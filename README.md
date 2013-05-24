# knife-solo

[![Build Status](https://travis-ci.org/matschaffer/knife-solo.png)](https://travis-ci.org/matschaffer/knife-solo)
[![Code Climate](https://codeclimate.com/github/matschaffer/knife-solo.png)](https://codeclimate.com/github/matschaffer/knife-solo)
[![Dependency Status](https://gemnasium.com/matschaffer/knife-solo.png)](https://gemnasium.com/matschaffer/knife-solo)

## Description

knife-solo adds a handful of Knife commands that aim to make working with chef-solo as powerful as chef-server.

## Usage

Simply ensure the gem is installed using:
```sh
gem install knife-solo
```

Or add this to your Gemfile if you use bundler:
```ruby
gem 'knife-solo'
```

Having the gem installed will add Knife subcommands. Run `knife solo` with no arguments to see a list of available commands.

## Documentation

More complete usage documentation for the current release is available at [matschaffer.github.io/knife-solo](http://matschaffer.github.io/knife-solo).

## Cutting Edge

To use the version from the git repository add this to your Gemfile:
```ruby
gem 'knife-solo',
  :github => 'matschaffer/knife-solo',
  :branch => 'master',
  :submodules => true
```
**Note**: For Knife to find solo subcommands, you need to put `bundle exec` in front of all `knife solo` calls. Other options is to use the `knife` executable installed by `bundle install --binstubs`.

To install knife-solo from source run:
```sh
git submodule init && git submodule update
bundle && bundle exec rake install
```

Documentation for the latest master version of knife-solo is available in [README.rdoc](https://github.com/matschaffer/knife-solo/blob/master/README.rdoc).
