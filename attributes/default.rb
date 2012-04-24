
default[:drbd][:remote_host] = nil
default[:drbd][:disk] = "/dev/local/data"
default[:drbd][:mount] = "/data"
default[:drbd][:fs_type] = "ext3"
default[:drbd][:dev] = "/dev/drbd0"
default[:drbd][:master] = false
default[:drbd][:port] = 7789
default[:drbd][:configured] = false
default[:drbd][:stop_file] = "/etc/drbd_stop_file"
default[:drbd][:syncrate] = "36M"
