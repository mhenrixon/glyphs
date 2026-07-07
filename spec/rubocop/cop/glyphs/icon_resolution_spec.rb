# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Glyphs::IconResolution, :config do
  let(:config) { RuboCop::Config.new("Glyphs/IconResolution" => cop_config) }
  let(:cop_config) { { "IconsPath" => "spec/fixtures/svg/icons" } }

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

  context "when the icons path does not exist" do
    let(:cop_config) { { "IconsPath" => "spec/fixtures/nope" } }

    it "reports nothing" do
      expect_no_offenses("LucideIcon(:anything_at_all)")
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
