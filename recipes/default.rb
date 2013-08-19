#
# Cookbook Name:: extended_drbd
# Recipe:: default
#
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

include_recipe "#{@cookbook_name}::iptables"

inplace = File.exists?(node['drbd']['config_file'])

if node['drbd']['fs_type'] == 'xfs'
  %w{ xfsprogs }.each do |pkg|
    package pkg do
      action :install
    end
  end
end

node['drbd']['packages'].each do |p|
  yum_package p do
    version node['drbd'][p]['version']
    allow_downgrade true
    action :install
  end
end

node.normal['drbd']['server']['ipaddress'] ||= node['ipaddress']

if node['drbd']['server']['hostname'].nil?
  node.normal['drbd']['server']['hostname'] = node['fqdn']
end

if not node['drbd']['partner']['hostname'] or
  not node['drbd']['partner']['ipaddress']
  if not node['drbd']['partner']['hostname']
    Log "Specified partner hostname is nil, cannot search." do
      level :warn
    end
  else
    Chef::Log.info("Searching for partner fqdn: "+
      "#{node['drbd']['partner']['hostname']}")
    host = search(:node, %Q{fqdn:"#{node['drbd']['partner']['hostname']}"})
    host = host.first
    node.normal['drbd']['partner']['ipaddress'] = host['ipaddress']
  end
end

Log "Creating template with disk resource #{node['drbd']['disk']['location']}"
template node['drbd']['config_file'] do
  source "drbd.conf.erb"
  variables(
    :resource => node['drbd']['resource']
  )
  owner "root"
  group "root"
  action :create
  notifies :run, "execute[adjust drbd]", :immediately
end

service 'drbd' do
  supports :restart =>true, :status =>true
  action :nothing
end

execute "adjust drbd" do
  command "drbdadm adjust all"
  action :nothing
  only_if { inplace }
end

extended_drbd_immutable_file node['drbd']['initialized']['stop_file'] do
  file_name node['drbd']['initialized']['stop_file']
  content "This file is for drbd and chef to signify drbd is initialized"
  action :nothing
end

extended_drbd_immutable_file node['drbd']['synced']['stop_file'] do
  file_name node['drbd']['synced']['stop_file']
  content "This file is for drbd and chef to signify drbd is synchronized"
  action :nothing
end

extended_drbd_immutable_file node['drbd']['stop_file'] do
  file_name node['drbd']['stop_file']
  content "This file is for drbd and chef to signify drbd is fully configured"
  action :nothing
end

# vim: ai et ts=2 sts=2 sw=2 ft=ruby
