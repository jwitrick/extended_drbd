require 'chefspec'
require 'tmpdir'
require 'fileutils'

RSpec.configure do |c|
  c.color_enabled = true

  c.before(:suite) do
    COOKBOOK_PATH = Dir.mktmpdir 'chefspec'
    FileUtils.ln_s(File.expand_path('../..', __FILE__), COOKBOOK_PATH)
    RUNNER_OPTS = {
      :cookbook_path => COOKBOOK_PATH, :platform => 'redhat', :version => '6.3'
    }
  end

  c.before(:each) do
    # Don't worry about external cookbook dependencies
    Chef::Cookbook::Metadata.any_instance.stub(:depends)

    # Test each recipe in isolation, regardless of includes
    @included_recipes = []
    Chef::RunContext.any_instance.stub(:loaded_recipe?).and_return(false)
    Chef::Recipe.any_instance.stub(:include_recipe) do |i|
      Chef::RunContext.any_instance.stub(:loaded_recipe?).with(i).and_return(
        true)
      @included_recipes << i
    end
    Chef::RunContext.any_instance.stub(:loaded_recipes).and_return(
      @included_recipes)

    # Drop extraneous writes to stdout
    Chef::Formatters::Doc.any_instance.stub(:library_load_start)
  end
end

RSpec.configure do |c|
  c.after(:suite) { FileUtils.rm_r(COOKBOOK_PATH) }
end

# vim: ai et ts=2 sts=2 sw=2 ft=ruby
