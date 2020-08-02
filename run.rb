#!/usr/bin/env ruby
# encoding: UTF-8

begin
  require_relative './lib/required'
  Runner.run
rescue Exception => e
  puts "ERROR: #{e.message}\n#{e.backtrace.join("\n")}"
end
