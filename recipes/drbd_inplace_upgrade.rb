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
    command "Creating stop files"
    not_if "#{stop_file_exists_command}"
    notifies :create, "file[/etc/drbd_initialized_file]", :immediately
    notifies :create, "file[#{node[:drbd][:stop_file]}]", :immediately
end
