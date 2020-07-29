# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'cucumber/rake/task'

RSpec::Core::RakeTask.new(:specs) do |t|
  t.rspec_opts = '--force-color'
end

Cucumber::Rake::Task.new(:features) do |t|
  t.cucumber_opts = %w[--color]
end

task default: %i[specs features]
CLEAN.include('tmp')
