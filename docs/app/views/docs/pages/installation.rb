# frozen_string_literal: true

class Views::Docs::Pages::Installation < DocsUI::Page
  title "Installation"
  eyebrow "Getting started"

  def lead = "Add the gem, sync your icon libraries, include the kit."

  def content
    add_the_gem
    sync_icons
    include_the_kit
    outside_rails
  end

  private

  def add_the_gem
    DocsUI::Section("Add the gem", description: "glyphs renders the SVGs that rails_icons syncs into your app.") do
      DocsUI::Code(<<~RUBY, filename: "Gemfile")
        gem "glyphs"
      RUBY
      md <<~'MD'
        glyphs depends on [phlex](https://www.phlex.fun) (~> 2.0) and
        [rails_icons](https://github.com/rails-designer/rails_icons) (>= 1.2) —
        rails_icons brings the sync generator and the `icons` gem, the pure-Ruby
        SVG renderer glyphs uses under the hood.
      MD
    end
  end

  def sync_icons
    DocsUI::Section("Sync icon libraries", description: "Skip this if rails_icons is already set up.") do
      DocsUI::Code(<<~SHELL, lexer: :shell)
        rails generate rails_icons:install --libraries=lucide heroicons
        rails generate rails_icons:sync --libraries=lucide heroicons
      SHELL
      md <<~'MD'
        The synced SVGs land in `app/assets/svg/icons/<library>/<variant>/` —
        that's where glyphs reads them at render time and where the
        `Glyphs/IconResolution` cop validates icon names at lint time.
      MD
    end
  end

  def include_the_kit
    DocsUI::Section("Include the kit") do
      md <<~'MD'
        `Glyphs` is a Phlex::Kit — include it once in your component base class
        and every library component becomes a capitalized method:
      MD
      DocsUI::Code(<<~RUBY, filename: "app/components/application_component.rb")
        class ApplicationComponent < Phlex::HTML
          include Glyphs
        end
      RUBY
      DocsUI::Code(<<~RUBY)
        LucideIcon(:house, class: "size-4")
        PhosphorIcon("lock", variant: :bold)
        HeroIcon(:check, class: "size-5 text-success")
      RUBY
    end
  end

  def outside_rails
    DocsUI::Section("Outside Rails") do
      md <<~'MD'
        glyphs has no Rails dependency at runtime. Point the `icons` gem at your
        SVG tree and render away:
      MD
      DocsUI::Code(<<~RUBY)
        Icons.configure do |config|
          config.base_path = File.expand_path(__dir__)
          config.icons_path = "svg/icons"
        end

        Glyphs::LucideIcon.new(:house).call # => "<svg ...>"
      RUBY
    end
  end
end
