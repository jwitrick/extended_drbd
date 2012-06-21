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

unless defined? node[:my_expected_ip] do
    host = search(:node, "fqdn:#{node[:fqdn]}").first
    node.set[:my_expected_ip] = host["ipaddress"]
end

unless defined? node[:server_short_hostname] do
    host = search(:node, "fqdn:#{node[:fqdn]}").first
    node.set[:server_short_hostname] = host["hostname"]
end

unless defined? node[:server_partner_ip] do
    host = search(:node, "fqdn:#{node[:drbd][:remote_host]}").first
    node.set[:server_partner_ip] = host["ipaddress"]
end

unless defined? node[:server_partner_short_hostname] do
    host = search(:node, "fqdn:#{node[:drbd][:remote_host]}").first
    node.set[:server_partner_short_hostname] = host["hostname"]
end

template node['drbd']['config_file'] do
    source "drbd.conf.erb"
    variables(
        :resource => node[:drbd][:resource],
        :my_ip => node[:my_expected_ip],
        :my_short_hostname => node[:server_short_hostname],
        :partner_ip => node[:server_partner_ip],
        :partner_short_hostname => node[:server_partner_short_hostname]
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

extended_drbd_immutable_file "#{node[:drbd][:initialized][:stop_file]}" do
    file_name "#{node[:drbd][:initialized][:stop_file]}"
    content "This file is for drbd and chef to signify drbd is initialized"
    action :nothing
end

extended_drbd_immutable_file "#{node[:drbd][:synced][:stop_file]}" do
    file_name "#{node[:drbd][:synced][:stop_file]}"
    content "This file is for drbd and chef to signify drbd is synchronized"
    action :nothing
end

extended_drbd_immutable_file "#{node[:drbd][:stop_file]}" do
    file_name "#{node[:drbd][:stop_file]}"
    content "This file is for drbd and chef to signify drbd is fully configured"
    action :nothing
end

