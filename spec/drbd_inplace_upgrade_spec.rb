require 'chefspec'

describe 'extended_drbd::drbd_inplace_upgrade' do
  let(:recipe) { 'extended_drbd::drbd_inplace_upgrade' }
  let(:server_name) { "test1" }
  let(:server_ip) { "192.168.1.1" }
  let(:partner_name) { "test2" }
  let(:partner_ip) { "192.168.1.2" }
  let(:chef_run) {
    runner = ChefSpec::ChefRunner.new(platform: 'redhat', version: '6.3',
      :step_into => ['extended_drbd_immutable_file']) do |node|
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

  shared_examples_for 'extended_drbd::drbd_inplace_upgrade' do
    it 'should include recipe extended_drbd::default' do
      chef_run.converge recipe
      expect(chef_run).to include_recipe 'extended_drbd'
    end

    it 'should execute create stop files' do
      chef_run.converge recipe
      expect(chef_run).to execute_command "echo 'Creating stop files'"
    end
  end
  context 'RHEL5' do
    before :each do
      chef_run.node.automatic_attrs['platform_version'] = '5.8'
    end

    it_should_behave_like 'extended_drbd::drbd_inplace_upgrade'

  end

  context 'RHEL6' do
    before :each do
    end

    it_should_behave_like 'extended_drbd::drbd_inplace_upgrade'
  end
end

# vim: ai et ts=2 sts=2 sw=2 ft=ruby
