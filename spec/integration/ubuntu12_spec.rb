require_relative 'spec_helper'

describe 'ubuntu12' do
  it 'can run a recipe' do
    provision run_list: "recipe[apache2]"
    subject.should show_apache_test_page
  end
end
