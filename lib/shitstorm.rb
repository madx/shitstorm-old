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

      @entries = []

      builder :feed
    end

    get '/' do
      @issues = Issue.search(params[:q])

      erb :index
    end

    get '/:id' do
      @issue = Issue[params[:id]]
      raise NotFound unless @issue

      erb :show
    end

    post '/' do
      halt 500 if params[:title].empty?
      set_author_cookie!

      Issue.create(params.merge({:ctime => Time.now, :status => "open"}))

      redirect '/'
    end

    put '/:id' do
      halt 500 if params[:body].empty?
      set_author_cookie!

      raise NotFound unless issue = Issue[params[:id]]

      comment = Comment.create(params.reject { |k,v|
        !%w(author body).member?(k)
      }.update({:issue_id => params[:id], :ctime => Time.now}))

      issue.update(:status => params[:status])

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

    def self.search(query)
      return Issue.order(:ctime.desc) unless query

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
      }.inject {|f,e| e & f }).order(:ctime.desc)
    end
  end

  class Comment < Sequel::Model
    many_to_one :issues

    def before_create
      super
      @values[:body] = Markup.new(body).to_html
    end

    def issue
      Issue[:id => issue_id]
    end
  end
end
