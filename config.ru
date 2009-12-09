require 'lib/shitstorm'

if ShitStorm::App.environment == :production
  ShitStorm::App.set :raise_errors, false
end

run ShitStorm::App
