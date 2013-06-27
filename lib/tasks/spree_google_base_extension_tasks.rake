require 'net/ftp'

namespace :spree_google_base do
  task :generate_and_transfer => [:environment] do |t, args|
    SpreeGoogleBase::FeedBuilder.generate_and_transfer
  end

  task :generate => [:environment] do |t, args|
    SpreeGoogleBase::FeedBuilder.generate
  end

  task :transfer => [:environment] do |t, args|
    SpreeGoogleBase::FeedBuilder.transfer
  end

end
