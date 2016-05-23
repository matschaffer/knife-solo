# knife-solo

[![Gitter](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/matschaffer/knife-solo?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

[![Stories in Ready](https://badge.waffle.io/matschaffer/knife-solo.png?label=ready&title=Ready)](https://waffle.io/matschaffer/knife-solo)
[![Version](http://img.shields.io/gem/v/knife-solo.svg)](http://allthebadges.io/matschaffer/knife-solo/badge_fury)
[![Dependencies](http://img.shields.io/gemnasium/matschaffer/knife-solo.svg)](http://allthebadges.io/matschaffer/knife-solo/gemnasium)
[![Build Status](http://img.shields.io/travis/matschaffer/knife-solo.svg)](http://allthebadges.io/matschaffer/knife-solo/travis)
[![Coverage](http://img.shields.io/coveralls/matschaffer/knife-solo.svg)](http://allthebadges.io/matschaffer/knife-solo/coveralls)
[![Code Climate](http://img.shields.io/codeclimate/github/matschaffer/knife-solo.svg)](http://allthebadges.io/matschaffer/knife-solo/code_climate)

## Description

knife-solo adds a handful of Knife commands that aim to make working with chef-solo as powerful as chef-server.

## Usage

Simply ensure the gem is installed using:
```sh
gem install knife-solo

# or if using ChefDK
chef gem install knife-solo
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

## Issues

Traffic on this project is still fairly low, so a mailing list seems like "too much". Since we don't have one feel free to file an issue for any problems or questions you have while using knife-solo.

If you'd like to help work on issues, I recommend using [waffle.io](https://waffle.io/matschaffer/knife-solo) to keep track of work in progress. The gray issue labels on this project are for use with the waffle.io board.


