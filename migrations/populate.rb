require 'sequel'
require 'time'
require 'lib/shitstorm'

(0..30).each do |i|
  ShitStorm::Issue.
      create :title        => "Issue ##{i}",
             :author       => ENV['USER'],
             :description  => "This is the issue n°#{i}",
             :ctime        => Time.now - 3600 + i * 10,
             :status       => :open
end
