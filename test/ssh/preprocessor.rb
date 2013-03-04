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
    conn = mock('connection')
    conn.expects(:run).with('source ~/.profile && echo hi')
    pp = preprocessor(conn, analyzer)
    pp.prefix = "source ~/.profile && "
    pp.run('echo hi')
  end

  def analyzer
    mock('analyzer', :sudo? => true)
  end

  def preprocessor(*args)
    KnifeSolo::SSH::Preprocessor.new(*args)
  end
end
