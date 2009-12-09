#coding: utf-8

%w(issue entry comment event).each do |model|
  require File.join(ShitStorm::LIB_DIR, 'models', model)
end
