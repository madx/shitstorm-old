Shitstorm
=========

Shitstorm is a _simple_, _fast_ and _opinionated_ ticket tracking system.

It tries not to include all the **bloat** that I usually found in most BTS
software.

Shitstorm has been designed to manage user requests and bug reports on a
dedicated server, but it could easily be used for a lot of other things.

## Features

* Simple states: active or resolved
* Comments
* An Atom feed to be notified of changes
* Password-less login, using "keys"
* Simple but efficient search engine
* Easy user management (create/delete, one admin)
* Simple text formatting

## Requirements and Install

Shitstorm is built using the [Sinatra](http://sinatrarb.com/) framework. It also
uses a few other libs:

* [Sequel](http://sequel.rubyforge.org/) and sqlite3 for database management
* [Calico](http://github.com/madx/calico) for text formatting
* Erubis and Sass for markup
* YAML, Digest::SHA1, Time, from the Ruby standard library

Once you've installed these, create the database by running `sequel -m db/
db/database.yml`. You can then run the `bootstrap.rb` script to create the
`admin` user, then launch the `config.ru` using your favorite mean (rackup,
mod_rack, ...)
