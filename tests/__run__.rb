#!/usr/bin/env ruby -wUW1
# encoding: UTF-8
=begin
  Runner de test
=end

TEST = 'essai_test' # chemin relatif dans './tests/___'

require_relative 'lib/required'

test_path = File.join(TEST_FOLDER_TESTS,"#{TEST}.rb")

# On joue le test
load test_path
