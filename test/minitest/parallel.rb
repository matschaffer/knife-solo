# https://github.com/ngauthier/minitest-parallel
if defined?(MiniTest)
  raise "Do not require minitest before minitest/parallel\n"
end
require 'parallel'
require 'minitest/unit'

module MiniTest::Parallel
  def self.included(base)
    base.class_eval do
      alias_method :_run_suites_in_series, :_run_suites
      alias_method :_run_suites, :_run_suites_in_parallel
    end
  end

  def self.processor_count=(procs)
    @processor_count = procs
  end

  def self.processor_count
    @processor_count ||= Parallel.processor_count
  end

  def _run_suites_in_parallel(suites, type)
    result = Parallel.map(suites, :in_processes => MiniTest::Parallel.processor_count) do |suite|
      ret = _run_suite(suite, type)
      {
        :failures         => failures,
        :errors           => errors,
        :report           => report,
        :run_suite_return => ret
      }
    end
    self.failures = result.inject(0)  {|sum, x| sum + x[:failures] }
    self.errors   = result.inject(0)  {|sum, x| sum + x[:errors] }
    self.report   = result.inject([]) {|sum, x| sum + x[:report] }
    result.map {|x| x[:run_suite_return] }
  end
end

MiniTest::Unit.send(:include, MiniTest::Parallel)
