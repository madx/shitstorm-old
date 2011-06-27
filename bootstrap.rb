require File.join(File.dirname(__FILE__), 'lib', 'shitstorm')

include Shitstorm

User.create(:name => 'admin')
puts "Created user admin with key: #{User.first.token}"
