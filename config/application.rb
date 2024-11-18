require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module CookingRecordAlbum
  class Application < Rails::Application
    config.load_defaults 7.2
    config.autoload_lib(ignore: %w[assets tasks])
    config.i18n.default_locale = :ja
    config.generators.system_tests = nil
  end
end
