#coding: utf-8

module ShitStorm
  class Comment < Sequel::Model
    many_to_one :issues
    many_to_one :entries

    def before_create
      super
      @values[:body] = Markup.new(body).to_html
    end

    def after_create
      super
      if issue_id
        Event.create(:new_comment_on_issue, issue, self)
      elsif entry_id
        Event.create(:new_comment_on_entry, entry, self)
      end
    end

    def issue
      Issue[issue_id]
    end

    def entry
      Entry[entry_id]
    end

    def self.create(params)
      super({:ctime => Time.now}.merge(params))
    end
  end
end
