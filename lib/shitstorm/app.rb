#coding: utf-8

module ShitStorm
  class App < Sinatra::Base

    configure do
      set :haml,  :attr_wrapper => '"'
      set :lang,  "en"
      set :name,  "ShitStorm"
      set :url,   "http://example.com/"
      set :email, "admin@example.com"
      set :dict,  Proc.new {
        YAML.load File.read(File.join(LIB_DIR, "lang", "#{lang}.yml"))
      }
      set :methodoverride, true
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

      def flag_link(issue)
        ('<a href="/?q=is:%s" title="%s">'+
        '<img src="/data/flag_%s.png" alt="%s" />'+
        '</a>') % [
          @issue.status, dict[:see_status][@issue.status.to_sym],
          @issue.status, @issue.status
        ]
      end

      def set_author_cookie!
        unless params[:author].empty?
          response.set_cookie("author", params[:author])
        end
        params[:author] = dict[:anonymous] if params[:author].empty?
      end

      def halt_unless_param(p)
        halt 500 if params[p].empty?
      end

      def find(klass)
        klass[params[:id]] or raise NotFound
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

      haml :feed, :layout => false
    end

    get '/' do
      @issues = Issue.search(params[:q])

      haml :index
    end

    get '/favicon.ico' do
      send_file('data/bug.png')
    end

    get '/log/:id' do
      @entry = find(Entry)

      haml :entry
    end

    get '/log' do
      @entries = Entry.order(:id.desc)

      haml :log
    end

    get '/add' do
      haml :add
    end

    get '/:id' do
      @issue = find(Issue)

      haml :issue
    end

    post '/' do
      halt_unless_param :title
      set_author_cookie!

      Issue.create(params)

      redirect '/'
    end

    post '/log' do
      halt_unless_param :title
      set_author_cookie!

      Entry.create(params)

      redirect '/log'
    end

    post '/:id/comment' do
      halt_unless_param :body
      set_author_cookie!

      issue = find(Issue)

      data = params.reject { |k,v|
        !%w(author body).member?(k)
      }.update(:issue_id => params[:id])

      Comment.create(data)

      redirect issue.url
    end

    post '/log/:id/comment' do
      halt_unless_param :body
      set_author_cookie!

      entry = find(Entry)

      data = params.reject { |k,v|
        !%w(author body).member?(k)
      }.update(:entry_id => params[:id])

      Comment.create(data)

      redirect entry.url
    end

    put '/:id' do
      halt_unless_param :status

      issue = find(Issue)

      issue.update :status => params[:status]

      redirect issue.url
    end

    error NotFound do
      haml :not_found
    end

  end
end
