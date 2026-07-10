# frozen_string_literal: true

RSpec.describe Glyphs::IconReference do
  describe ".component_to_library" do
    subject(:map) { described_class.component_to_library }

    it "maps every library component to its icons-gem library symbol" do
      expect(map).to include(
        "LucideIcon" => :lucide,
        "PhosphorIcon" => :phosphor,
        "HeroIcon" => :heroicons,
        "TablerIcon" => :tabler,
        "FeatherIcon" => :feather,
        "BoxIcon" => :boxicons,
        "FlagIcon" => :flags,
        "HugeIcon" => :hugeicons,
        "LinearIcon" => :linear,
        "RadixIcon" => :radix,
        "SidekickIcon" => :sidekickicons,
        "WeatherIcon" => :weather,
        "AnimatedIcon" => :animated
      )
    end

    it "covers all 13 library components" do
      expect(map.size).to eq(13)
    end
  end

  describe ".legacy_helpers" do
    subject(:helpers) { described_class.legacy_helpers }

    it "maps the legacy helper names to library symbols" do
      expect(helpers).to include(
        "_lucide" => :lucide,
        "_phosphor" => :phosphor,
        "_hero" => :heroicons,
        "_heroicon" => :heroicons,
        "_tabler" => :tabler
      )
    end
  end

  describe ".library_for" do
    it "resolves a component name" do
      expect(described_class.library_for("LucideIcon")).to eq(:lucide)
    end

    it "resolves a legacy helper name" do
      expect(described_class.library_for("_hero")).to eq(:heroicons)
    end

    it "returns nil for an unknown method" do
      expect(described_class.library_for("puts")).to be_nil
    end
  end

  describe ".normalize_variant" do
    it "passes a real variant through" do
      expect(described_class.normalize_variant("solid")).to eq("solid")
    end

    it "normalizes an empty string to nil (the flat-layout override)" do
      expect(described_class.normalize_variant("")).to be_nil
    end

    it "normalizes '.' to nil (the variant-less convention)" do
      expect(described_class.normalize_variant(".")).to be_nil
    end

    it "normalizes a symbol variant to a string" do
      expect(described_class.normalize_variant(:solid)).to eq("solid")
    end

    it "returns nil for nil" do
      expect(described_class.normalize_variant(nil)).to be_nil
    end
  end

  describe ".default_variant_for" do
    it "reads the phosphor default variant from the icons gem" do
      expect(described_class.default_variant_for(:phosphor)).to eq("regular")
    end

    it "normalizes an empty-string configured default to nil" do
      allow(Icons.config.libraries[:lucide]).to receive(:default_variant).and_return("")

      expect(described_class.default_variant_for(:lucide)).to be_nil
    end

    it "reads the lucide default variant from the icons gem" do
      expect(described_class.default_variant_for(:lucide)).to eq("outline")
    end

    it "reads the heroicons default variant from the icons gem" do
      expect(described_class.default_variant_for(:heroicons)).to eq("outline")
    end

    it "returns nil for variant-less libraries" do
      expect(described_class.default_variant_for(:feather)).to be_nil
    end

    it "returns nil for an unknown library" do
      expect(described_class.default_variant_for(:nope)).to be_nil
    end
  end

  describe "value semantics" do
    it "normalizes into a comparable value object" do
      one = described_class.new(library: :lucide, variant: "outline", name: "house")
      two = described_class.new(library: :lucide, variant: "outline", name: "house")

      expect(one).to eq(two)
    end
  end

  describe "ICONIFY_PATTERN" do
    it "matches an iconify class string" do
      match = described_class::ICONIFY_PATTERN.match("iconify lucide--house size-4")

      expect(match[1]).to eq("lucide")
      expect(match[2]).to eq("house")
    end
  end
end
