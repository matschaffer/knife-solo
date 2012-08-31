require_relative 'spec_helper'

describe 'ubuntu12' do
  it 'can run a recipe with tests' do
    provision(run_list: [ "recipe[minitest-handler]", "recipe[apache2]" ]).should == true
  end
end
