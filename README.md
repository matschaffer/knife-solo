# knife-solo

[![Version](http://allthebadges.io/matschaffer/knife-solo/badge_fury.png)](http://allthebadges.io/matschaffer/knife-solo/badge_fury)
[![Dependencies](http://allthebadges.io/matschaffer/knife-solo/gemnasium.png)](http://allthebadges.io/matschaffer/knife-solo/gemnasium)
[![Build Status](http://allthebadges.io/matschaffer/knife-solo/travis.png)](http://allthebadges.io/matschaffer/knife-solo/travis)
[![Coverage](http://allthebadges.io/matschaffer/knife-solo/coveralls.png)](http://allthebadges.io/matschaffer/knife-solo/coveralls)
[![Code Climate](http://allthebadges.io/matschaffer/knife-solo/code_climate.png)](http://allthebadges.io/matschaffer/knife-solo/code_climate)

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
git submodule update --init
bundle && bundle exec rake install
```

Documentation for the latest master version of knife-solo is available in [README.rdoc](https://github.com/matschaffer/knife-solo/blob/master/README.rdoc).
