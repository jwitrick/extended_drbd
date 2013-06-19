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
actions :create

attribute :group, :regex => [/^([a-z]|[A-Z]|[0-9]|_|-)+$/]
attribute :owner, :regex => [/^([a-z]|[A-Z]|[0-9]|_|-)+$/]
attribute :mode, :regex => /^0?\d{3,4}$/
attribute :file_name, :kind_of => String
attribute :content, :kind_of => String

def initialize(*args)
  super
  @action = :create
  @owner = "root"
  @group = "root"
  @mode = 0755
end

# vim: ai et ts=2 sts=2 sw=2 ft=ruby
