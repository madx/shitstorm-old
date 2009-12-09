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
        Event.create(:issue_comment, Issue[issue_id])
      elsif entry_id
        Event.create(:entry_comment, Entry[entry_id])
      end
    end

    def issue
      Issue[:id => issue_id]
    end

    def entry
      Entry[:id => entry_id]
    end
  end
end
