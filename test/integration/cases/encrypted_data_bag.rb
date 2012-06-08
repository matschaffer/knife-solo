require 'chef/encrypted_data_bag_item'

module EncryptedDataBag
  def setup
    super
    FileUtils.cp $base_dir.join('support', 'data_bag_key'), 'data_bag_key'
    FileUtils.cp_r $base_dir.join('support', 'secret_cookbook'), 'cookbooks/secret_cookbook'
    @password = "essential particles busy loud"
    create_data_bag
  end

  def create_data_bag
    secret = Chef::EncryptedDataBagItem.load_secret('data_bag_key')
    data = {"id" => "passwords", "admin" => @password}
    encrypted_data = Chef::EncryptedDataBagItem.encrypt_data_bag_item(data, secret)
    write_json_file('data_bags/dev/passwords.json', encrypted_data)
  end

  def test_reading_encrypted_data_bag
    write_nodefile(run_list: ["recipe[secret_cookbook]"])
    assert_subcommand "cook"
    actual = `ssh -i #{key_file} #{user}@#{server.public_ip_address} cat /etc/admin_password`
    assert_equal @password, actual
  end
end
