# -*- mode: ruby -*-

def boxify()
  box = "centos-6.3"
  box_url = "http://ff9ab1b0dd708050f0c2-3d464532f2dc105f18d6ce29cfbb9612.r90.cf2.rackcdn.com/centos-6.3_chef-11.4.4.box"
  [box, box_url]
end

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
  recipes
end

Vagrant::Config.run do |config|

  config.vm.define :store1a do |subconfig|
    subconfig.vm.box, subconfig.vm.box_url = boxify
    subconfig.vm.host_name = "store1a.mail.testing.example.com"
    subconfig.vm.network :hostonly, "172.31.0.110"
    subconfig.vm.provision :chef_solo do |chef|
      chef.data_bags_path = 'data_bags'
      chef.json = {
        :drbd => {
          :server => {
            :ipaddress => "172.31.0.110"
          },
          :primary => {
            :fqdn => "store1a.mail.testing.example.com"
          },
          :partner => {
            :hostname => "store1b.mail.testing.example.com"
          }
        }
      }
      get_recipes.each do |rec|
        chef.add_recipe rec
      end
    end
  end

  config.vm.define :store1b do |subconfig|
    subconfig.vm.box, subconfig.vm.box_url = boxify
    subconfig.vm.host_name = "store1b.mail.testing.example.com"
    subconfig.vm.network :hostonly, "172.31.0.120"
    subconfig.vm.provision :chef_solo do |chef|
      chef.data_bags_path = 'data_bags'
      chef.json = {
        :drbd => {
          :server => {
            :ipaddress => "172.31.0.120"
          },
          :primary => {
            :fqdn => "store1a.mail.testing.example.com"
          },
          :partner => {
            :hostname => "store1a.mail.testing.example.com"
          }
        }
      }
      get_recipes.each do |rec|
        chef.add_recipe rec
      end
    end
  end
end

# vim: ai et ts=2 sts=2 sw=2 ft=ruby
