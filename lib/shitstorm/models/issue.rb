#coding: utf-8

module ShitStorm
  class Issue < Sequel::Model
    include ModelPlugin::URLizable

    one_to_many :comments
    one_to_many :events

    def title_without_hashtags
      title.gsub(/#(\S+)/, '\1')
    end

    def hashtags
      tags = []
      title.gsub(/(#\S+)/) { |a| tags << a }
      tags
    end

    def before_create
      super
      @values[:body] = Markup.new(body).to_html
    end

    def after_create
      super
      Event.create(:new_issue, self)
    end

    def after_update
      super
      Event.create(:issue_status_change, self) if status != @old_status
    end

    def self.update(params)
      params.each { |k,v| instance_variable_set("@old_#{k}", v) }
      super(params)
    end

    def self.create(params)
      super({:ctime => Time.now, :status => "open"}.merge(params))
    end

    def self.search(query)
      return Issue.order(:id.desc) if query.nil? || query.empty?

      filter(query.split(/ +/).map { |chunk|
        case chunk
          when /^by:(.+)/
            {:author => $~[1]}
          when /^is:(.+)/
            {:status => $~[1]}
          when /^with:(.+)/
            {:id => Comment.select(:issue_id).filter(:author => $~[1])}
          else
            :title.like("%#{chunk}%")
        end
      }.inject {|f,e| e & f }).order(:id.desc)
    end
  end
end
