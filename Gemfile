source "https://rubygems.org"

gem "rails", "~> 8.0.1"
ruby "3.3.5"
gem "sprockets-rails"
gem "sqlite3", ">= 1.4"
gem "puma", ">= 5.0"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "tzinfo-data", platforms: %i[ windows jruby ]
gem "bootsnap", require: false
gem "faraday"
gem "kaminari"
gem "bootstrap", "~> 5.3.3"
gem "jquery-rails"
gem "sassc-rails"
gem "bootstrap5-kaminari-views"

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
end

group :development do
  gem "web-console"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
  gem "rspec-rails"
  gem "webmock"
end
