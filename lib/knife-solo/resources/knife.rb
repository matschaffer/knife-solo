cookbook_path ["cookbooks", "site-cookbooks"]
role_path     "roles"
data_bag_path "data_bags"

# To use encryptd data bags first generate a secret:
#   openssl rand -base64 512 | tr -d '\r\n' > data_bag_key
# Then uncomment the line below.

# encrypted_data_bag_secret "data_bag_key"

