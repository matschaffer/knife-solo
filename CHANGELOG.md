# 0.3.0: _In progress_

# 0.2.0: February 12, 2013

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

# 0.1.0: January 12, 2013

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
* [Home page](http://matschaffer.github.com/knife-solo/)
  that reflects always the current release (#151)

## Thanks to our contributors!

* [Marek Hulan][ares]
* [Anton Orel][skyeagle]
* [Adam Carlile][Frozenproduce]
* [Chris Lundquist][ChrisLundquist]
* [Hiten Parmar][hrp]
* [Patrick Connolly][patcon]

# 0.0.15: November 29th, 2012

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

# 0.0.14: September 21st, 2012

* Fix argument checks (#101)
* Allow custom omnibus URLs (#99)
* Verbose logging options (#96)

## Thanks to our contributors!

* [Vaughan Rouesnel][vjpr]
* [Ryan Walker][ryandub]
* [Aaron Cruz][pferdefleisch]

# 0.0.13: August 16th, 2012

* Less agressive in-kitchen check (36a14161a1c)
* New curl/wget selection during omnibus install (#84)
* FreeBSD 9.0 support (#78)
* Syntax-check-only switch (#74)
* Validate CLI user/host args (#73)

## Thanks to our contributors!

* [Deepak Kannan][deepak]
* [Florian Unglaub][funglaub]

# 0.0.12: June 25th, 2012

* Better validation on CLI args (#68, #70)
* Switch from wget to curl (#66)
* Initial fedora support (not under integration) (#67)
* Support new omnibus path (/opt/chef)

## Thanks to our contributors!

* [Bryan Helmkamp][brynary]
* [Greg Fitzgerald][gregf]
* [Deepak Kannan][deepak]

# 0.0.11: June 16th, 2012

* Encrypted data bag support (#22)
* Updated dependency version (#63, #64)
* Joyent Ubuntu detection (#62)
* Omnibus version selection (#61)

## Thanks to our contributors!

* [Hector Castro][hectcastro]
* [Sean Porter][portertech]

# 0.0.10: May 30th, 2012

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

# 0.0.9: May 13th, 2012

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

# 0.0.8: February 10, 2012

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

# 0.0.7: Dec 9, 2011

* BUG #9: Fix intelligent sudo handling for OSes that don't have it
* Move integration tests into proper test cases
* CentOS 5.6 integration test

# 0.0.6: Dec 8, 2011

* Support for Mac OS 10.5 and 10.6 (00921ebd1b93)
* Parallel integration testing and SLES (167360d447..167360d447)
* Dynamic sudo detection for yum-based systems (5282fc36ac3..256f27658a06cb)

## Thanks to our contributors!

* [Sergio Rubio][rubiojr]
* [Nat Lownes][natlownes]

# 0.0.5: Oct 31, 2011

* Started on integration testing via EC2
* Add openSuSE support. Installation via zypper. (64ff2edf42)
* Upgraded Rubygems to 1.8.10 (8ac1f4d43a)

# 0.0.4: Oct 7, 2011

* Chef 0.10.4 based databag and search method (a800880e6d)
* Proper path for roles (b143ae290a)
* Test fixes for CI compatibility (ccf4247125..62b8bd498d)

## Thanks to our contributors!

* [John Dewey][retr0h]

# 0.0.3: July 31, 2011

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
[avit]:          https://github.com/avit
[brynary]:       https://github.com/brynary
[btm]:           https://github.com/btm
[davidsch]:      https://github.com/davidsch
[deepak]:        https://github.com/deepak
[fnichol]:       https://github.com/fnichol
[funglaub]:      https://github.com/funglaub
[gregf]:         https://github.com/gregf
[gsterndale]:    https://github.com/gsterndale
[hectcastro]:    https://github.com/hectcastro
[hrp]:           https://github.com/hrp
[jgarber]:       https://github.com/jgarber
[jgrevich]:      https://github.com/jgrevich
[natlownes]:     https://github.com/natlownes
[patatepartie]:  https://github.com/patatepartie
[patcon]:        https://github.com/patcon
[pferdefleisch]: https://github.com/pferdefleisch
[portertech]:    https://github.com/portertech
[retr0h]:        https://github.com/retr0h
[rmoriz]:        https://github.com/rmoriz
[rosstimson]:    https://github.com/rosstimson
[rubiojr]:       https://github.com/rubiojr
[russellcardullo]: https://github.com/russellcardullo
[ryandub]:       https://github.com/ryandub
[skyeagle]:      https://github.com/skyeagle
[smdern]:        https://github.com/smdern
[tknerr]:        https://github.com/tknerr
[tmatilai]:      https://github.com/tmatilai
[vjpr]:          https://github.com/vjpr
[zeph]:          https://github.com/zeph
