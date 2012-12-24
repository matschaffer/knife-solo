# Tries to cook with apache2 cookbook and
# verifies the "It Works!" page is present.
module Apache2Cook
  def write_cheffile
    File.open('Cheffile', 'w') do |f|
      f.print <<-CHEF
            site 'http://community.opscode.com/api/v1'
            cookbook 'apache2'
      CHEF
    end
  end

  def http_response
    Net::HTTP.get(URI.parse("http://"+server.public_ip_address))
  end

  def default_apache_message
    /Apache Server/
  end

  def test_apache2
    write_cheffile
    system "librarian-chef install >> #{log_file}"
    write_nodefile(run_list: ["recipe[apache2]"])
    assert_subcommand "cook"
    assert_match default_apache_message, http_response
  end
end
