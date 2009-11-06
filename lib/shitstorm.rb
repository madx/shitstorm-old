require 'yaml'
require 'sinatra'
require 'sequel'

require File.join(File.dirname(__FILE__), 'markup')

module ShitStorm
  DB = Sequel.connect "sqlite://shitstorm.db"

  class NotFound < StandardError; end

  class App < Sinatra::Base

    configure do
      set :haml,  :attr_wrapper => "'"
      set :lang,  "en"
      set :name,  "ShitStorm"
      set :url,   "http://example.com/"
      set :email, "admin@example.com"
      set :dict,  Proc.new { YAML.load(File.read("lang/#{lang}.yml")) }
      set :methodoverride, true
    end

    helpers do
      def dict
        ShitStorm::App.dict
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

      @entries = Entry.order(:id.desc).limit(20)

      builder :feed
    end

    get '/log' do
      @entries = Entry.order(:id.desc)

      erb :log
    end

    get '/add' do
      erb :add
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

      Entry.create(params.merge({:ctime => Time.now}))

      redirect '/log'
    end

    put '/:id' do
      halt 500 if params[:body].empty?
      set_author_cookie!

      raise NotFound unless issue = Issue[params[:id]]

      data = params.reject { |k,v|
        !%w(author body).member?(k)
      }.update({:issue_id => params[:id], :ctime => Time.now})

      Comment.create(data)

      if params[:status] != issue.status
        issue.update(:status => params[:status])
      end

      redirect issue.url
    end

  end

  class Issue < Sequel::Model
    one_to_many :comments

    def url
      "/#{id}"
    end

    def before_create
      super
      @values[:description] = Markup.new(description).to_html
    end

    def after_update
      super

      entry = Entry.order(:id).last
      body  = entry.body
      entry.destroy

      Entry.create do |entry|
        entry.title = App.dict[:log_status] % [
          author, id,
          App.dict[status.to_sym]
        ]
        entry.ctime = Time.now
        entry.url   = url
        entry.body  = body
      end
    end

    def after_create
      super
      Entry.create do |entry|
        entry.title = App.dict[:log_issue] % [author, id]
        entry.ctime = Time.now
        entry.url   = url
        entry.body  = description
      end
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

  class Comment < Sequel::Model
    many_to_one :issues

    def before_create
      super
      @values[:body] = Markup.new(body).to_html
    end

    def after_create
      super
      Entry.create do |entry|
        entry.title = App.dict[:log_comment] % [author, issue_id]
        entry.ctime = Time.now
        entry.url   = issue.url
        entry.body = body
      end
    end

    def issue
      Issue[:id => issue_id]
    end
  end

  class Entry < Sequel::Model
  end
end
