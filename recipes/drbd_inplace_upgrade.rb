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

include_recipe "#{@cookbook_name}"

execute "create stop files" do
    command "echo 'Creating stop files'"
    not_if {::File.exists?(node['drbd']['stop_file'])}
    notifies :create, "extended_drbd_immutable_file[#{node[:drbd][:initialized][:stop_file]}]", :immediately
    notifies :create, "extended_drbd_immutable_file[#{node[:drbd][:stop_file]}]", :immediately
end
