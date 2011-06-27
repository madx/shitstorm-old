require File.join(File.dirname(__FILE__), 'lib', 'shitstorm')

::Shitstorm::App.set :session_secret, "dev"

run ::Shitstorm::App
