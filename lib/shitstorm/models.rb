#coding: utf-8

%w(issue entry comment event).each do |model|
  require File.join(File.dirname(__FILE__), 'models', model)
end
