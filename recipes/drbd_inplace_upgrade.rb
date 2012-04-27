#
# Cookbook Name:: mailserver_provisioning
# Recipe:: drbd_inplace_upgrade
#
# Copyright 2012, RACKSPACE
#
# All rights reserved - Do Not Redistribute
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
