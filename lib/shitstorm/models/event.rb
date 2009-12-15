#coding: utf-8

module ShitStorm
  class Event < Sequel::Model
    many_to_one :issues
    many_to_one :entries

    CODES = {
      :new_issue            => 1,
      :new_entry            => 2,
      :new_comment_on_issue => 3,
      :new_comment_on_entry => 4,
      :issue_status_change  => 5
    }

    def self.create(event, obj)
      super({
        :url => obj.url,
        :code => CODES[event],
        :ctime => Time.now,
      })
    end
  end
end
