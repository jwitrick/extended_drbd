
if node['kernel']['release'] and node['kernel']['release'].include?("xen")
  default['drbd']['packages'] = ["kmod-drbd83", "drbd83", "kmod-drbd83-xen"]
else
  default['drbd']['packages'] = ["kmod-drbd83", "drbd83"]
end

node['drbd']['packages'].each do |pkg|
  default['drbd'][pkg]['version'] = nil
end

default['drbd']['remote_host'] = nil
default['drbd']['disk']['start'] = "/dev/"
default_unless['drbd']['fs_type'] = "ext3"
default['drbd']['dev'] = "/dev/drbd0"
default['drbd']['master'] = false
default['drbd']['port'] = 7789
default['drbd']['syncrate'] = "36M"
default['drbd']['resource'] = "data"
default['drbd']['disk']['location'] = "/dev/local/#{node['drbd']['resource']}"
default['drbd']['wait_til_synced'] = true

default['drbd']['config_file'] = "/etc/drbd.conf"

default['drbd']['stop_file'] = "/etc/drbd_stop_file"
default['drbd']['synced']['stop_file'] = "/etc/drbd_synced_stop_file"
default['drbd']['initialized']['stop_file'] = "/etc/drbd_initialized_stop_file"

default['drbd']['primary']['fqdn'] = nil
default['drbd']['server']['hostname'] = nil
default['drbd']['server']['ipaddress'] = nil
default['drbd']['partner']['hostname'] = nil
default['drbd']['partner']['ipaddress'] = nil

default['drbd']['command_timeout'] = 36000

default['drbd']['protocol'] = 'C'
default['drbd']['disk']['on_io_error_action'] = 'detach'
default['drbd']['disk']['disk-flushes'] = false
default['drbd']['disk']['md-flushes'] = false
default['drbd']['disk']['no-disk-barrier'] = false

default['drbd']['net']['enabled'] = false
default['drbd']['net']['sndbuf-size'] = '1M'
default['drbd']['net']['max-buffers'] = 8000
default['drbd']['net']['max-epoch-size'] = 8000

default['iptables']['enabled'] = true
