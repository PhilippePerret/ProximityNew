# encoding: UTF-8
# require 'sqlite'
# APP_DB = SQLite::Database.new('config/proximity_new.db')

LIB_FOLDER = File.dirname(__FILE__)
APP_FOLDER = File.dirname(LIB_FOLDER)

Dir["#{LIB_FOLDER}/required/_first/**/*.rb"].each{|m|require(m)}
Dir["#{LIB_FOLDER}/required/_then/**/*.rb"].each{|m|require(m)}
