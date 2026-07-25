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

  # RuboCop builds its supported-parameter list from the keys present in
  # `config/default.yml` (see `ConfigValidator#each_invalid_parameter`), so an
  # option a cop reads but the file only documents in a comment is reported as
  # unsupported on every run.
  it "declares every cop_config parameter its cops read" do
    default_config = YAML.safe_load_file(plugin.rules(nil).value)

    undeclared = glyphs_cops.filter_map do |cop|
      missing = cop_config_keys_read_by(cop) - default_config.fetch(cop.cop_name).keys
      "#{cop.cop_name} reads undeclared #{missing.join(', ')}" if missing.any?
    end

    expect(undeclared).to be_empty
  end

  def glyphs_cops
    RuboCop::Cop::Registry.global.cops.select { |cop| cop.badge.department == :Glyphs }
  end

  # A cop reads its options both directly and through the shared
  # `RuboCop::Cop::Glyphs::*` mixins, so both sources have to be scanned.
  def cop_config_keys_read_by(cop_class)
    mixins = cop_class.included_modules.select { |mod| mod.name.to_s.start_with?("RuboCop::Cop::Glyphs::") }

    [cop_class, *mixins]
      .filter_map { |mod| Object.const_source_location(mod.name)&.first }
      .flat_map { |path| File.read(path).scan(/cop_config\["([^"]+)"\]/).flatten }
      .uniq
  end
end
