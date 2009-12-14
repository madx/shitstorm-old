#coding: utf-8

module ShitStorm
  module ModelPlugin
    module URLizable
      def url
        "/#{id}"
      end
    end
  end
end

%w(issue entry comment event).each do |model|
  require File.join(ShitStorm::LIB_DIR, 'models', model)
end
