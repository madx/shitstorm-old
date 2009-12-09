#coding: utf-8

module ShitStorm
  class Event < Sequel::Model
    many_to_one :issues
    many_to_one :entries

    def self.create(mode, obj)
      super({
        :url => obj.url,
        :message => App.dict[:event][mode] % [obj.author, obj.id],
        :ctime => Time.now,
      })
    end
  end
end
