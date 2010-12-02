I18n.backend.store_translations 'en', {}

I18n.load_path << Dir[ File.join(RAILS_ROOT, 'config', 'locales', '**', '*.{rb,yml}') ]

# You need to "force-initialize" loaded locales
I18n.backend.send(:init_translations)

AVAILABLE_LOCALES = ["en"] #I18n.backend.available_locales.map { |l| l.to_s }
AVAILABLE_LANGUAGES = I18n.backend.available_locales.map { |l| l.to_s.split("-").first}.uniq

## this is only for the user settings, not related to translatewiki.net
DEFAULT_USER_LANGUAGES = ['en']

RAILS_DEFAULT_LOGGER.debug "* Loaded locales: #{AVAILABLE_LOCALES.inspect}"

require "i18n/backend/fallbacks"
I18n::Backend::Simple.send(:include, I18n::Backend::Fallbacks)
I18n.default_locale = :"en"
