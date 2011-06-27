require File.join(File.dirname(__FILE__), 'lib', 'shitstorm')

include Shitstorm

User.create(:name => 'admin')
puts "Created user admin with key: #{User.first.token}"

Ticket.create({
  author: User.first,
  title: "Welcome to Shitstorm",
  body: File.read('README.md')
})
