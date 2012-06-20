#
# Cookbook Name:: mailserver_provisioning
# Recipe:: drbd
#
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

stop_file_exists_command = " [ -f #{node[:drbd][:stop_file]} ] "
inplace = File.exists?("#{node['drbd']['config_file']}")
node[:drbd][:packages].each do |p|
    yum_package p do
        version node[:drbd]['#{p}'][:version] if defined? node[:drbd]['#{p}'][:version]
        allow_downgrade true
        action :install
    end
end

template node['drbd']['config_file'] do
    source "drbd.conf.erb"
    variables(
        :resource => node[:drbd][:resource],
        :primary_ip => node[:drbd][:primary][:ip],
        :primary_short_hostname => node[:drbd][:primary][:short_hostname],
        :secondary_ip => node[:drbd][:secondary][:ip],
        :secondary_short_hostname => node[:drbd][:secondary][:short_hostname]
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
    only_if {inplace}
end

extended_drbd_immutable_file "/etc/drbd_initialized_file" do
    file_name "/etc/drbd_initialized_file"
    content "This file is for drbd and chef to signify drbd is initialized"
    action :nothing
end

extended_drbd_immutable_file "/etc/drbd_synced_stop_file" do
    file_name "/etc/drbd_synced_stop_file"
    content "This file is for drbd and chef to signify drbd is synchronized"
    action :nothing
end

extended_drbd_immutable_file "#{node[:drbd][:stop_file]}" do
    file_name "#{node[:drbd][:stop_file]}"
    content "This file is for drbd and chef to signify drbd is fully configured"
    action :nothing
end

file "/etc/drbd_initialized_file" do
    action :nothing
    notifies :run, "execute[change permissions on /etc/drbd_initialized_file]", :immediately
end
execute "change permissions on /etc/drbd_initialized_file" do
    command "chattr +i /etc/drbd_initialized_file"
    action :nothing
end
file "/etc/drbd_synced_stop_file" do
    mode 0777
    action :nothing
    notifies :run, "execute[change permissions on /etc/drbd_synced_stop_file]", :immediately
end
execute "change permissions on /etc/drbd_synced_stop_file" do
    command "chattr +i /etc/drbd_synced_stop_file"
    action :nothing
end
file "#{node[:drbd][:stop_file]}" do
    mode 0777
    action :nothing
    notifies :run, "execute[change permissions on #{node[:drbd][:stop_file]}]", :immediately
end

execute "change permissions on #{node[:drbd][:stop_file]}" do
    command "chattr +i #{node[:drbd][:stop_file]}"
    action :nothing
end
