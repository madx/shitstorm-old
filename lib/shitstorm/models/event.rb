#coding: utf-8

module ShitStorm
  class Event < Sequel::Model
    many_to_one :issues
    many_to_one :entries
    many_to_one :comments

    CODES = {
      :new_issue            => 1,
      :new_entry            => 2,
      :new_comment_on_issue => 3,
      :new_comment_on_entry => 4,
      :issue_status_change  => 5
    }

    def self.create(event, *obj)
      references = Hash[ *obj.map {|o|
        ["#{o.class.to_s.split('::').last.downcase}_id", o.id]
      }.flatten ]
      super({
        :url => obj.first.url,
        :code => CODES[event],
        :ctime => Time.now,
      }.merge(references))
    end

    def ev
      CODES.invert[code]
    end

    def title
      App.dict[:event][ev] % case ev
        when :new_issue
          [issue.author, issue.id]
        when :new_entry
          [entry.author, entry.id]
        when :new_comment_on_issue
          [comment.author, issue.id]
        when :new_comment_on_entry
          [comment.author, entry.id]
        when :issue_status_change
          [issue.id, App.dict[issue.status.to_sym].downcase]
      end
    end

    def body
      case ev
      when :new_issue
        issue.body
      when :new_entry
        entry.body
      when :new_comment_on_issue
        comment.body
      when :new_comment_on_entry
        comment.body
      when :issue_status_change
        ""
      end
    end

    def issue
      Issue[issue_id]
    end

    def entry
      Entry[entry_id]
    end

    def comment
      Comment[comment_id]
    end
  end
end
