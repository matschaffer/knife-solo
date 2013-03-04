require 'test_helper'

require 'knife-solo/ssh/preprocessor'

class SshPreprocessorTest < TestCase
  def test_runs_without_sudo_if_unavailable
    analyzer = mock('analyzer', :sudo? => false)
    conn = mock('connection')
    conn.expects(:run).with('echo hi')
    preprocessor(conn, analyzer).run('sudo echo hi')
  end

  def test_injects_a_prefix_if_specified
    analyzer = mock('analyzer', :sudo? => false)
    conn = mock('connection')
    conn.expects(:run).with('source ~/.profile && echo hi')
    pp = preprocessor(conn, analyzer)
    pp.prefix = "source ~/.profile && "
    pp.run('echo hi')
  end

  def test_injects_custom_sudo_prompt
    analyzer = mock('analyzer', :sudo? => true)
    conn = mock('connection', :sudo_prompt= => true)
    conn.expects(:run).with("sudo -p 'knife-solo sudo password: ' echo hi")
    pp = preprocessor(conn, analyzer)
    pp.run('sudo echo hi')
  end

  def preprocessor(*args)
    KnifeSolo::SSH::Preprocessor.new(*args)
  end
end
