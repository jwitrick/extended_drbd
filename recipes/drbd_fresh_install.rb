#
# Cookbook Name:: extended_drbd
# Recipe:: drbd_fresh_install
# Copyright (C) 2012 Justin Witrick
#
# This program is free software; you can reistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301,
# USA.
#

include_recipe 'extended_drbd'
drbd_primary_check          = "cat /proc/drbd |grep -q 'Primary/'"
drbd_secondary_check        = "cat /proc/drbd |grep -q 'Secondary/'"
resource                    = node[:drbd][:resource]
my_ip                       = node[:my_expected_ip].nil? ? node[:ipaddress] : node[:my_expected_ip]
node['drbd']['ssh_command'] = "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"

remote_ip = node[:server_partner_ip]

ruby_block "check if other server is primary" do
  block do
    node[:drbd][:master] = true
    Chef::Log.info("This is a DRBD master")
    unless Chef::Config[:solo]
      node.save
    end
  end
  only_if { node[:drbd][:primary][:fqdn]}eql? node[:fqdn] }
end

execute "drbdadm create-md all" do
  command "echo 'Running create-md' ; yes yes |drbdadm create-md all"
  not_if {::File.exists?(node['drbd']['stop_file'])}
  action :run
  notifies :restart, resources(:service => 'drbd'), :immediately
  notifies :create, "extended_drbd_immutable_file[#{node[:drbd][:initialized][:stop_file]}]", :immediately
end

wait_til "drbd_initialized on other server" do
    command "#{node['drbd']['ssh_command']} -q #{remote_ip} [ -f #{node[:drbd][:initialized][:stop_file]} ] "
    message "Wait for drbd to be initialized on #{remote_ip}"
    wait_interval 5
    not_if {::File.exists?(node['drbd']['stop_file'])}
end

bash "setup drbd on master" do
  user "root"
  code <<-EOH
drbdadm -- --overwrite-data-of-peer primary #{resource}
echo 'Changing sync rate to 110M'
drbdsetup #{node[:drbd][:dev]} syncer -r 110M
  EOH
  only_if { system(drbd_primary_check) and not ::File.exists?(node['drbd']['stop_file']) }
end

if node['drbd']['fs_type'] == "xfs"
  execute "setup xfs filesystem" do
    command "mkfs.#{node['drbd']['fs_type']} -L #{resource} -f #{node[:drbd][:dev]}"
    timeout node['drbd']['command_timeout']
    only_if { system(drbd_primary_check) and not ::File.exists?(node['drbd']['stop_file']) }
  end
else
  execute "setup ext file system" do
    command "mkfs.#{node['drbd']['fs_type']} -m 1 -L #{resource} -T news #{node[:drbd][:dev]}"
    timeout node['drbd']['command_timeout']
    only_if { system(drbd_primary_check) and not ::File.exists?(node['drbd']['stop_file']) }
  end

  execute "configure fs" do
    command "tune2fs -c0 -i0 #{node[:drbd][:dev]}"
    timeout node['drbd']['command_timeout']
    only_if { system(drbd_primary_check) and not ::File.exists?(node['drbd']['stop_file']) }
  end
end

execute "change sync rate on secondary server only if this is an inplace upgrade" do
  command "drbdsetup #{node[:drbd][:dev]} syncer -r 110M"
  action :run
  only_if { system(drbd_secondary_check) and not ::File.exists?(node['drbd']['stop_file']) }
end

wait_til_not "wait until drbd is in a constant state" do
  command "grep -q ds:.*Inconsistent /proc/drbd"
  message "Wait until drbd is not in an inconsistent state"
  wait_interval 60
  not_if { ::File.exists?(node['drbd']['stop_file']) }
  notifies :run, "execute[adjust drbd]", :immediately
  notifies :create, "extended_drbd_immutable_file[#{node[:drbd][:synced][:stop_file]}]", :immediately
end

ruby_block "check configuration on both servers" do
  block do
    drbd_correct = true
    if node[:drbd][:master]
      if not system("drbdadm role #{resource} | grep -q \"Primary/Secondary\"")
        Chef::Log.info("The drbd master role was not correctly configured.")
        drbd_correct = false
      end
      if not system("#{node['drbd']['ssh_command']} #{remote_ip} drbdadm role #{resource} | grep -q \"Secondary/Primary\"")
        Chef::Log.info("The drbd secondary role was not correctly configured.")
        drbd_correct = false
      end
      else
        if not system("drbdadm role #{resource} | grep -q \"Secondary/Primary\"")
          Chef::Log.info("The drbd master role was not correctly configured.")
          drbd_correct = false
         end
          if not system("#{node['drbd']['ssh_command']} #{remote_ip} drbdadm role #{resource} | grep -q \"Primary/Secondary\"")
            Chef::Log.info("The drbd secondary role was not correctly configured.")
            drbd_correct = false
          end
      end

      if not system("drbdadm dstate #{resource} | grep -q \"UpToDate/UpToDate\"")
        Chef::Log.info("The drbd master dstate was not correctly configured.")
        drbd_correct = false
      end
      if not system("drbdadm cstate #{resource} | grep -q \"Connected\"")
        Chef::Log.info("The drbd master cstate was not correctly configured.")
        drbd_correct = false
      end
      if not system("#{node['drbd']['ssh_command']} #{remote_ip} drbdadm dstate #{resource} | grep -q \"UpToDate/UpToDate\"")
        Chef::Log.info("The drbd secondary dstate was not correctly configured.")
        drbd_correct = false
      end
      if not system("#{node['drbd']['ssh_command']} #{remote_ip} drbdadm cstate #{resource} | grep -q \"Connected\"")
        Chef::Log.info("The drbd secondary cstate was not correctly configured.")
        drbd_correct = false
      end

      if ! drbd_correct
        Chef::Application.fatal! "DRBD was not correctly configured. Please correct."
      end
  end
  not_if { ::File.exists?(node['drbd']['stop_file']) }
  notifies :create, "extended_drbd_immutable_file[#{node[:drbd][:stop_file]}]", :immediately
end

