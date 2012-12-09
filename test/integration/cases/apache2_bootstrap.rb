# Tries to bootstrap with apache2 cookbook and
# verifies the "It Works!" page is present.

require $base_dir.join('integration', 'cases', 'apache2_cook')

module Apache2Bootstrap
  include Apache2Cook

  def test_apache2
    write_cheffile
    system "librarian-chef install >> #{log_file}"
    assert_subcommand "solo bootstrap --run-list=recipe[apache2]"
    assert_match default_apache_message, http_response
  end
end
