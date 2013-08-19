#
# Cookbook Name:: extended_drbd_helper
# Recipe:: default
#
# Copyright 2013, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
#

if not node['drbd'].nil? and not node['drbd']['disk'].nil? and
  not node['drbd']['disk']['location'].nil?
  disk_loc = node['drbd']['disk']['location']
  disk_loc_array = disk_loc.split('/')
  lv_name = node['drbd']['resource']
  storevg = disk_loc_array[2]
#  lv_size_cmd = "-L 500M"
  lv_size_cmd = "-L 2G"
  execute "create lv #{lv_name} in volume group #{storevg}" do
    command "lvcreate --name #{lv_name} #{lv_size_cmd} #{storevg}"
    not_if { ::File.exists?(disk_loc) }
    action :run
  end
end
