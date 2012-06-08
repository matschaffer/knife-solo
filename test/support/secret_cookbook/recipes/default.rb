passwords = Chef::EncryptedDataBagItem.load("dev", "passwords")

file "/etc/admin_password" do
  # This mode is a terrible idea for passwords
  # but makes verification easier
  mode 0644
  content passwords["admin"]
end
