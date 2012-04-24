#
# Cookbook Name:: mailserver_provisioning
# Recipe:: drbd
#
# Copyright 2012, RACKSPACE
#
# All rights reserved - Do Not Redistribute
#
#
include_recipe "mailserver_common"

node[:drbd][:packages].each do |p|
    yum_package p do
        version node[:drbd]['#{p}'][:version] if node[:drbd]['#{p}'][:version]
        allow_downgrade true
        action :install
    end
end

service 'drbd' do
    supports :restart =>true, :status =>true
    action :nothing
end

execute "adjust drbd" do
    command "drbdadm adjust all"
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
    notifies :run, "execute[change permissions on /etc/drbd_synced_file]", :immediately
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
