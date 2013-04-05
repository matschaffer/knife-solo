require 'chef/encrypted_data_bag_item'

module EncryptedDataBag
  def setup
    super
    FileUtils.cp $base_dir.join('support', 'data_bag_key'), 'data_bag_key'
    FileUtils.cp_r $base_dir.join('support', 'secret_cookbook'), 'cookbooks/secret_cookbook'
    File.open('.chef/knife.rb', 'a') do |f|
      f.puts 'encrypted_data_bag_secret "data_bag_key"'
    end
    @password = "essential particles busy loud"
    create_data_bag
  end

  def create_data_bag
    secret = Chef::EncryptedDataBagItem.load_secret('data_bag_key')
    data = {"id" => "passwords", "admin" => @password}
    encrypted_data = Chef::EncryptedDataBagItem.encrypt_data_bag_item(data, secret)
    write_json_file('data_bags/dev/passwords.json', encrypted_data)
  end

  # Test that we can read an encrypted data bag value
  # NOTE: This shells out to ssh, so may not be windows-compatible
  def test_reading_encrypted_data_bag
    write_nodefile(run_list: ["recipe[secret_cookbook]"])
    assert_subcommand "cook"
    actual = `ssh #{connection_string} cat /etc/admin_password`
    assert_equal @password, actual
  end
end
