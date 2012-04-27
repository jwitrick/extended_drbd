#
# Cookbook Name:: mailserver_provisioning
# Recipe:: drbd_inplace_upgrade
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
include_recipe 'drbd'
stop_file_exists_command = " [ -f #{node[:drbd][:stop_file]} ] "
resource = "data"

my_ip = node[:my_expected_ip]
remote_ip = node[:server_partner_ip]
if node[:drbd][:remote_host] == ''
    node[:drbd][:remote_host] = node[:server_partner_hostname]
end
if remote_ip == ''
    remote = search(:node, "name:#{node['drbd']['remote_host']}")[0]
    remote_ip = remote.ipaddress
end

if my_ip == ''
    my_ip = node[:ipaddress]
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
    notifies :run, "execute[adjust drbd]", :immediately
end

execute "create stop files" do
    command "echo 'Creating stop files'"
    not_if "#{stop_file_exists_command}"
    notifies :create, "file[/etc/drbd_initialized_file]", :immediately
    notifies :create, "file[#{node[:drbd][:stop_file]}]", :immediately
end
