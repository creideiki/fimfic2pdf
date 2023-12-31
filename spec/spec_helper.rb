# frozen_string_literal: true

require 'fileutils'
require 'rspec_structure_matcher'

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
SAMPLE_PATH = File.expand_path('data', __dir__)
TEST_ID = '12345'
