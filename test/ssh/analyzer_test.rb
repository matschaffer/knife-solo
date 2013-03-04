require 'test_helper'

require 'knife-solo/ssh/analyzer'

class SshAnalyzerTest < TestCase
  def test_finds_windows_node_by_ver
    conn = mock('connection')
    conn.expects(:run).with('ver').returns(success)
    assert analyzer(conn).windows?
  end

  def test_checks_for_sudo
    conn = mock('connection')
    conn.expects(:run).with('sudo -V').returns(success)
    assert analyzer(conn).sudo?
  end

  def success
    mock('ExecResult', :success? => true)
  end

  def analyzer(connection)
    KnifeSolo::SSH::Analyzer.new(connection)
  end
end
