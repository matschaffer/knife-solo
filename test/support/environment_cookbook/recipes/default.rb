file "/etc/chef_environment" do
  mode 0644
  content "#{node.chef_environment}/#{node['environment']['test_attribute']}"
end
