base = File.expand_path('..', __FILE__)

data_bag_path             base + '/data_bags'
encrypted_data_bag_secret base + '/data_bag_key'
role_path                 base + '/roles'
cookbook_path             [ base + '/site-cookbooks', base + '/cookbooks' ]
