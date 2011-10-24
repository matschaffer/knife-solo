namespace :test do
  desc "Run integration tests (requires EC2)"
  task :integration do
    require 'bundler'
    Bundler.require(:test)
  end
end