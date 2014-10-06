#
# Cookbook Name:: extended_drbd
# Recipe:: iptables
#
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

if node['iptables']['enabled']
  include_recipe "iptables"

  iptables_rule 'drbd_port' do
    source "iptables/drbd.erb"
  end

  if not ::File.exists?("/etc/iptables.d/drbd_port")
    #This is a hack to make it open the port before drbd service runs
    ruby_block "rebuild iptables now" do
      block do
      end
      notifies :run, "execute[rebuild-iptables]", :immediately
    end
  end
end

# vim: ai et ts=2 sts=2 sw=2 ft=ruby
