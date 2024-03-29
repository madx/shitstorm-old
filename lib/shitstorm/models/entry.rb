#coding: utf-8

module ShitStorm
  class Entry < Sequel::Model
    include ModelPlugin::URLizable

    one_to_many :comments
    one_to_many :events

    def url
      "/log/#{id}"
    end

    def before_create
      super
      @values[:body] = Markup.new(body).to_html
    end

    def after_create
      super
      Event.create(:new_entry, self)
    end

    def self.create(params, &block)
      super({:ctime => Time.now}.merge(params), &block)
    end
  end
end
