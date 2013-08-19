require 'spec_helper'

describe 'extended_drbd::drbd_fresh_install' do
  let(:recipe) { 'extended_drbd::drbd_fresh_install' }
  let(:server_name) { "test1" }
  let(:server_ip) { "192.168.1.1" }
  let(:partner_name) { "test2" }
  let(:partner_ip) { "192.168.1.2" }
  let(:chef_run) {
    runner = ChefSpec::ChefRunner.new(RUNNER_OPTS) do |node|
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

  before :each do
    Chef::Recipe.any_instance.should_receive(:wait_until).with(
      "wait until drbd is in a constant state")
    Chef::ResourceCollection.any_instance.stub(:find).with('service[drbd]')
    Chef::ResourceCollection.any_instance.stub(:find).with(
      'execute[configure fs]')
    Chef::ResourceCollection.any_instance.stub(:find).with(
      'extended_drbd_immutable_file[/etc/drbd_initialized_stop_file]')
    Chef::ResourceCollection.any_instance.stub(:find).with(
      'extended_drbd_immutable_file[/etc/drbd_stop_file]')
  end

  shared_examples_for 'extended_drbd::drbd_fresh_install' do
    it 'should include recipe extended_drbd::default' do
      chef_run.converge recipe
      expect(chef_run).to include_recipe 'extended_drbd'
    end

    it 'should execute modprobe drbd' do
      chef_run.converge recipe
      expect(chef_run).to execute_command 'modprobe drbd'
    end
  end

  shared_examples_for 'drbd_fresh_install - stop file exists' do
    before :each do
      File.stub(:exists?).and_call_original
      File.stub(:exists?).with('/etc/drbd_stop_file').and_return(true)
      File.stub(:exists?).with('/etc/drbd.conf').and_return(true)
    end

    it 'should not execute drbdadm create-md all due to file existing' do
      chef_run.converge recipe
      expect(chef_run).not_to execute_command 'drbdadm create-md all'
    end

    it 'should not restart dirsrv' do
      chef_run.converge recipe
      expect(chef_run).not_to restart_service 'dirsrv'
    end
  end

  shared_examples_for 'drbd_fresh_install - no stop file' do
    before :each do
      File.stub(:exists?).and_call_original
      File.stub(:exists?).with('/etc/drbd_stop_file').and_return(false)
      File.stub(:exists?).with('/etc/drbd.conf').and_return(false)
    end


    it 'should execute drbdadm create-md all' do
      chef_run.converge recipe
      expect(chef_run).to execute_command "echo 'Running create-md' ; "+
        "yes yes |drbdadm create-md all"
    end
  end

  shared_examples_for 'drbd_fresh_install primary xfs filesystem' do
    before :each do
      chef_run.node.normal['drbd']['fs_type'] = 'xfs'
    end

    it 'should execute setup xfs filesystem' do
      File.stub(:exists?).and_call_original
      File.stub(:exists?).with('/etc/drbd.conf').and_return(false)
      chef_run.converge recipe
      expect(chef_run).to execute_command 'mkfs.xfs -L data -f /dev/drbd0'
    end
  end

  shared_examples_for 'drbd_fresh_install primary ext filesystem' do
    before :each do
      File.stub(:exists?).and_call_original
      File.stub(:exists?).with('/etc/drbd.conf').and_return(false)
    end

    it 'should execute setup ext3 file system' do
      chef_run.node.normal['drbd']['fs_type'] = 'ext3'
      chef_run.converge recipe
      expect(chef_run).to execute_command \
        'mkfs.ext3 -m 1 -L data -T news /dev/drbd0'
    end

    it 'should execute setup ext3 file system' do
      chef_run.node.normal['drbd']['fs_type'] = 'ext4'
      chef_run.converge recipe
      expect(chef_run).to execute_command \
        'mkfs.ext4 -m 1 -L data -T news /dev/drbd0'
    end

    it 'should execute configure fs command' do
      chef_run.node.normal['drbd']['fs_type'] = 'ext4'
      chef_run.converge recipe
      expect(chef_run).to execute_command 'tune2fs -c0 -i0 /dev/drbd0'
    end
  end

  shared_examples_for 'drbd_fresh_install primary server' do
    before :each do
      chef_run.node.normal['drbd']['primary']['fqdn'] = server_name
      chef_run.node.normal['drbd']['master'] = true
    end
    it_should_behave_like 'extended_drbd::drbd_fresh_install'
    it_should_behave_like 'drbd_fresh_install - stop file exists'
    it_should_behave_like 'drbd_fresh_install - no stop file'

    it 'should set this node as drbd master once primary attr is set' do
      chef_run.node.normal['drbd']['master'] = nil
      chef_run.converge recipe
      expect(chef_run).to execute_ruby_block 'check if other server is primary'
    end

    it 'should execute setup drbd on master block' do
      chef_run.converge recipe
      expect(chef_run).to execute_bash_script 'setup drbd on master'
    end

    it_should_behave_like 'drbd_fresh_install primary xfs filesystem'
    it_should_behave_like 'drbd_fresh_install primary ext filesystem'
  end

  shared_examples_for 'drbd_fresh_install secondary server' do
    before :each do
      chef_run.node.normal['drbd']['primary']['fqdn'] = partner_name
      chef_run.node.normal['drbd']['master'] = false
    end
    it_should_behave_like 'extended_drbd::drbd_fresh_install'
    it_should_behave_like 'drbd_fresh_install - stop file exists'
    it_should_behave_like 'drbd_fresh_install - no stop file'
  end

  context 'RHEL5' do
    before :each do
      chef_run.node.automatic_attrs['platform_version'] = '5.8'
    end

    it_should_behave_like 'drbd_fresh_install primary server'
    it_should_behave_like 'drbd_fresh_install secondary server'

  end

  context 'RHEL6' do
    before :each do
    end
    it_should_behave_like 'drbd_fresh_install primary server'
    it_should_behave_like 'drbd_fresh_install secondary server'
  end
end

# vim: ai et ts=2 sts=2 sw=2 ft=ruby
