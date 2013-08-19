require 'spec_helper'

describe 'extended_drbd::iptables' do
  let(:recipe) { 'extended_drbd::iptables' }
  let(:server_name) { "test1" }
  let(:server_ip) { "192.168.1.1" }
  let(:partner_name) { "test2" }
  let(:partner_ip) { "192.168.1.2" }
  let(:chef_run) {
    runner = ChefSpec::ChefRunner.new(RUNNER_OPTS.merge(
      :step_into => ['extended_drbd_immutable_file'])) do |node|
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
    Chef::Recipe.any_instance.stub(:iptables_rule)
    Chef::ResourceCollection.any_instance.stub(:find).with(
      'execute[rebuild-iptables]')
  end

  shared_examples_for 'extended_drbd::iptables - enabled' do
    it 'should include recipe iptables' do
      Chef::Recipe.any_instance.unstub(:iptables_rule)
      Chef::Recipe.any_instance.should_receive(:iptables_rule).
        with('drbd_port').and_yield
      Chef::Recipe.any_instance.should_receive(:source).
        with('iptables/drbd.erb')
      chef_run.converge recipe
      expect(chef_run).to include_recipe 'iptables'
    end

    it 'should execute rebuild when the file does not exist' do
      File.stub(:exists?).and_call_original
      File.stub(:exists?).with('/etc/iptables.d/drbd_port').and_return(false)
      chef_run.converge recipe
      expect(chef_run).to execute_ruby_block 'rebuild iptables now'
    end

    it 'should build file bc does not exists' do
      Chef::Recipe.any_instance.unstub(:iptables_rule)
      Chef::Recipe.any_instance.should_receive(:iptables_rule).
        with('drbd_port').and_yield
      Chef::Recipe.any_instance.should_receive(:source).
        with('iptables/drbd.erb')
      chef_run.converge recipe
    end

    it 'should not execute rebuild when the file does exist' do
      File.stub(:exists?).and_call_original
      File.stub(:exists?).with('/etc/iptables.d/drbd_port').and_return(true)
      chef_run.converge recipe
      expect(chef_run).not_to execute_ruby_block 'rebuild iptables now'
    end

  end

  shared_examples_for 'extended_drbd::iptables - disabled' do
    before :each do
      chef_run.node.normal['iptables']['enabled'] = false
    end

    it 'should include recipe iptables::disabled' do
      chef_run.converge recipe
      expect(chef_run).to include_recipe 'iptables::disabled'
    end
  end

  context 'RHEL5' do
    before :each do
      chef_run.node.automatic_attrs['platform_version'] = '5.8'
    end

    it_should_behave_like 'extended_drbd::iptables - enabled'
    it_should_behave_like 'extended_drbd::iptables - disabled'

  end

  context 'RHEL6' do
    before :each do
    end

    it_should_behave_like 'extended_drbd::iptables - enabled'
    it_should_behave_like 'extended_drbd::iptables - disabled'
  end
end

# vim: ai et ts=2 sts=2 sw=2 ft=ruby
