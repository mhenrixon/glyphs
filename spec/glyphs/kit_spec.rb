# frozen_string_literal: true

RSpec.describe Glyphs, "as a Phlex kit" do
  let(:component_class) do
    Class.new(Phlex::HTML) do
      include Glyphs

      def view_template
        div do
          LucideIcon(:house, class: "size-4")
          HeroIcon(:check, variant: :solid)
          Icon(:lock, library: :phosphor)
        end
      end
    end
  end

  it "exposes library components as capitalized kit methods" do
    html = component_class.new.call

    expect(html).to include('data-glyph="lucide-house"')
    expect(html).to include('data-glyph="hero-check-solid"')
    expect(html).to include('data-glyph="phosphor-lock"')
  end

  it "defines a component for every rails_icons library" do
    {
      LucideIcon: :lucide, PhosphorIcon: :phosphor, HeroIcon: :heroicons, TablerIcon: :tabler,
      FeatherIcon: :feather, BoxIcon: :boxicons, FlagIcon: :flags, HugeIcon: :hugeicons,
      LinearIcon: :linear, RadixIcon: :radix, SidekickIcon: :sidekickicons,
      WeatherIcon: :weather, AnimatedIcon: :animated
    }.each do |component, library|
      klass = described_class.const_get(component)

      expect(klass.ancestors).to include(Glyphs::Icon)
      expect(klass::LIBRARY).to eq(library)
    end
  end
end
