# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Glyphs::LegacyIconHelper, :config do
  let(:config) { RuboCop::Config.new("Glyphs/LegacyIconHelper" => cop_config) }
  let(:cop_config) { {} }

  it "corrects _lucide preserving all arguments" do
    expect_offense(<<~RUBY)
      _lucide(:house, class: "size-4")
      ^^^^^^^ Use `LucideIcon(...)` instead of `_lucide(...)`.
    RUBY

    expect_correction(<<~RUBY)
      LucideIcon(:house, class: "size-4")
    RUBY
  end

  it "corrects _phosphor with a variant" do
    expect_offense(<<~RUBY)
      _phosphor("lock", variant: :bold)
      ^^^^^^^^^ Use `PhosphorIcon(...)` instead of `_phosphor(...)`.
    RUBY

    expect_correction(<<~RUBY)
      PhosphorIcon("lock", variant: :bold)
    RUBY
  end

  it "corrects both _hero and _heroicon to HeroIcon" do
    expect_offense(<<~RUBY)
      _hero(:check)
      ^^^^^ Use `HeroIcon(...)` instead of `_hero(...)`.
      _heroicon(:check)
      ^^^^^^^^^ Use `HeroIcon(...)` instead of `_heroicon(...)`.
    RUBY

    expect_correction(<<~RUBY)
      HeroIcon(:check)
      HeroIcon(:check)
    RUBY
  end

  it "corrects icon() with a literal library and removes the pair" do
    expect_offense(<<~RUBY)
      icon("check", library: "lucide")
      ^^^^ Use `LucideIcon(...)` instead of `icon(...)`.
    RUBY

    expect_correction(<<~RUBY)
      LucideIcon("check")
    RUBY
  end

  it "corrects icon() with a symbol library and keeps other kwargs" do
    expect_offense(<<~RUBY)
      icon("check", library: :phosphor, class: "size-4")
      ^^^^ Use `PhosphorIcon(...)` instead of `icon(...)`.
    RUBY

    expect_correction(<<~RUBY)
      PhosphorIcon("check", class: "size-4")
    RUBY
  end

  it "supports the rails_icons from: alias" do
    expect_offense(<<~RUBY)
      icon("check", from: "heroicons")
      ^^^^ Use `HeroIcon(...)` instead of `icon(...)`.
    RUBY

    expect_correction(<<~RUBY)
      HeroIcon("check")
    RUBY
  end

  it "corrects bare icon() to the default library component" do
    expect_offense(<<~RUBY)
      icon("check", class: "size-4")
      ^^^^ Use `HeroIcon(...)` instead of `icon(...)`.
    RUBY

    expect_correction(<<~RUBY)
      HeroIcon("check", class: "size-4")
    RUBY
  end

  it "flags but does not correct a dynamic library" do
    expect_offense(<<~RUBY)
      icon("check", library: some_library)
      ^^^^ Use a Glyphs component (e.g. `LucideIcon(...)`) instead of `icon(...)` with a dynamic library.
    RUBY

    expect_no_corrections
  end

  it "flags but does not correct an unknown library" do
    expect_offense(<<~RUBY)
      icon("check", library: "customlib")
      ^^^^ Use a Glyphs component instead of `icon(...)`; add a `LibraryComponents` mapping for library `customlib`.
    RUBY

    expect_no_corrections
  end

  it "ignores icon calls with a receiver, without arguments, and icon hash keys" do
    expect_no_offenses(<<~RUBY)
      record.icon("check")
      icon
      { icon: "check" }
    RUBY
  end

  context "with custom Mappings" do
    let(:cop_config) { { "Mappings" => { "_custom" => "CustomIcon" } } }

    it "uses the configured mapping instead of the defaults" do
      expect_offense(<<~RUBY)
        _custom(:x)
        ^^^^^^^ Use `CustomIcon(...)` instead of `_custom(...)`.
      RUBY

      expect_correction(<<~RUBY)
        CustomIcon(:x)
      RUBY

      expect_no_offenses("_lucide(:house)")
    end
  end

  context "with a custom DefaultLibraryComponent" do
    let(:cop_config) { { "DefaultLibraryComponent" => "LucideIcon" } }

    it "corrects bare icon() to the configured component" do
      expect_offense(<<~RUBY)
        icon("check")
        ^^^^ Use `LucideIcon(...)` instead of `icon(...)`.
      RUBY

      expect_correction(<<~RUBY)
        LucideIcon("check")
      RUBY
    end
  end
end
