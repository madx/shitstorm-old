#coding: utf-8
require 'yaml'
require 'sinatra'
require 'sequel'
require File.join(File.dirname(__FILE__), 'markup')

module ShitStorm
  DB = Sequel.connect "sqlite://shitstorm.db"

  class NotFound < StandardError; end

  # == App ==

  class App < Sinatra::Base

    configure do
      set :haml,  :attr_wrapper => "'"
      set :lang,  "en"
      set :name,  "ShitStorm"
      set :url,   "http://example.com/"
      set :email, "admin@example.com"
      set :dict,  Proc.new { YAML.load(File.read("lang/#{lang}.yml")) }
      set :methodoverride, true
      set :raise_errors, false
    end

    helpers do
      def dict
        ShitStorm::App.dict
      end

      def settings
        ShitStorm::App
      end

      def author_search_link(issue)
        dict[:by] + " " + dict[:by_link] % [
          Rack::Utils.escape(issue.author),
          issue.author,
          issue.author
        ]
      end

      def author_field
        '<input type="text" name="author" value="%s" />' %
          request.cookies["author"]
      end

      def set_author_cookie!
        unless params[:author].empty?
          response.set_cookie("author", params[:author])
        end
        params[:author] = dict[:anonymous] if params[:author].empty?
      end

      def option_tag(status, issue_status)
        '<option%s value="%s">%s</option>' % [
          status.to_s == issue_status ? ' selected="selected"' : '',
          status, dict[status]
        ]
      end
    end

    get '/data/:file' do
      halt 403 if params[:file].index ".."

      send_file(File.join('data', params[:file]))
    end

    get '/feed' do
      content_type 'application/atom+xml'

      @events = Event.order(:id.desc).limit(20)

      erb :feed, :layout => false
    end

    get '/' do
      @issues = Issue.search(params[:q])

      erb :index
    end

    get '/log/:id' do
      @entry = Entry[params[:id]]
      raise NotFound unless @entry

      erb :entry
    end

    get '/log' do
      @entries = Entry.order(:id.desc)

      erb :log
    end

    get '/add' do
      erb :add
    end

    get '/:id' do
      @issue = Issue[params[:id]]
      raise NotFound unless @issue

      erb :issue
    end

    post '/' do
      halt 500 if params[:title].empty?
      set_author_cookie!

      Issue.create(params.merge({:ctime => Time.now, :status => "open"}))

      redirect '/'
    end

    post '/log' do
      halt 500 if params[:title].empty?
      set_author_cookie!

      Entry.create(params.merge({:ctime => Time.now}))

      redirect '/log'
    end

    post '/:id/comment' do
      halt 500 if params[:body].empty?
      set_author_cookie!

      raise NotFound unless issue = Issue[params[:id]]

      data = params.reject { |k,v|
        !%w(author body).member?(k)
      }.update({:issue_id => params[:id], :ctime => Time.now})

      Comment.create(data)

      redirect issue.url
    end

    post '/log/:id/comment' do
      halt 500 if params[:body].empty?
      set_author_cookie!

      raise NotFound unless entry = Entry[params[:id]]

      data = params.reject { |k,v|
        !%w(author body).member?(k)
      }.update({:entry_id => params[:id], :ctime => Time.now})

      Comment.create(data)

      redirect entry.url
    end

    error NotFound do
      erb :not_found
    end

  end

  # == Models ==

  class Issue < Sequel::Model
    one_to_many :comments

    def url
      "/#{id}"
    end

    def before_create
      super
      @values[:body] = Markup.new(body).to_html
    end

    def after_create
      super
      Event.issue(self)
    end

    def self.search(query)
      return Issue.order(:id.desc) unless query

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

  class Entry < Sequel::Model
    one_to_many :comments

    def url
      "/log/#{id}"
    end

    def before_create
      super
      @values[:body] = Markup.new(body).to_html
    end

    def after_create
      super
      Event.entry(id)
    end
  end


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
        Event.comment_issue(issue_id)
      elsif entry_id
        Event.comment_entry(entry_id)
      end
    end

    def issue
      Issue[:id => issue_id]
    end

    def entry
      Entry[:id => entry_id]
    end
  end

  class Event < Sequel::Model
    def self.issue(issue)
      create :url => issue.url,
             :message => "new_issue",
             :ctime => Time.now
    end

    def self.entry(id)
      create :url => "/log/#{id}",
             :message => "new_entry",
             :ctime => Time.now
    end

    def self.comment_issue(id)
      create :url => "/#{id}",
             :message => "comment_on_issue",
             :ctime => Time.now
    end

    def self.comment_entry(id)
      create :url => "/log/#{id}",
             :message => "comment_on_entry",
             :ctime => Time.now
    end
  end

end
