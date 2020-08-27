# encoding: UTF-8

require './lib/required/_first/constants/String_constants.rb'
Dir["#{File.dirname(__FILE__)}/required/**/*.rb"].each{|m|require(m)}
