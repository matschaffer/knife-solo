require 'test_helper'

require 'knife-solo/bootstraps'

class KnifeSolo::Bootstraps::StubOS < KnifeSolo::Bootstraps::Base
end

class KnifeSolo::Bootstraps::StubOS2 < KnifeSolo::Bootstraps::Base
  def gem_packages ; ['chef'] ; end
  def distro ; {:type => 'gem', :version => 'Fanny Faker'} ; end
  def gem_install
    # dont' actually install anything
  end
end

class BootstrapsTest < TestCase
  def test_bootstrap_class_exists_for
    assert_equal true, KnifeSolo::Bootstraps.class_exists_for?('Stub OS')
    assert_equal false, KnifeSolo::Bootstraps.class_exists_for?('Mythical OS')
  end

  def test_distro_raises_if_not_implemented
    assert_raises RuntimeError do
      bootstrap_instance.distro()
    end
  end

  def test_gem_packages_raises_if_not_implemented
    assert_raises RuntimeError do
      bootstrap_instance.gem_packages()
    end
  end

  def test_bootstrap_calls_appropriate_install_method
    bootstrap = bootstrap_instance
    bootstrap.stubs(:distro).returns({:type => 'disco_gem'})
    bootstrap.expects(:disco_gem_install)
    bootstrap.bootstrap!
  end

  def test_bootstrap_calls_pre_bootstrap_checks
    bootstrap = KnifeSolo::Bootstraps::StubOS2.new(mock)
    bootstrap.expects(:run_pre_bootstrap_checks)
    bootstrap.bootstrap!
  end

  def test_bootstrap_delegates_to_knife_prepare
    prepare = mock('chef::knife::prepare')
    bootstrap = KnifeSolo::Bootstraps::StubOS2.new(prepare)

    assert prepare == bootstrap.prepare
  end

  def test_darwin_checks_for_xcode_install_and_barfs_if_missing
    bootstrap = KnifeSolo::Bootstraps::Darwin.new(mock)
    bootstrap.stubs(:gem_install)
    bootstrap.expects(:has_xcode_installed?).returns(false)

    assert_raises RuntimeError do
      bootstrap.bootstrap!
    end
  end

  def test_omnibus_install_methdod
    bootstrap = bootstrap_instance
    bootstrap.stubs(:distro).returns({:type => "omnibus"})
    bootstrap.expects(:omnibus_install)
    bootstrap.bootstrap!
  end

  def test_passes_omnibus_options
    bootstrap = bootstrap_instance
    bootstrap.stubs(:distro).returns({:type => "omnibus"})
    bootstrap.stubs(:http_client_get_url)

    options = "-v 10.16.4"
    matcher = regexp_matches(/\s#{Regexp.quote(options)}(\s|$)/)
    bootstrap.prepare.stubs(:config).returns({:omnibus_options => options})
    bootstrap.prepare.expects(:stream_command).with(matcher).returns(SuccessfulResult.new)

    bootstrap.bootstrap!
  end

  # ***

  def bootstrap_instance
    prepare = mock('Knife::Chef::SoloPrepare')
    KnifeSolo::Bootstraps::StubOS.new(prepare)
  end
end
