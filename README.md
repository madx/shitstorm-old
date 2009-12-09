ShitStorm
=========

ShitStorm is a minimalist bug/issue/request/whatever tracker written in Ruby.
ShitStorm has been designed to manage issues and user requests on a dedicated
server, but it may be have other usages.

Instead of being bloated with tons of features, ShitStorms stays simples by
enforcing a few conventions:

* Issues can have 4 states: open, closed, pending and rejected, no less, no
  more.
* No user management, but your name is remembered in a cookie so you don't
  have to type it again and again. If you need password protection, use
  Rack::Auth.
* Since there's no user management, tasks can't be assigned to anyone, but,
  hey, there's a comment form so you can tell someone to take care of it.
* No categories, tags, milestones, WTF, etc. But a search field that has a few
  smart features.
* A pseudo blog where everyone can write and comment entries. Works pretty much
  like issues, except there is no state.
* An aggregator for the issues and the blog entries available as an ATOM feed.
* Simple i18n with a YAML file (see lib/shitstorm/lang/). English and french
  dictionaries are provided.

## Requirements ##############################################################

* sinatra (tested with 0.9.4)
* sequel (tested with 3.6.0)
* yaml (comes with ruby)
* ruby 1.8 or 1.9

## Install ###################################################################

    $ git clone git://github.com/madx/shitstorm.git
    $ cd shitstorm && sequel -m migrations/ sqlite://shitstorm.db

Copy the files where you want to install it, then edit `config.ru` if you
want to change the defaults. Use plain ruby to do the configuration, like
this:

    require 'lib/shitstorm'

    run(ShitStorm::App.tap {|config|
      config.set :name, "My Issue Tracker" # defaults to ShitStorm
      config.set :lang, "en"               # defaults to en
      # NEXT ONE IS ACTUALLY IMPORTANT
      config.set :url,  "http//tracker.mydomain.com/"
      config.set :email, "admin@mydomain.com" # this one isn't
    })

Then run the app with $ rackup -E production config.ru

## Source ####################################################################

ShitStorm's Git repo is available on GitHub, which can be browsed at
<http://github.com/madx/shitstorm> and cloned with:

    git clone git://github.com/madx/shitstorm.git

## Usage #####################################################################

ShitStorm's UI is quite simple. The default page is where issues are listed.
You can search in them using the field at the top.

There are special filters in the queries:

* `by:<name>`: filter issues reported by `<name>`
* `is:<status>`: filter issues with a status of `<status>` (can be `open`,
   `closed`, `pending` or `rejected`)
* `with:<name>`: filter issues where `<name>` has written a comment
* `#<tag>`: filter issues with a hashtag. Actually this is just a text search,
  but hashtags are handled by ShitStorm (try it!)

Click on an issue title to view details and comments. Posting comments is
dead-simple, so is changing an issue's state (right of the issue's title)

The log works pretty much the same way, except it's not (yet) searchable.
It's accessible by clicking "Log" at the top right

## Formatting ################################################################

When writing issue descriptions or comments, you have access to a basic
formatting facility that's based on Christian Neukirchen's Challis, but
simplified.

Help about Challis is available at <http://github.com/chneukirchen/challis>

The following features are disabled:

* Headers
* Raw HTML insertion
* Images
* Class and ID for tags

These things change:

* Emphasizing (`<em>`) is done by surrounding with `_`'s
* Strong (`<strong>`) is done by surrounding with `*`'s
* You can link to an issue using the notation `#<issue_number>`

You can easily override the formatter by redefining `ShitStorm::Markup#to_html`

## Contributors ##############################################################

* [webs][1]: Hashtags support, UI improvements (faster searches)

[1]: http://github.com/webs
