require 'test_helper'

require 'knife-solo/bootstraps'

class KnifeSolo::Bootstraps::StubOS < KnifeSolo::Bootstraps::Base
end

class KnifeSolo::Bootstraps::StubOS2 < KnifeSolo::Bootstraps::Base
  def distro ; {:type => 'gem', :version => 'Fanny Faker'} ; end
  def gem_install
    # dont' actually install anything
  end
end

class BootstrapsTest < TestCase
  def test_bootstrap_class_exists_for
    assert KnifeSolo::Bootstraps.class_exists_for?('Stub OS')
    refute KnifeSolo::Bootstraps.class_exists_for?('Mythical OS')
  end

  def test_distro_raises_if_not_implemented
    assert_raises RuntimeError do
      bootstrap_instance.distro
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
    assert_equal prepare, bootstrap.prepare
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
    bootstrap.stubs(:chef_version)

    options = "-v 10.16.4"
    matcher = regexp_matches(/\s#{Regexp.quote(options)}(\s|$)/)
    bootstrap.prepare.stubs(:config).returns({:omnibus_options => options})
    bootstrap.prepare.expects(:stream_command).with(matcher).returns(SuccessfulResult.new)

    bootstrap.bootstrap!
  end

  def test_combines_omnibus_options
    bootstrap = bootstrap_instance
    bootstrap.prepare.stubs(:chef_version).returns("0.10.8-3")
    bootstrap.prepare.stubs(:config).returns({:omnibus_options => "-s"})
    assert_equal "-s -v 0.10.8-3", bootstrap.omnibus_options
  end

  def test_passes_prerelease_omnibus_version
    bootstrap = bootstrap_instance
    bootstrap.prepare.stubs(:chef_version).returns("10.18.3")
    bootstrap.prepare.stubs(:config).returns({:prerelease => true})
    assert_equal "-p", bootstrap.omnibus_options.strip
  end

  def test_passes_gem_version
    bootstrap = bootstrap_instance
    bootstrap.prepare.stubs(:chef_version).returns("10.16.4")
    assert_equal "--version 10.16.4", bootstrap.gem_options
  end

  def test_passes_prereleaes_gem_version
    bootstrap = bootstrap_instance
    bootstrap.prepare.stubs(:chef_version).returns("10.18.1")
    bootstrap.prepare.stubs(:config).returns({:prerelease => true})
    assert_equal "--prerelease", bootstrap.gem_options
  end

  def test_wont_pass_unset_gem_version
    bootstrap = bootstrap_instance
    bootstrap.prepare.stubs(:chef_version).returns(nil)
    assert_equal "", bootstrap.gem_options.to_s
  end

  # ***

  def bootstrap_instance
    prepare = mock('Knife::Chef::SoloPrepare')
    prepare.stubs(:config).returns({})
    KnifeSolo::Bootstraps::StubOS.new(prepare)
  end
end
