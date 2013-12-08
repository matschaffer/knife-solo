# 0.4.2 / _In progress_

## Changes and new features


## Fixes

## Thanks to our contributors!

# 0.4.1 / 2013-12-07

## Changes and new features

* Support Oracle Enterprise Linux ([311][])
* Support Arch Linux ([327][])
* Make sure wget is installed on Debianoids ([320][])

## Fixes

* Explicitly set root path for default `*_path` options in Chef 11.8.0 ([308][])
* Verify that `node_path` is a String ([308][])
* Fix compatibility with Ruby 1.8 ([0bcae4a][])

## Thanks to our contributors!

* [aromarom64][aromarom64]
* [Łukasz Dubiel][bambuchaAdm]
* [Takamura Soichi][piglovesyou]

[308]: https://github.com/matschaffer/knife-solo/issues/308
[311]: https://github.com/matschaffer/knife-solo/issues/311
[320]: https://github.com/matschaffer/knife-solo/issues/320
[327]: https://github.com/matschaffer/knife-solo/issues/327
[0bcae4a]: https://github.com/matschaffer/knife-solo/commit/0bcae4a

# 0.4.0 / 2013-10-30

## Changes and new features

* Add SSH option --[no-]host-key-verify ([274])
* Add --no-sync option to skip syncing and only run Chef ([284])
* Use Omnibus installer for Debian 7 ([287])
* Support Raspbian ([295])
* Support environments (from Chef 11.6.0 on) ([285])

## Fixes

* Cache SSH connections ([265])
* Support Berkshelf 3.0 ([268])
* Follow symlinks when uploading kitchen ([279], [289])
* Quote rsync paths to avoid problems with spaces in directory names ([281], [286])
* Fix precedence of automatic cookbook_path components ([296], [298])
* Print an error message if a `*_path` configuration value is not a String ([278], [300])
* Mention knife-solo_data_bag gem in the docs ([83])
* Pin to ffi 1.9.1 due to issues with newer versions
* Docs around berkshelf and librarian-chef integrations

## Thanks to our contributors!

* [Andreas Josephson][teyrow]
* [Markus Kern][makern]
* [Michael Glass][michaelglass]
* [Mathieu Allaire][allaire]

[83]:  https://github.com/matschaffer/knife-solo/issues/83
[265]: https://github.com/matschaffer/knife-solo/issues/265
[268]: https://github.com/matschaffer/knife-solo/issues/268
[274]: https://github.com/matschaffer/knife-solo/issues/274
[278]: https://github.com/matschaffer/knife-solo/issues/278
[279]: https://github.com/matschaffer/knife-solo/issues/279
[281]: https://github.com/matschaffer/knife-solo/issues/281
[284]: https://github.com/matschaffer/knife-solo/issues/284
[285]: https://github.com/matschaffer/knife-solo/issues/285
[286]: https://github.com/matschaffer/knife-solo/issues/286
[287]: https://github.com/matschaffer/knife-solo/issues/287
[289]: https://github.com/matschaffer/knife-solo/issues/289
[295]: https://github.com/matschaffer/knife-solo/issues/295
[296]: https://github.com/matschaffer/knife-solo/issues/296
[298]: https://github.com/matschaffer/knife-solo/issues/298
[300]: https://github.com/matschaffer/knife-solo/issues/300

# 0.3.0 / 2013-08-01

