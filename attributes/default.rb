default[:drbd][:packages] = ["kmod-drbd83", "drbd83"]

default[:drbd][:remote_host] = nil
default[:drbd][:disk][:start] = "/dev/" #{node['lvm']['vg_name']}/data"
default[:drbd][:mount] = "/data"
default[:drbd][:fs_type] = "ext3"
default[:drbd][:dev] = "/dev/drbd0"
default[:drbd][:master] = false
default[:drbd][:port] = 7789
default[:drbd][:syncrate] = "36M"
default[:drbd][:resource] = "data"

default[:drbd][:config_file] = "/etc/drbd.conf"

default[:drbd][:stop_file] = "/etc/drbd_stop_file"
default[:drbd][:synced][:stop_file] = "/etc/drbd_synced_stop_file"
default[:drbd][:initialized][:stop_file] = "/etc/drbd_initialized_stop_file"

default[:drbd][:primary][:fqdn] = nil
