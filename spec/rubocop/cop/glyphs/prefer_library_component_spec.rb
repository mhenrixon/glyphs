# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Glyphs::PreferLibraryComponent, :config do
  let(:config) { RuboCop::Config.new("Glyphs/PreferLibraryComponent" => cop_config) }
  let(:cop_config) { {} }

  it "corrects Icon() with a literal library" do
    expect_offense(<<~RUBY)
      Icon(:house, library: :lucide)
      ^^^^ Use `LucideIcon(...)` instead of `Icon(..., library: ...)`.
    RUBY

    expect_correction(<<~RUBY)
      LucideIcon(:house)
    RUBY
  end

  it "keeps remaining keyword arguments" do
    expect_offense(<<~RUBY)
      Icon("check", library: "heroicons", class: "size-4")
      ^^^^ Use `HeroIcon(...)` instead of `Icon(..., library: ...)`.
    RUBY

    expect_correction(<<~RUBY)
      HeroIcon("check", class: "size-4")
    RUBY
  end

  it "flags but does not correct a dynamic library" do
    expect_offense(<<~RUBY)
      Icon(:house, library: some_library)
      ^^^^ Prefer a library-specific Glyphs component over `Icon(...)` with a dynamic library.
    RUBY

    expect_no_corrections
  end

  it "ignores Icon() without a library and calls with receivers" do
    expect_no_offenses(<<~RUBY)
      Icon(:house)
      Some::Icon(:house, library: :lucide)
    RUBY
  end
end