**NOTE**: This release includes breaking changes. See [upgrade instructions](https://github.com/matschaffer/knife-solo/wiki/Upgrading-to-0.3.0) for more information.

## Changes and new features

* BREAKING: Generate solo.rb based on knife.rb settings ([199])
    - `solo.rb` is not used and a warning is issued if it is still found
    - You have to specify the local cookbook etc. paths in `.chef/knife.rb`
* BREAKING: Set root path with `--provisioning-path` or `knife[:provisioning_path]` and use ~/chef-solo by default ([1], [86], [125], [128], [177], [197])
* BREAKING: Remove hard dependency on Librarian-Chef ([211])
    - If you use Librarian integration you need to install the librarian-chef gem yourself
* Add Berkshelf integration ([227])
* Automatically add librarian to cookbook paths when syncing ([226])
* Add `--solo` option and `knife[:solo]` configuration option to `knife bootstrap` ([207])
* `--prerelease` option to allow pre-release versions of chef omnibus or rubygem to be installed ([205])
* Prepare/bootstrap now installs the same version of Chef that the workstation is running ([186])
* Switch `--omnibus-version` flag to `--bootstrap-version` ([185])
* Support `--override-runlist` option ([204])
* Add proxy settings to the generated solo.rb ([254])
* Support Fedora 18 and other new EL distros ([229], [51a581])
* Support CloudLinux ([262])
* Drop support for openSUSE 11
* Upgrade chef-solo-search to v0.4.0
* Add `--sudo-command` option to use custom remote 'sudo' command ([256])

## Fixes

* Read protect the provision directory from the world ([1])
* FreeBSD 9.1 support
* OS X (especially 10.8) support ([209], [210])
* Clear yum cache before installing rsync ([200])
* Make sure "ca-certificates" package is installed on Debian ([213])
* Ensure rsync is installed on openSUSE ([f43ba4])
* Clean up bootstrap classes ([213])
* Rsync dot files by default, exclude only VCS dirs ([d21756], [1d3485])
* Standardize messaging across commands ([215], [d37162])
* Librarian-Chef was not run by default when knife-solo was invoked from ruby ([221])
* Fix `solo init` on Ruby 1.8 ([230])
* Fix deprecated commands to include options and dependencies from the new ones ([233])
* Parse Chef version even if chef-solo command prints warnings ([235], [238])
* Upgrade CentOS in integration tests to 5.8 and 6.3 ([237])
* Default to `lsb_release` for detecting the Linux distro and add support for RHEL based systems where /etc/issue is modified ([234], [242])
* Create the directory for node_config if it does not exist ([253])
* Accept trailing whitespace in passwords ([264])

## Thanks to our contributors!

* [David Kinzer][dkinzer]
* [Naoya Ito][naoya]
* [David Radcliffe][dwradcliffe]
* [Łukasz Dubiel][bambuchaAdm]
* [kmdsbng][kmdsbng]
* [Darshan Patil][dapatil]
* [Shin Tokiwa][tocky]
* [Sam Martin][searlm]

[1]: https://github.com/matschaffer/knife-solo/issues/1
[86]: https://github.com/matschaffer/knife-solo/issues/86
[125]: https://github.com/matschaffer/knife-solo/issues/125
[128]: https://github.com/matschaffer/knife-solo/issues/128
[177]: https://github.com/matschaffer/knife-solo/issues/177
[185]: https://github.com/matschaffer/knife-solo/issues/185
[186]: https://github.com/matschaffer/knife-solo/issues/186
[197]: https://github.com/matschaffer/knife-solo/issues/197
[199]: https://github.com/matschaffer/knife-solo/issues/199
[200]: https://github.com/matschaffer/knife-solo/issues/200
[204]: https://github.com/matschaffer/knife-solo/issues/204
[205]: https://github.com/matschaffer/knife-solo/issues/205
[207]: https://github.com/matschaffer/knife-solo/issues/207
[209]: https://github.com/matschaffer/knife-solo/issues/209
[210]: https://github.com/matschaffer/knife-solo/issues/210
[211]: https://github.com/matschaffer/knife-solo/issues/211
[213]: https://github.com/matschaffer/knife-solo/issues/213
[215]: https://github.com/matschaffer/knife-solo/issues/215
[221]: https://github.com/matschaffer/knife-solo/issues/221
[226]: https://github.com/matschaffer/knife-solo/issues/226
[227]: https://github.com/matschaffer/knife-solo/issues/227
[229]: https://github.com/matschaffer/knife-solo/issues/229
[230]: https://github.com/matschaffer/knife-solo/issues/230
[233]: https://github.com/matschaffer/knife-solo/issues/233
[234]: https://github.com/matschaffer/knife-solo/issues/234
[235]: https://github.com/matschaffer/knife-solo/issues/235
[237]: https://github.com/matschaffer/knife-solo/issues/237
[238]: https://github.com/matschaffer/knife-solo/issues/238
[242]: https://github.com/matschaffer/knife-solo/issues/242
[253]: https://github.com/matschaffer/knife-solo/issues/253
[254]: https://github.com/matschaffer/knife-solo/issues/254
[256]: https://github.com/matschaffer/knife-solo/issues/256
[262]: https://github.com/matschaffer/knife-solo/issues/262
[264]: https://github.com/matschaffer/knife-solo/issues/264
[d21756]: https://github.com/matschaffer/knife-solo/commit/d21756
[1d3485]: https://github.com/matschaffer/knife-solo/commit/1d3485
[f43ba4]: https://github.com/matschaffer/knife-solo/commit/f43ba4
[51a581]: https://github.com/matschaffer/knife-solo/commit/51a581
[d37162]: https://github.com/matschaffer/knife-solo/commit/d37162

# 0.2.0 / 2013-02-12

## Changes and new features

* Post-install hook to remind people about removing old gems (#152)
* Support Chef 11 (#183)
* Rename Cook command's `--skip-chef-check` option to `--no-chef-check (#162)
* Rename `--ssh-identity` option to `--identity-file` (#178)
* Add `--ssh-user option` (#179)
* Add `--no-librarian` option to bootstrap and cook commands (#180)
* Generate Cheffile and .gitignore on `knife solo init --librarian` (#182)
* Windows client compatibility (#156, #91)
* Support Amazon Linux (#181)
* Support unknown/unreleased Debian versions by using the
  gem installer (#172)
* Drop support for Debian 5.0 Lenny (#172)
* Integration tests for Debian 6 and 7 (74c6ed1 - f299a6)
* Travis tests for both Chef 10 and 11 (#183)

## Fixes

* Fix Debian 7.0 Wheezy support by using gem installer (#172)
* Fix compatibility with Ruby 1.8.7 on work station (#170)
* Fix Chef version checking if sudo promts password (#190)
* Fix compatibility (net-ssh dependency) with Chef 10.20.0 and 11.2.0 (#188)
* Fail CI if manifest isn't updated (#195)
* Better unit tests around solo cook
* Other fixes: #166, #168, #173, #194

## Thanks to our contributors!

* [Russell Cardullo][russellcardullo]
* [tknerr][tknerr]
* [Shaun Dern][smdern]
* [Mike Bain][TheAlphaTester]

# 0.1.0 / 2013-01-12

## Changes and new features

* Move all commands under "knife solo" namespace (#118)
    - Rename `knife kitchen` to `knife solo init`
    - Rename `knife wash_up` to `knife solo clean`
* Add `knife solo bootstrap` command (#120)
* OmniOS support (#144)
* Detect Fedora 17 (#141)
* Update chef-solo-search and add support of encrypted data bags (#127)
* Support Librarian (#36)
* Always install rsync from yum on RPM-based Linuxes (#157)
* Debian wheezy (7) support (#165)

## Fixes

* Improve help/error messages and validation (#142)
* Fix exit status of "cook" if chef-solo fails (#97)
* Fix option passing to the Omnibus installer (#163)
* Other fixes: SuSE omnibus #146, #155, #158, #160, #164

## Documentation

* Include documentation and tests in the gem (e01c23)
* [Home page](http://matschaffer.github.io/knife-solo/)
  that reflects always the current release (#151)

## Thanks to our contributors!

* [Marek Hulan][ares]
* [Anton Orel][skyeagle]
* [Adam Carlile][Frozenproduce]
* [Chris Lundquist][ChrisLundquist]
* [Hiten Parmar][hrp]
* [Patrick Connolly][patcon]

# 0.0.15 / 2012-11-29

* Support for non-x86 omnibus (#137)
* Validate hostname in wash\_up (7a9115)
* Scientific Linux support (#131)
* Default to SSL omnibus URL (#130)
* Fixes for base debian installations (#129)
* Whyrun flag support (#123)
* Node-name flag support (#107)
* No More Syntax Check!! (#122)

* Various fixes: #138, #119, #113, d38bfd1

## Thanks to our contributors!

* [David Schneider][davidsch]
* [Andrew Vit][avit]
* [Nick Shortway][DrGonzo65]
* [Guido Serra aka Zeph][zeph]
* [Patrick Connolly][patcon]
* [Greg Fitzgerald][gregf]
* [Bryan McLellan][btm]
* [Aaron Jensen][aaronjensen]

And a special thanks to [Teemu Matilainen][tmatilai] who is now on the list of direct colaborators!

# 0.0.14 / 2012-09-21

* Fix argument checks (#101)
* Allow custom omnibus URLs (#99)
* Verbose logging options (#96)

## Thanks to our contributors!

* [Vaughan Rouesnel][vjpr]
* [Ryan Walker][ryandub]
* [Aaron Cruz][pferdefleisch]

# 0.0.13 / 2012-08-16

* Less agressive in-kitchen check (36a14161a1c)
* New curl/wget selection during omnibus install (#84)
* FreeBSD 9.0 support (#78)
* Syntax-check-only switch (#74)
* Validate CLI user/host args (#73)

## Thanks to our contributors!

* [Deepak Kannan][deepak]
* [Florian Unglaub][funglaub]

# 0.0.12 / 2012-06-25

* Better validation on CLI args (#68, #70)
* Switch from wget to curl (#66)
* Initial fedora support (not under integration) (#67)
* Support new omnibus path (/opt/chef)

## Thanks to our contributors!

* [Bryan Helmkamp][brynary]
* [Greg Fitzgerald][gregf]
* [Deepak Kannan][deepak]

# 0.0.11 / 2012-06-16

* Encrypted data bag support (#22)
* Updated dependency version (#63, #64)
* Joyent Ubuntu detection (#62)
* Omnibus version selection (#61)

## Thanks to our contributors!

* [Hector Castro][hectcastro]
* [Sean Porter][portertech]

# 0.0.10 / 2012-05-30

* Include apache recipe during integration testing (#17)
* Use omnibus installer on Ubuntu and RedHat (#40, #45, #58)
* `knife wash_up` command for removing uploaded resources (#48)
* Cleaner sudo pre-processing (#59)
* Support `knife kitchen .` to init an existing kitchen (#54)

## Thanks to our contributors!

* [Hector Castro][hectcastro]
* [Nix-wie-weg][Nix-wie-weg]
* [Justin Grevich][jgrevich]
* [Ross Timson][rosstimson]

# 0.0.9 / 2012-05-13

* Chef 0.10.10 compatibility (b0fa50e9)
* Finished support and integration testing for remaining key OSes (Issues #2 and #15)
* Added support for 'chefignore' (e4bcbd1..4b578cf9)
* Use `lsb_release` to detect OSes where possible (c976cc119..a31d8234b)
* Ignore `tmp` and `deploy_revision` to rsync exclusion (7d252ff2b)

## Thanks to our contributors!

* [Hector Castro][hectcastro]
* [Amos Lanka][amoslanka]
* [Roland Moriz][rmoriz]
* [Tyler Rick][TylerRick]
* [Motiejus Jakštys][Motiejus]

# 0.0.8 / 2012-02-10

* Add --startup-script which gets sourced before any command to setup env vars (e.g., ~/.bashrc) (d1489f94)
* Use curl + rpm rather than rpm against direct URL for better proxy support (51ad9c51)
* Integration harness improvements (1ac5cce..4be36c2)
* BUG #10: Create .gitkeep's to avoid errors on sparse kitchens (074b4e0a)
* Add --skip-chef-check knife option (a1a66ae)

## Thanks to our contributors!

* [Cyril Ledru][patatepartie]
* [Fletcher Nichol][fnichol]
* [Jason Garber][jgarber]
* [Greg Sterndale][gsterndale]

# 0.0.7 / 2011-12-09

* BUG #9: Fix intelligent sudo handling for OSes that don't have it
* Move integration tests into proper test cases
* CentOS 5.6 integration test

# 0.0.6 / 2011-12-08

* Support for Mac OS 10.5 and 10.6 (00921ebd1b93)
* Parallel integration testing and SLES (167360d447..167360d447)
* Dynamic sudo detection for yum-based systems (5282fc36ac3..256f27658a06cb)

## Thanks to our contributors!

* [Sergio Rubio][rubiojr]
* [Nat Lownes][natlownes]

# 0.0.5 / 2011-10-31

* Started on integration testing via EC2
* Add openSuSE support. Installation via zypper. (64ff2edf42)
* Upgraded Rubygems to 1.8.10 (8ac1f4d43a)

# 0.0.4 / 2011-10-07

* Chef 0.10.4 based databag and search method (a800880e6d)
* Proper path for roles (b143ae290a)
* Test fixes for CI compatibility (ccf4247125..62b8bd498d)

## Thanks to our contributors!

* [John Dewey][retr0h]

# 0.0.3 / 2011-07-31

* Kitchen directory generation
* Prepare tested on ubuntu
* Generate node config on prepare
* Cook via rsync

[ChrisLundquist]:https://github.com/ChrisLundquist
[DrGonzo65]:     https://github.com/DrGonzo65
[Frozenproduce]: https://github.com/Frozenproduce
[Motiejus]:      https://github.com/Motiejus
[Nix-wie-weg]:   https://github.com/Nix-wie-weg
[TheAlphaTester]:https://github.com/TheAlphaTester
[TylerRick]:     https://github.com/TylerRick
[aaronjensen]:   https://github.com/aaronjensen
[amoslanka]:     https://github.com/amoslanka
[ares]:          https://github.com/ares
[aromarom64]:    https://github.com/aromarom64
[avit]:          https://github.com/avit
[bambuchaAdm]:   https://github.com/bambuchaAdm
[brynary]:       https://github.com/brynary
[btm]:           https://github.com/btm
[dapatil]:       https://github.com/dapatil
[davidsch]:      https://github.com/davidsch
[deepak]:        https://github.com/deepak
[dkinzer]:       https://github.com/dkinzer
[dwradcliffe]:   https://github.com/dwradcliffe
[fnichol]:       https://github.com/fnichol
[funglaub]:      https://github.com/funglaub
[gregf]:         https://github.com/gregf
[gsterndale]:    https://github.com/gsterndale
[hectcastro]:    https://github.com/hectcastro
[hrp]:           https://github.com/hrp
[jgarber]:       https://github.com/jgarber
[jgrevich]:      https://github.com/jgrevich
[kmdsbng]:       https://github.com/kmdsbng
[makern]:        https://github.com/makern
[michaelglass]:  https://github.com/michaelglass
[naoya]:         https://github.com/naoya
[natlownes]:     https://github.com/natlownes
[patatepartie]:  https://github.com/patatepartie
[patcon]:        https://github.com/patcon
[pferdefleisch]: https://github.com/pferdefleisch
[piglovesyou]:   https://github.com/piglovesyou
[portertech]:    https://github.com/portertech
[retr0h]:        https://github.com/retr0h
[rmoriz]:        https://github.com/rmoriz
[rosstimson]:    https://github.com/rosstimson
[rubiojr]:       https://github.com/rubiojr
[russellcardullo]: https://github.com/russellcardullo
[ryandub]:       https://github.com/ryandub
[searlm]:        https://github.com/searlm
[skyeagle]:      https://github.com/skyeagle
[smdern]:        https://github.com/smdern
[teyrow]:        https://github.com/teyrow
[tknerr]:        https://github.com/tknerr
[tmatilai]:      https://github.com/tmatilai
[tocky]:         https://github.com/tocky
[vjpr]:          https://github.com/vjpr
[zeph]:          https://github.com/zeph
[allaire]:       https://github.com/allaire
