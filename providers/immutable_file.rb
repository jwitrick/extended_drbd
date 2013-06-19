#
# Cookbook Name:: extended_drbd
# Resource:: immutable_file
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

action :create do

  file new_resource.file_name do
    mode new_resource.mode
    owner new_resource.owner if new_resource.owner
    group new_resource.group if new_resource.group
    content new_resource.content if new_resource.content
    action :create_if_missing
    new_resource.updated_by_last_action(true)
  end

  execute "change permissions on #{new_resource.file_name}" do
    command "chattr +i #{new_resource.file_name}"
    action :run
  end
end
# vim: ai et ts=2 sts=2 sw=2 ft=ruby
