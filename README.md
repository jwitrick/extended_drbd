extended_drbd
=============

This cookbook is designed to setup and configure a pair of server with
drbd.
Please Note: this cookbook does not mount the drbd drive.

This cookbook can be used in the following situations:

1) Fresh server pair installation (please see below for how to use).

2) Adding a server to another server running drbd.

3) Change drbd.conf file and have drbd update with out restarting.

Usage
=====
# How to use when creating a fresh server pair:

Prerequisites:

- Chef client must be installed on both servers.

- The disk location (`node['drbd']['disk']`) must exist.

Note: In order for this work properly both servers need to be running chef
at the same time,

You will need to have the following attribute values specified:

`node['drbd']['primary']['fqdn']` and `node['drbd']['remote_host']`

Once one server has been specified as drbd master you can add the recipe
"drbd::drbd_fresh_install" to the run_list of both servers.

# How to use when adding a new server to another server running drbd:

This is the same as above except the new server is not specified as the drbd
master, and you dont have to be running chef-client on the other server.

# How to use when changing the drbd.conf file:

On which ever server you are updated (or both) add the recipe
"drbd::drbd_inplace_upgrade" to the server's run_list. And the next
time Chef-client runs it will preform the changes in a safe way.

The ways I have used this have been to call this drbd cookbook from within
another cookbook, and have the second cookbook do the logic of decided whether
or not this is a fresh install or inplace upgrade.

Here is how I use it:

    if ::File.exists?("/etc/drbd.conf")
      include_recipe "extended_drbd::drbd_inplace_upgrade"
    else
      include_recipe "extended_drbd::drbd_fresh_install"
    end

Attributes:
===========
 * `default['drbd']['packages'] = ["kmod-drbd83", "drbd83"]`
 * `default['drbd']['disk'] = "/dev/local/data"`
 * `default['drbd']['mount'] = "/data"`
 * `default['drbd']['fs_type'] = "ext3"`
 * `default['drbd']['dev'] = "/dev/drbd0"`
 * `default['drbd']['master'] = false`
 * `default['drbd']['port'] = 7789`
 * `default['drbd']['configured'] = false`
 * `default['drbd']['syncrate'] = "36M"`
 * `default['drbd']['resource'] = "data"`
 * `default['drbd']['stop_file'] = "/etc/drbd_stop_file"`
 * `default['drbd']['synced']['stop_file'] = "/etc/drbd_synced_stop_file"`
 * `default['drbd']['initialized']['stop_file'] = "/etc/drbd_initialized_stop_file"`
 * `default['drbd']['primary']['fqdn'] = nil`
 * `default['drbd']['remote_host'] = nil`

# License and Author

- Author:: Justin Witrick (<github@thewitricks.com>)

- Copyright:: Justin Witrick.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

