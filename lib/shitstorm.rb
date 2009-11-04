require 'yaml'
require 'sinatra'
require 'sequel'

module ShitStorm
  DB = Sequel.connect "sqlite://shitstorm.db"

  class NotFound < StandardError; end

  class App < Sinatra::Base

    configure do
      set :haml, :attr_wrapper => "'"
      set :lang, "en"
      set :dict, Proc.new { YAML.load(File.read("lang/#{lang}.yml")) }
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
        '<input type="text" name="author" value="%s" />' % request.cookies["author"]
      end

      def option_tag(status, issue_status)
        '<option%s value="%s">%s</option>' % [
          status.to_s == issue_status ? ' selected="selected"' : '',
          status, dict[status]
        ]
      end

      def to_filter(query)
        query.split(/ +/).map { |chunk|
          case chunk
            when /^by:(.+)/
              {:author => $~[1]}
            when /^is:(.+)/
              {:status => $~[1]}
            else
              :title.like("%#{chunk}%")
          end
        }.inject(:ctime) {|f,e| e & f }
      end
    end

    get '/' do
      @issues = (params[:q] ?
        Issue.filter(to_filter(params[:q])) : Issue
      ).order(:ctime.desc)

      p @issues.sql

      erb :index
    end

    post '/' do
      halt 500 if params[:title].empty?
      params.merge!({:ctime => Time.now, :status => "open"})

      unless params[:author].empty?
        response.set_cookie("author", params[:author]) 
      end
      params[:author] = dict[:anonymous] if params[:author].empty?

      Issue.create(params)

      redirect '/'
    end

    get '/data/:file' do
      halt 403 if params[:file].index ".."

      content_type File.extname(params[:file])
      File.read(File.join('data', params[:file]))
    end

    get '/:id' do
      @issue = Issue[params[:id]]
      raise NotFound unless @issue

      erb :show
    end

    put '/:id' do
      halt 500 if params[:body].empty?

      unless params[:author].empty?
        response.set_cookie("author", params[:author]) 
      end
      params[:author] = dict[:anonymous] if params[:author].empty?

      issue = Issue[params[:id]]
      raise NotFound unless issue

      comment_params = params.reject { |k,v|
        !%w(author body).member?(k)
      }.update({:issue_id => params[:id], :ctime => Time.now})

      comment = Comment.create(comment_params)
      if issue.status != params[:status]
        issue.status = params[:status]
        issue.save
      end

      redirect issue.url
    end

  end

  class Issue < Sequel::Model
    one_to_many :comments

    def url
      "/#{id}"
    end
  end

  class Comment < Sequel::Model
    many_to_one :issues

    def issue
      Issue[:id => issue_id]
    end
  end
end
