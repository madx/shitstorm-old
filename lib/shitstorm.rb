require 'yaml'
require 'sequel'
require 'calico'
require 'sinatra/base'
require 'erubis'
require 'builder'
require 'sass'
require 'time'
require 'digest/sha1'
require 'calico'

module Shitstorm
  DB = Sequel.connect(YAML.load_file('db/database.yml'))

  def self.markup(text)
    Calico.new(text).
      to_html.
      gsub(/[^\\]#([1-9]\d+)/) { '<a href="%s">%s</a>' % ["/#{$1}", $&] }
  end

  class User < Sequel::Model
    plugin :validation_helpers

    one_to_many :tickets,  :key => :author_id
    one_to_many :comments, :key => :author_id
    one_to_many :updates,  :key => :author_id

    def validate
      super
      validates_presence :name
    end

    def before_create
      regenerate_token
      self.active ||= true
      super
    end

    def regenerate_token
      self.token = Digest::SHA1.hexdigest(name + Time.now.to_i.to_s)
    end
  end

  class Ticket < Sequel::Model
    plugin :validation_helpers

    one_to_many :comments
    one_to_many :updates
    many_to_one :author, :class => User

    def validate
      super
      validates_presence [:title, :body]
    end

    def feed
      (updates + comments).sort_by(&:created_at)
    end

    def before_create
      self.created_at ||= Time.now
      self.active     ||= true
      super
    end

    def before_save
      self.body_markup = Shitstorm.markup(body)
      super
    end

    def css_class
      active ? 'active' : 'resolved'
    end
  end

  class Comment < Sequel::Model
    many_to_one :ticket
    many_to_one :author, :class => User

    def before_create
      self.created_at ||= Time.now
      super
    end

    def before_save
      self.body_markup = Shitstorm.markup(body)
      super
    end
  end

  class Update < Sequel::Model
    many_to_one :ticket
    many_to_one :author, :class => User

    def before_create
      self.created_at ||= Time.now
      super
    end

    def css_class
      active ? 'active' : 'resolved'
    end
  end

  class App < Sinatra::Base
    Tilt.register :erb, Tilt[:erubis]

    enable :sessions

    helpers do
      def authenticated?
        not session[:user].nil?
      end

      def admin?
        authenticated? and session[:user].id == 1
      end

      def protect!
        redirect to('/') unless authenticated?
      end

      def admin!
        redirect to('/') unless admin?
      end

      def username
        session[:user].name
      end

      def partial(template, options={}, locals={})
        options.merge!(:layout => false)
        erb "_#{template}".to_sym, options, locals
      end

      def cycle(rowid)
        ((rowid % 2) == 0) ? 'even' : 'odd'
      end

      def markup(text)
        Markup.render(text)
      end
    end

    get '/' do
      @tickets = Ticket.reverse(:id)
      erb :search
    end

    get '/stylesheet.css' do
      scss :stylesheet
    end

    get '/new' do
      protect!

      erb :new
    end

    post '/new' do
      protect!

      @ticket = Ticket.new({
        title: params[:title],
        body: params[:body],
        author: session[:user]
      })

      if @ticket.valid?
        @ticket.save
        redirect to('/')
      else
        erb :new
      end
    end

    get '/login' do
      erb :login
    end

    get '/logout' do
      session[:user] = nil
      redirect to('/')
    end

    post '/login' do
      user = User.first(:token => params[:token])

      if user && user.active
        session[:user] = user
        redirect to('/')
      else
        @error = true
        erb :login
      end
    end

    get '/manage' do
      admin!

      erb :manage
    end

    post '/manage/add' do
      admin!

      user = User.new(name: params[:name])

      begin
        user.save
        redirect to('/manage')
      rescue Sequel::DatabaseError, Sequel::ValidationFailed
        @error = true
        erb :manage
      end
    end

    get '/manage/toggle/:id' do
      admin!

      user = User[params[:id]]
      user.active = !user.active
      user.save

      redirect to('/manage')
    end

    get '/manage/regen/:id' do
      admin!

      user = User[params[:id]]
      user.regenerate_token
      user.save

      redirect to('/manage')
    end

    get '/feed' do
      tickets  = Ticket.order(:created_at.desc).limit(20).all
      comments = Comment.order(:created_at.desc).limit(20).all
      updates  = Update.order(:created_at.desc).limit(20).all
      @items = (tickets + comments + updates).sort_by {|x| x.created_at }.
                reverse.
                take(20)
      @url = "#{request.env['rack.url_scheme']}://#{request.env['HTTP_HOST']}"
      erb :feed, :layout => false
    end

    get '/:id' do
      @ticket = Ticket[params[:id]]
      erb :ticket
    end

    post '/:id/comment' do
      protect!

      ticket = Ticket[params[:id]]

      Comment.create({
        ticket: ticket,
        author: session[:user],
        body: params[:body]
      })

      redirect to("/#{ticket.id}")
    end


    get '/:id/toggle' do
      protect!

      ticket = Ticket[params[:id]]
      ticket.active = !ticket.active
      ticket.save

      Update.create({
        ticket: ticket,
        active: ticket.active,
        author: session[:user]
      })

      redirect to("/#{ticket.id}")
    end
  end
end
