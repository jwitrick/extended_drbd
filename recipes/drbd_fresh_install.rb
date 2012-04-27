#
# Cookbook Name:: mailserver_provisioning
# Recipe:: drbd_fresh_install
# Copyright (C) 2012 Justin Witrick
#
# This program is free software; you can redistribute it and/or
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
stop_file_exists_command = " [ -f #{node[:drbd][:stop_file]} ] "
resource = node[:drbd][:resource]

my_ip = node[:my_expected_ip]
remote_ip = node[:server_partner_ip]

if node[:drbd][:remote_host].nil?
    node[:drbd][:remote_host] = node[:server_partner_hostname]
end
if remote_ip.nil?
    remote = search(:node, "name:#{node['drbd']['remote_host']}")[0]
    remote_ip = remote.ipaddress
end

if my_ip.nil?
    my_ip = node[:ipaddress]
end

ruby_block "check if other server is primary" do
    block do
        partner_primary = system("ssh #{remote_ip} drbdadm role data | grep -q 'Primary/'")
        if not partner_primary
            node[:drbd][:master] = true
            Chef::Log.info("This is a DRBD master")
        end
    end
    only_if {"#{node[:server_letter]}".eql? "#{node[:drbd][:primary][:designation]}" }
end

template "/etc/drbd.conf" do
    source "drbd.conf.erb"
    variables(
        :resource => resource,
        :my_ip => my_ip,
        :remote_ip => remote_ip
    )
    owner "root"
    group "root"
    action :create
end

execute "drbdadm create-md all" do
    command "echo 'Running create-md' ; yes yes |drbdadm create-md all"
    only_if {!system("#{stop_file_exists_command}") and system("drbd-overview | grep -q \"drbd not loaded\"")}
    action :run
    notifies :restart, resources(:service => 'drbd'), :immediately
    notifies :create, "file[/etc/drbd_initialized_file]", :immediately
end

ruby_block "wait_til_drbd_initialized on other server" do
    block do
        drbd_initialized = false
        until drbd_initialized == true do
            begin
            if system("ssh -q #{remote_ip} [ -f /etc/drbd_initialized_file ] ")
                drbd_initialized = true
                Chef::Log.info("DRBD Server is initialized on other server")
            else
                Chef::Log.info("Waiting on DRBD to be initialized on other server")
                sleep 5
            end
            rescue
                Chef::Log.info("Waiting on DRBD to be initialized on other server")
                sleep 5
            end
        end
    end
    not_if "#{stop_file_exists_command}"
end

bash "setup DRBD on master" do
 user "root"
 code <<-EOH
drbdadm -- --overwrite-data-of-peer primary #{resource}
echo 'Changing sync rate to 110M'
drbdsetup #{node[:drbd][:dev]} syncer -r 110M
mkfs.ext3 -m 1 -L #{resource} -T news #{node[:drbd][:dev]}
tune2fs -c0 -i0 #{node[:drbd][:dev]}
 EOH
 only_if {node[:drbd][:master]} and not_if "#{stop_file_exists_command}"
end

execute "change sync rate on secondary server only if this is an inplace upgrade" do
    command "drbdsetup #{node[:drbd][:dev]} syncer -r 110M"
    action :run
    not_if {node[:drbd][:master] or system("#{stop_file_exists_command}")}
end

ruby_block "wait for it to be in a consistent state" do
    block do
        until not system("grep -q ds:.*Inconsistent /proc/drbd") do
            current_rate = %x(sed -n 5p /proc/drbd | sed -e 's/^[ \\t]*//' | cut -d' ' -f3 |tr -d '\n')
            Chef::Log.info("Waiting on drbd to sync. Current Rate: #{current_rate}")
            sleep 60
        end
    end
    not_if "#{stop_file_exists_command}"
    notifies :run, "execute[adjust drbd]", :immediately
    notifies :create, "file[/etc/drbd_synced_stop_file]", :immediately
end

ruby_block "check configuration on both servers" do
    block do
        drbd_correct = true
        if node[:drbd][:master]
            if not system("drbdadm role #{resource} | grep -q \"Primary/Secondary\"")
                Chef::Log.info("The drbd master role was not correctly configured.")
                drbd_correct = false
            end
            if not system("ssh #{remote_ip} drbdadm role #{resource} | grep -q \"Secondary/Primary\"")
                Chef::Log.info("The drbd secondary role was not correctly configured.")
                drbd_correct = false
            end
        else
            if not system("drbdadm role #{resource} | grep -q \"Secondary/Primary\"")
                Chef::Log.info("The drbd master role was not correctly configured.")
                drbd_correct = false
            end
            if not system("ssh #{remote_ip} drbdadm role #{resource} | grep -q \"Primary/Secondary\"")
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
        if not system("ssh #{remote_ip} drbdadm dstate #{resource} | grep -q \"UpToDate/UpToDate\"")
            Chef::Log.info("The drbd secondary dstate was not correctly configured.")
            drbd_correct = false
        end
        if not system("ssh #{remote_ip} drbdadm cstate #{resource} | grep -q \"Connected\"")
            Chef::Log.info("The drbd secondary cstate was not correctly configured.")
            drbd_correct = false
        end

        if ! drbd_correct
            Chef::Application.fatal! "DRBD was not correctly configured. Please correct."
        end
    end
    not_if "#{stop_file_exists_command}"
    notifies :create, "file[#{node[:drbd][:stop_file]}]", :immediately
end

