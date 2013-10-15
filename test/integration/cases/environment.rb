module Environment
  def setup
    super
    FileUtils.cp_r $base_dir.join('support', 'environment_cookbook'), 'site-cookbooks/environment_cookbook'
    FileUtils.cp $base_dir.join('support', 'test_environment.json'), 'environments/test_environment.json'
  end

  def cook_environment(node)
    write_nodefile(node)
    assert_subcommand "cook"
    `ssh #{connection_string} cat /etc/chef_environment`
  end

  # Test that chef picks up environments properly
  # NOTE: This shells out to ssh, so may not be windows-compatible
  def test_chef_environment
    # If no environment is specified chef needs to use "_default" and attribute from cookbook
    actual = cook_environment(run_list: ["recipe[environment_cookbook]"])
    assert_equal "_default/untouched", actual

    # If one is specified chef needs to pick it up and get override attibute
    actual = cook_environment(run_list: ["recipe[environment_cookbook]"], environment: 'test_environment')
    assert_equal "test_environment/test_env_was_here", actual
  end
end
