# frozen_string_literal: true

module Glyphs
  # Loaded only when Rails is present (see the guard in lib/glyphs.rb). Its sole
  # job is to expose the icon-pruning rake task to consuming apps. Kept a
  # Railtie, not an Engine: glyphs contributes no routes, views, or migrations.
  class Railtie < ::Rails::Railtie
    rake_tasks do
      load File.expand_path("../tasks/glyphs.rake", __dir__)
    end
  end
end
