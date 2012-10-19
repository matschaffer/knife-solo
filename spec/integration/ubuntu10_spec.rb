require_relative 'spec_helper'

describe 'ubuntu10' do
  it 'can run a recipe with tests' do
    provision(run_list: [ "recipe[apache2]" ]).should == true
  end

  it 'fails on a bad run' do
    provision(run_list: [ "recipe[no-recipe-here]" ]).should == false
  end
end
