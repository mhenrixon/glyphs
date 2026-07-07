# frozen_string_literal: true

RSpec.describe Glyphs::RuboCop::Plugin do
  subject(:plugin) { described_class.new }

  it "identifies itself" do
    about = plugin.about

    expect(about.name).to eq("glyphs")
    expect(about.version).to eq(Glyphs::VERSION)
  end

  it "supports the rubocop engine" do
    expect(plugin.supported?(LintRoller::Context.new(engine: :rubocop))).to be(true)
    expect(plugin.supported?(LintRoller::Context.new(engine: :other))).to be(false)
  end

  it "points at a parseable default configuration covering all cops" do
    rules = plugin.rules(nil)

    expect(rules.type).to eq(:path)

    config = YAML.safe_load_file(rules.value)
    expect(config.keys).to contain_exactly(
      "Glyphs/LegacyIconHelper", "Glyphs/IconResolution", "Glyphs/PreferLibraryComponent"
    )
    expect(config.values).to all(include("Enabled" => true))
  end
end
