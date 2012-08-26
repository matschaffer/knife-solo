require_relative 'spec_helper'
require 'open3'

describe 'ubuntu 12.04' do
  before(:all) do
    system({'VAGRANT_CWD' => VAGRANT_CWD}, "vagrant up ubuntu12")
  end

  after(:all) do
    system({'VAGRANT_CWD' => VAGRANT_CWD}, "vagrant halt ubuntu12")
  end

  it 'should be preparable' do
    true.should == false
  end
end
