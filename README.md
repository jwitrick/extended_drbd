extended\_drbd
=============

This cookbook is designed to setup and configure a pair of server with
drbd.
Please Note: this cookbook does not mount the drbd drive.

This cookbook assumes that you want it to control your firewall using iptables,
as such it will attempt to open/close the correct ports. If you want to disable
this functionality you can modify the attribute `node['iptables']['enabled']` 
and set it to `false`.

This cookbook can be used in the following situations:

1) Fresh server pair installation (please see below for how to use).

2) Adding a server to another server running drbd.

3) Change drbd.conf file and have drbd update with out restarting.

Usage
=====
# How to use when creating a fresh server pair:

Prerequisites:

- Chef client must be installed on both servers.

- The disk location `node['drbd']['disk']['location']` must exist.

Note: In order for this work properly both servers need to be running chef
at the same time,

You will need to have the following attribute values specified:

`node['drbd']['primary']['fqdn']` and `node['drbd']['partner']['hostname']`

Note: If you do not specify both attributes then the chef run will error out.

Once one server has been specified as drbd master you can add the recipe
"drbd::drbd\_fresh\_install" to the run\_list of both servers.

# How to use when adding a new server to another server running drbd:

This is the same as above except the new server is not specified as the drbd
master, and you dont have to be running chef-client on the other server.

# How to use when changing the drbd.conf file:

On which ever server you are updated (or both) add the recipe
"drbd::drbd\_inplace\_upgrade" to the server's run\_list. And the next
time Chef-client runs it will preform the changes in a safe way.

The way I have used this have been to call this drbd cookbook from within
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
 * `default['drbd']['disk']['location'] = "/dev/local/data"`
 * `default['drbd']['mount'] = "/data"`
 * `default_unless['drbd']['fs_type'] = "ext3"`
 * `default['drbd']['dev'] = "/dev/drbd0"`
 * `default['drbd']['master'] = false`
 * `default['drbd']['port'] = 7789`
 * `default['drbd']['configured'] = false`
 * `default['drbd']['syncrate'] = "36M"`
 * `default['drbd']['resource'] = "data"`
 * `default['drbd']['stop_file'] = "/etc/drbd_stop_file"`
 * `default['drbd']['synced']['stop_file'] = "/etc/drbd_synced_stop_file"`
 * `default['drbd']['initialized']['stop_file'] = "/etc/drbd_initialized_stop_file"`

 * `default['drbd']['primary']['fqdn'] = nil` - Fqdn of the primary drbd server
 * `default['drbd']['server']['hostname'] = nil` - Fqdn of the server
   Note: This will use the `node['fqdn']` if not specified.
 * `default['drbd']['server']['ipaddress'] = nil` - Ipaddress of the server
   Note: This will use `node['ipaddress']` if nil.
 * `default['drbd']['partner']['hostname'] = nil` - Fqdn of the partner server
 * `default['drbd']['partner']['ipaddress'] = nil` - Ipaddress of the parter server
   Note: If not specified chef will try to search the chef-server using 
   `node['drbd']['partner']['hostname']` to find the node object.

 * `default['drbd']['command_timeout'] = 36000` - A timeout value used when
   trying to create a filesystem of a huge data store.
 * `default['drbd']['protocol'] = 'C'` - The protocal used by the drbd app.
 * `default['drbd']['disk']['on_io_error_action'] = 'detach'`
 * `default['drbd']['disk']['disk-flushes'] = false`
 * `default['drbd']['disk']['md-flushes'] = false`
 * `default['drbd']['disk']['no-disk-barrier'] = false`
 * `default['drbd']['net']['enabled'] = false`
 * `default['drbd']['net']['sndbuf-size'] = '1M'`
 * `default['drbd']['net']['max-buffers'] = 8000`
 * `default['drbd']['net']['max-epoch-size'] = 8000`

 * `default['iptables']['enabled'] = true`

# Testing
This recipe includes a number of chefspec unit tests for this cookbook.

To execute the tests run `rake`

This also makes use of vagrant, and creates VM's to make use of the cookbook.
Because this cookbook REQUIRES both serves to be running chef at the same time,
there are a few manual steps involved with using Vagrant.

1) Create both VM's (one at a time).

2) Once both VM's are up and running, edit the Vagrant File:
<BLOCKQUOTE><PRE>
Existing file:
def get_recipes()
  recipes = %w{
    chef-solo-search
    minitest-handler
    extended_drbd_helper
    yum::epel
    yum::elrepo
  }
#    extended_drbd::drbd_fresh_install
#  }
</PRE></BLOCKQUOTE>
Please change the file to look like:
<BLOCKQUOTE><PRE>
Ater changes:
def get_recipes()
  recipes = %w{
    chef-solo-search
    minitest-handler
    extended_drbd_helper
    yum::epel
    yum::elrepo
    extended_drbd::drbd_fresh_install
  }
</PRE></BLOCKQUOTE>

3) Now run `vagrant provision <server_name>` for both servers at the same time.

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

