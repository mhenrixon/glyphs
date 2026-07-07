# frozen_string_literal: true

RSpec.describe Glyphs::Configuration do
  describe "defaults" do
    subject(:configuration) { described_class.new }

    it "raises on missing icons outside Rails" do
      expect(configuration.raise_on_missing_icon.call).to be(true)
    end

    it "has a no-op missing icon hook" do
      expect { configuration.on_missing_icon.call(StandardError.new, name: "x", library: :lucide, variant: nil) }
        .not_to raise_error
    end

    it "ships fallback icons for lucide, phosphor and heroicons" do
      expect(configuration.fallback_icons).to eq(
        lucide: "circle-question-mark",
        phosphor: "question",
        heroicons: "question-mark-circle"
      )
    end

    it "caches svgs" do
      expect(configuration.cache_svgs).to be(true)
    end
  end

  describe "Glyphs.configure" do
    it "yields the memoized configuration" do
      Glyphs.configure { |config| config.cache_svgs = false }

      expect(Glyphs.configuration.cache_svgs).to be(false)
    end

    it "can be reset" do
      Glyphs.configure { |config| config.cache_svgs = false }
      Glyphs.reset_configuration!

      expect(Glyphs.configuration.cache_svgs).to be(true)
    end
  end
end
