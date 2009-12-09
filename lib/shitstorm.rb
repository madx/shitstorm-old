#coding: utf-8

require 'yaml'
require 'sinatra'
require 'sequel'

module ShitStorm
  LIB_DIR = File.join(File.dirname(__FILE__), 'shitstorm')

  DB = Sequel.connect "sqlite://shitstorm.db"

  class NotFound < StandardError; end

end

%w(markup models app).each do |lib|
  require File.join(ShitStorm::LIB_DIR, lib)
end
