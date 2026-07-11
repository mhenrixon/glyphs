# frozen_string_literal: true

# Zeitwerk resolves this compact reference through the directory-implied
# namespaces (app/views/docs/pages/ → Views::Docs::Pages), so there's no need
# for the 4-level nested-module ceremony.
class Views::Docs::Pages::ShrinkingIconsInDocker < DocsUI::Page
  title "Shrinking icons in Docker"
  eyebrow "Guide"

  def lead = "Ship only the icons you render — delete the thousands you synced but never use."

  def content
    the_problem
    the_allowlist
    running_it
    docker
    safety
  end

  private

  def the_problem
    DocsUI::Section("The problem", description: "A full sync is thousands of files; you use a handful.") do
      md <<~'MD'
        `rails g rails_icons:sync` copies a library's **entire** icon set into
        `app/assets/svg/icons/<library>/<variant>/`. Lucide alone is ~1,745 SVGs
        (~6.8&nbsp;MB) — all git-tracked and baked into your image, even though a
        typical app renders a few dozen.

        `glyphs:prune_icons` scans your source for the icons you actually
        reference and deletes the rest. Run it in the Docker build so the **image**
        ships only what it renders, while your **repo** keeps the full set for
        development. Icons resolve from disk at request time (not the Propshaft
        pipeline), so pruning is a plain file delete — nothing else to rebuild.
      MD
      md <<~'MD'
        The scanner reads `app/**/*.rb` and `lib/**/*.rb` with a real parser, plus
        `.erb/.haml/.slim` as text, and recognizes every reference form:
      MD
      DocsUI::Code(<<~'RUBY')
        LucideIcon(:house)                      # component call
        HeroIcon(:check, variant: :solid)       # explicit variant
        _lucide(:triangle_alert)                # legacy helper
        Icon(:house, library: :lucide)          # generic component
        span(class: "iconify lucide--menu")     # raw iconify class
      RUBY
    end
  end

  def the_allowlist
    DocsUI::Section("Keeping dynamic icons", description: "Names a static scan can't see.") do
      md <<~'MD'
        Icon names built at runtime — from a database, config, or a gem's chrome —
        are invisible to a static scan. List them in `keep_icons` so the prune
        keeps them. It accepts a flat list or a per-library hash, and each entry
        may be an exact name or an `fnmatch` glob.
      MD
      DocsUI::Code(<<~'RUBY', filename: "config/initializers/glyphs.rb")
        Glyphs.configure do |config|
          config.keep_icons = %w[menu palette search circle-*]
          # or, scoped per library:
          # config.keep_icons = { lucide: %w[menu palette], phosphor: %w[lock] }
        end
      RUBY
      DocsUI::Callout(:tip) do
        md <<~'MD'
          Your configured `fallback_icons` are **always** kept automatically — a
          pruned fallback would 500 the next time any icon is missing.
        MD
      end
    end
  end

  def running_it
    DocsUI::Section("Running it", description: "Dry-run by default; deletion is an explicit opt-in.") do
      md <<~'MD'
        With no flags the task reports what it *would* delete and touches nothing:
      MD
      DocsUI::Code(<<~'BASH')
        bin/rails glyphs:prune_icons
        # [dry-run] Would prune 1735 icons, kept 10, freed 6.75 MB
        #   lucide/outline: 1735 deleted, 10 kept
        #   Re-run with PRUNE=1 GLYPHS_PRUNE_ICONS=1 to delete.
      BASH
      md <<~'MD'
        Deleting requires **both** `PRUNE=1` and `GLYPHS_PRUNE_ICONS=1` — a
        deliberate double opt-in so the task never wipes a developer's synced
        icons by accident:
      MD
      DocsUI::Code(<<~'BASH')
        PRUNE=1 GLYPHS_PRUNE_ICONS=1 bin/rails glyphs:prune_icons
      BASH
    end
  end

  def docker
    DocsUI::Section("In the Docker build", description: "After precompile, before the final copy.") do
      md <<~'MD'
        Run the prune in the build stage, **after** `assets:precompile` and before
        the final stage copies the app. The deletions land in the shipped image;
        your checkout keeps every icon.
      MD
      DocsUI::Code(<<~'DOCKERFILE', filename: "Dockerfile")
        RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile
        RUN SECRET_KEY_BASE_DUMMY=1 PRUNE=1 GLYPHS_PRUNE_ICONS=1 \
            ./bin/rails glyphs:prune_icons
      DOCKERFILE
      DocsUI::Callout(:note) do
        md <<~'MD'
          Don't hook it onto `assets:precompile` with `enhance` — that would fire
          on a local precompile too and delete a developer's icons. A dedicated
          `RUN` keeps it to the image build.
        MD
      end
    end
  end

  def safety
    DocsUI::Section("Safety net", description: "A bad prune fails the build, never a request.") do
      md <<~'MD'
        After deleting, the task **verifies** every kept icon — static references,
        `keep_icons`, and `fallback_icons` — still resolves on disk. If any is
        missing (say, a dynamic name you forgot to allowlist), it exits non-zero
        and **fails the build** instead of shipping an image that renders broken
        glyphs or 500s in production.

        Two libraries are always left alone: the `animated` set bundled inside the
        `icons` gem, and any `custom_path` library outside the icons tree. And the
        prune refuses to empty a library whose keep-set is empty — a mis-scan
        can't silently wipe an entire library.
      MD
    end
  end
end
