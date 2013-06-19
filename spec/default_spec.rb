require 'chefspec'

describe 'extended_drbd::default' do
  let(:recipe) { 'extended_drbd::default' }
  let(:server_name) { "test1" }
  let(:server_ip) { "192.168.1.1" }
  let(:partner_name) { "test2" }
  let(:partner_ip) { "192.168.1.2" }
  let(:chef_run) {
    runner = ChefSpec::ChefRunner.new(platform: 'redhat', version: '6.3') do 
      |node|
      node.automatic_attrs['fqdn'] = server_name
      node.automatic_attrs['ipaddress'] = server_ip

      #For some reason if other cookbooks that change this value
      #are within the same cookbook root level then there atts values
      #override the default one
      node.override['drbd']['resource'] = "data"
      node.normal['drbd']['server']['hostname'] = server_name
      node.normal['drbd']['server']['ipaddress'] = server_ip
      node.normal['drbd']['partner']['ipaddress'] = partner_ip
      node.normal['drbd']['partner']['hostname'] = partner_name
    end
    runner
  }

  shared_examples_for 'extended_drbd' do

    it 'should include recipe extended_drbd::iptables' do
      chef_run.converge recipe
      expect(chef_run).to include_recipe 'extended_drbd::iptables'
    end

    it 'should set the server ip when attribule is nil' do
      chef_run.node.normal['drbd']['server']['ipaddress'] = nil
      chef_run.converge recipe
      actual_ip = chef_run.node['drbd']['server']['ipaddress']
      expect(actual_ip).to eql(server_ip)
    end

    it 'should set the server hostname to fqdn when nil' do
      chef_run.node.normal['drbd']['server']['hostname'] = nil
      chef_run.converge recipe
      actual_name = chef_run.node['drbd']['server']['hostname']
      expect(actual_name).to eql(server_name)
    end

    it 'should log a msg about saying chhef solo when partner name is nil' do
      chef_run.node.normal['drbd']['partner']['hostname'] = nil
      chef_run.converge recipe
      expect(chef_run).to log 'You are running as solo, search does not work'
    end

    it 'should log a msg about saying chhef solo when partner ip is nil' do
      chef_run.node.normal['drbd']['partner']['ipaddress'] = nil
      chef_run.converge recipe
      expect(chef_run).to log 'You are running as solo, search does not work'
    end

    it 'should log msg about disk resource' do
      chef_run.converge recipe
      expect(chef_run).to log "Creating template with disk resource /dev/local/data"
    end

    it 'should create file /etc/drbd.conf' do
      chef_run.converge recipe
      expect(chef_run).to create_file_with_content '/etc/drbd.conf',
        /^# Generated by Chef for (\w*)$/
      expect(chef_run).to create_file_with_content "/etc/drbd.conf",
        "resource data" 
      expect(chef_run).to create_file_with_content "/etc/drbd.conf",
        "device    /dev/drbd0;"
      expect(chef_run).to create_file_with_content "/etc/drbd.conf",
        "disk      /dev/local/data;"
      expect(chef_run).to create_file_with_content "/etc/drbd.conf",
        "address   #{server_ip}:7789"
      expect(chef_run).to create_file_with_content "/etc/drbd.conf",
        "address   #{partner_ip}:7789"
      expect(chef_run).to create_file_with_content "/etc/drbd.conf",
        "protocol C;"
      expect(chef_run).to create_file_with_content "/etc/drbd.conf",
        "rate 36M"
      expect(chef_run).to create_file_with_content "/etc/drbd.conf",
        "on-io-error detach"
    end
  end

  shared_examples_for 'extended_drbd - fresh' do
    before :each do
      File.stub(:exists?).and_call_original
      File.stub(:exists?).with('/etc/drbd.conf').and_return(false)
    end
    it_should_behave_like 'extended_drbd'

    it 'should not execute the adjust drbd resource' do
      chef_run.converge recipe
      #TODO: figure out why the not_to execute statement does not work
#      expect(chef_run).not_to execute_command('drbdadm adjust all')
    end
  end

  shared_examples_for 'extended_drbd - inplace' do
    before :each do
      File.stub(:exists?).and_call_original
      File.stub(:exists?).with('/etc/drbd.conf').and_return(true)
    end
    it_should_behave_like 'extended_drbd'

    it 'should execute the adjust drbd resource' do
      chef_run.converge recipe
      expect(chef_run).to execute_command('drbdadm adjust all')
    end

  end

  context 'RHEL5' do
    before :each do
      chef_run.node.automatic_attrs['platform_version'] = '5.8'
    end
    it_should_behave_like 'extended_drbd - inplace'
    it_should_behave_like 'extended_drbd - fresh'

  end

  context 'RHEL6' do
    before :each do
    end

    it_should_behave_like 'extended_drbd - inplace'
    it_should_behave_like 'extended_drbd - fresh'
  end
    
    
end

# vim: ai et ts=2 sts=2 sw=2 ft=ruby
