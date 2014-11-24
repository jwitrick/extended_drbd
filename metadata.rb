name             "extended_drbd"
maintainer       "Justin Witrick"
maintainer_email "github@thewitricks.com"
license          "Apache 2.0"
description      "DRBD recipe"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "1.0.5"

%w{ redhat centos scientific }.each do |os|
  supports os, ">= 5.8"
end

depends "iptables"
depends "wait"
