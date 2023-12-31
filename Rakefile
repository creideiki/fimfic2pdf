# frozen_string_literal: true

require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  warn e.message
  warn 'Run "bundle install" to install missing gems'
  exit e.status_code
end

desc 'Run RSpec tests'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

desc 'Run Rubocop'
require 'rubocop/rake_task'
RuboCop::RakeTask.new(:rubocop)

task :default => [:rubocop, :spec]
