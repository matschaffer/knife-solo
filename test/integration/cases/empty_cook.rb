# Tries to run cook on the box
module EmptyCook
  def test_empty_cook
    write_nodefile(run_list: [])
    assert_subcommand "cook"
  end
end

