#
# Cookbook Name:: extended_drbd
# Recipe:: drbd_fresh_install
# Copyright (C) 2012 Justin Witrick
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe "#{@cookbook_name}"

resource                    = node['drbd']['resource']
drbd_chk_cmd = "drbdadm role #{node['drbd']['resource']}"
drbd_primary_check          = "cat /proc/drbd |grep -q 'Primary/'"
drbd_secondary_check        = "cat /proc/drbd |grep -q 'Secondary/'"
drbd_stopf = node['drbd']['stop_file']
drbd_initf = node['drbd']['initialized']['stop_file']
drbd_syncf = node['drbd']['synced']['stop_file']

remote_ip = node['drbd']['partner']['ipaddress']

execute "drbdadm create-md all" do
  command "echo 'Running create-md' ; yes yes |drbdadm create-md all"
  not_if { ::File.exists?(drbd_initf) }
  action :run
  notifies :restart, "service[drbd]", :immediately
  notifies :create, "extended_drbd_immutable_file[#{drbd_initf}]", :immediately
end

execute "modprobe drbd"

ruby_block "check if other server is primary" do
  block do
    drbd_check = Mixlib::ShellOut.new("drbdadm role all").run_command.stdout
    if not drbd_check.include?("Secondary/Primary")
      node.normal['drbd']['master'] = true
      Chef::Log.info("This is a DRBD master")
      unless Chef::Config[:solo]
        node.save
      end
    else
      node.normal['drbd']['master'] = false
    end
  end
  only_if do
    chk = node['drbd']['primary']['fqdn'].eql? node['fqdn']
    chk and not node['drbd']['master']
  end
  action :create
end

bash "setup drbd on master" do
  user "root"
  code <<-EOH
drbdadm -- --overwrite-data-of-peer primary #{resource}
echo 'Changing sync rate to 110M'
drbdsetup #{node['drbd']['dev']} syncer -r 110M
  EOH
  only_if do
    master = node['drbd']['master']
    drbd_chk_out = Mixlib::ShellOut.new(drbd_chk_cmd).run_command.stdout
    primary = drbd_chk_out.include?("Primary/")
    if master or primary and not ::File.exists?(drbd_initf)
      true
    end
  end
end

execute "setup xfs filesystem" do
  subscribes :run, "bash[setup drbd on master]", :immediately
  cmd = "mkfs.#{node['drbd']['fs_type']} -L #{resource}" +
    " -f #{node['drbd']['dev']}"
  command cmd
  timeout node['drbd']['command_timeout']
  action :nothing
  only_if { node['drbd']['fs_type'].eql? "xfs" }
end

execute "setup ext file system" do
  subscribes :run, "bash[setup drbd on master]", :immediately
  cmd = "mkfs.#{node['drbd']['fs_type']} -m 1 -L #{resource}" +
    " -T news #{node['drbd']['dev']}"
  command cmd
  timeout node['drbd']['command_timeout']
  notifies :run, "execute[configure fs]", :immediately
  not_if { node['drbd']['fs_type'].eql? "xfs" }
  action :nothing
end

execute "configure fs" do
  command "tune2fs -c0 -i0 #{node['drbd']['dev']}"
  timeout node['drbd']['command_timeout']
  action :nothing
end

execute "change sync rate on secondary server if this is an inplace upgrade" do
  command "drbdsetup #{node['drbd']['dev']} syncer -r 110M"
  action :run
  only_if { system(drbd_secondary_check) and not ::File.exists?(drbd_initf) }
end

if node['drbd']['wait_til_synced']
  wait_until "wait until drbd is in a constant state" do
    command "grep -q 'ds:UpToDate/UpToDate' /proc/drbd"
    message "Wait until drbd is not in an inconsistent state"
    wait_interval 60
    not_if { ::File.exists?(drbd_syncf) }
    notifies :run, "execute[adjust drbd]", :immediately
    notifies :create, "extended_drbd_immutable_file[#{drbd_syncf}]",
      :immediately
  end
end

ruby_block "check configuration on both servers" do
  block do
    drbd_correct = true
    if not node['drbd']['wait_til_synced']
      Chef::Log.info("Telling Chef to sleep for '10' seconds")
      sleep(10)
    end
    drbd_role_cmd = Mixlib::ShellOut.new("drbdadm role #{resource}")
    drbd_role_out = drbd_role_cmd.run_command.stdout.delete("\n")
    drbd_dstate_cmd = Mixlib::ShellOut.new("drbdadm dstate #{resource}")
    drbd_dstate_out = drbd_dstate_cmd.run_command.stdout.delete("\n")
    drbd_cstate_cmd = Mixlib::ShellOut.new("drbdadm cstate #{resource}")
    drbd_cstate_out = drbd_cstate_cmd.run_command.stdout.delete("\n")

    if not drbd_role_out.include?("Primary/Secondary") and
      not drbd_role_out.include?("Secondary/Primary")
      Chef::Log.info("The drbd role was not correctly configured.")
      Chef::Log.info("drbdadm output: #{drbd_role_out}")
      drbd_correct = false
    end

    if drbd_correct and node['drbd']['wait_til_synced']
      if not drbd_cstate_out.include?("Connected")
        Chef::Log.info("The drbd cstate not correctly configured.")
        Chef::Log.info("drbdadm output: #{drbd_cstate_out}")
        drbd_correct = false
      elsif not drbd_dstate_out.include?("UpToDate/UpToDate")
        Chef::Log.info("The drbd dstate not correctly configured.")
        Chef::Log.info("drbdadm output: #{drbd_dstate_out}")
        drbd_correct = false
      end
    end

    if not drbd_correct
      Chef::Application.fatal! "DRBD was not correctly configured."
    end
  end
  not_if { ::File.exists?(drbd_stopf) }
  notifies :create, "extended_drbd_immutable_file[#{drbd_stopf}]", :immediately
end

# vim: ai et ts=2 sts=2 sw=2 ft=ruby
