module CachePathUsage
  def setup
    super
    FileUtils.cp_r $base_dir.join('support', 'cache_using_cookbook'), 'site-cookbooks/cache_using_cookbook'
  end

  def test_changing_a_cached_directory_between_cooks
    write_nodefile(run_count: 1, run_list: ["cache_using_cookbook"])
    assert_subcommand "cook"
    write_nodefile(run_count: 2, run_list: ["cache_using_cookbook"])
    assert_subcommand "cook"
  end
end
