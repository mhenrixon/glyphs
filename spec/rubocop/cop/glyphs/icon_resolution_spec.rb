# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Glyphs::IconResolution, :config do
  let(:config) { RuboCop::Config.new("Glyphs/IconResolution" => cop_config) }
  let(:cop_config) { { "IconsPath" => "spec/fixtures/svg/icons" } }

  # The missing-directory warning is deduplicated for the whole process (RuboCop
  # builds a fresh cop instance per file), so examples must not inherit it.
  before { described_class.reset_warnings! }

  context "with component calls" do
    it "accepts icons that exist" do
      expect_no_offenses(<<~RUBY)
        LucideIcon(:house)
        LucideIcon("circle-check", class: "size-4")
        HeroIcon(:check)
        PhosphorIcon(:lock)
      RUBY
    end

    it "suggests and corrects a close match" do
      expect_offense(<<~RUBY)
        HeroIcon(:chek)
                 ^^^^^ Icon `chek` not found in heroicons/outline. Did you mean `:check`?
      RUBY

      expect_correction(<<~RUBY)
        HeroIcon(:check)
      RUBY
    end

    it "corrects known lucide renames" do
      expect_offense(<<~RUBY)
        LucideIcon(:alert_triangle)
                   ^^^^^^^^^^^^^^^ Icon `alert-triangle` not found in lucide/outline. Did you mean `:triangle_alert`? (Lucide v1 reordered prefix and suffix.)
      RUBY

      expect_correction(<<~RUBY)
        LucideIcon(:triangle_alert)
      RUBY
    end

    it "lists candidates without correcting when several icons match" do
      expect_offense(<<~RUBY)
        LucideIcon(:circle)
                   ^^^^^^^ Icon `circle` not found in lucide/outline. Did you mean one of: `:circle_check`, `:circle_question_mark`?
      RUBY

      expect_no_corrections
    end

    it "reports when nothing similar exists" do
      expect_offense(<<~RUBY)
        LucideIcon(:zzzzzz)
                   ^^^^^^^ Icon `zzzzzz` not found in lucide/outline. No similar icons found.
      RUBY

      expect_no_corrections
    end

    it "validates against a literal variant directory" do
      expect_no_offenses(<<~RUBY)
        HeroIcon(:check, variant: :solid)
      RUBY

      expect_offense(<<~RUBY)
        HeroIcon(:question_mark_circle, variant: :solid)
                 ^^^^^^^^^^^^^^^^^^^^^ Icon `question-mark-circle` not found in heroicons/solid. No similar icons found.
      RUBY
    end

    it "skips dynamic names and dynamic variants" do
      expect_no_offenses(<<~RUBY)
        LucideIcon(icon_name)
        HeroIcon(:whatever_here, variant: some_variant)
      RUBY
    end

    it "skips components without library configuration" do
      expect_no_offenses(<<~RUBY)
        FlagIcon(:se)
      RUBY
    end
  end

  context "with legacy helper calls" do
    it "validates helper icon names" do
      expect_no_offenses("_lucide(:house)")

      expect_offense(<<~RUBY)
        _hero(:chek)
              ^^^^^ Icon `chek` not found in heroicons/outline. Did you mean `:check`?
      RUBY

      expect_correction(<<~RUBY)
        _hero(:check)
      RUBY
    end
  end

  context "with raw iconify class strings" do
    it "corrects a span with a single iconify class attribute" do
      expect_offense(<<~RUBY)
        span(class: "iconify lucide--house size-4")
                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `LucideIcon(:house, class: "size-4")` instead of raw `iconify lucide--…` class.
      RUBY

      expect_correction(<<~RUBY)
        LucideIcon(:house, class: "size-4")
      RUBY
    end

    it "corrects a span without extra classes" do
      expect_offense(<<~RUBY)
        span(class: "iconify phosphor--lock")
                    ^^^^^^^^^^^^^^^^^^^^^^^^ Use `PhosphorIcon(:lock, class: "")` instead of raw `iconify phosphor--…` class.
      RUBY

      expect_correction(<<~RUBY)
        PhosphorIcon(:lock)
      RUBY
    end

    it "flags interpolated iconify strings without correcting" do
      expect_offense(<<~'RUBY')
        span(class: "iconify lucide--#{name}")
                    ^^^^^^^^^^^^^^^^^^^^^^^^^ Use `LucideIcon(name, class: ...)` etc. instead of building a raw `iconify <library>--…` class string.
      RUBY

      expect_no_corrections
    end
  end

  context "when the icons directory does not exist" do
    let(:cop_config) { { "IconsPath" => "spec/fixtures/nope" } }

    it "warns instead of silently validating nothing" do
      expect { expect_no_offenses("LucideIcon(:anything_at_all)") }
        .to output(%r{\[Glyphs/IconResolution\].*spec/fixtures/nope/lucide/outline}).to_stderr
    end

    it "warns once per library and variant, not once per call site" do
      expect { expect_no_offenses("LucideIcon(:one)\nLucideIcon(:two)") }.to output.to_stderr
      expect { expect_no_offenses("LucideIcon(:three)") }.not_to output.to_stderr
      expect { expect_no_offenses("HeroIcon(:four)") }.to output(%r{nope/heroicons/outline}).to_stderr
    end
  end

  context "when the icons directory does not exist and Strict is enabled" do
    let(:cop_config) { { "IconsPath" => "spec/fixtures/nope", "Strict" => true } }

    it "reports an offence at the call site instead of warning" do
      expect do
        expect_offense(<<~RUBY)
          LucideIcon(:anything_at_all)
                     ^^^^^^^^^^^^^^^^ Icon directory `spec/fixtures/nope/lucide/outline` not found, so `LucideIcon` names are not validated. Sync the library or fix `IconsPath`/`Libraries`.
        RUBY
      end.not_to output.to_stderr

      expect_no_corrections
    end
  end

  # Load-bearing: a library that is synced but genuinely ships no SVGs is not a
  # misconfiguration, and must not produce an offence on every call site.
  context "when the icons directory exists but holds no SVGs" do
    let(:cop_config) do
      {
        "IconsPath" => "spec/fixtures/svg/icons",
        "Libraries" => { "EmptyIcon" => { "Dir" => "emptylib", "DefaultVariant" => "regular" } }
      }
    end

    it "stays silent" do
      expect { expect_no_offenses("EmptyIcon(:whatever_at_all)") }.not_to output.to_stderr
    end
  end

  context "with the declared empty Libraries default" do
    let(:cop_config) { { "IconsPath" => "spec/fixtures/svg/icons", "Libraries" => {} } }

    it "still resolves through the built-in library defaults" do
      expect_offense(<<~RUBY)
        PhosphorIcon(:locks)
                     ^^^^^^ Icon `locks` not found in phosphor/regular. Did you mean `:lock`?
      RUBY

      expect_correction(<<~RUBY)
        PhosphorIcon(:lock)
      RUBY
    end
  end

  context "with a Libraries override" do
    let(:cop_config) do
      {
        "IconsPath" => "spec/fixtures/svg/icons",
        "Libraries" => { "PhosphorIcon" => { "Dir" => "phosphor", "DefaultVariant" => "light" } }
      }
    end

    it "validates against the configured variant" do
      expect_offense(<<~RUBY)
        PhosphorIcon(:lock)
                     ^^^^^ Icon `lock` not found in phosphor/light. No similar icons found.
      RUBY
    end
  end
end
