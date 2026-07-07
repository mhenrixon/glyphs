# frozen_string_literal: true

RSpec.describe Glyphs, ".register_library" do
  after do
    described_class.send(:remove_const, :BrandIcon) if described_class.const_defined?(:BrandIcon, false)
  end

  it "defines a kit component for the custom library" do
    described_class.register_library(:brand, component: :BrandIcon)

    klass = described_class.const_get(:BrandIcon)
    expect(klass.ancestors).to include(Glyphs::Icon)
    expect(klass::LIBRARY).to eq(:brand)
  end

  it "exposes the component as a kit method" do
    described_class.register_library(:brand, component: :BrandIcon)

    component_class = Class.new(Phlex::HTML) do
      include Glyphs

      def view_template
        BrandIcon(:logo)
      end
    end

    described_class.configure { |config| config.raise_on_missing = false }
    # :brand has no synced svgs and no fallback; rendering raises IconNotFound,
    # which proves the kit method dispatched into the component.
    expect { component_class.new.call }.to raise_error(Icons::IconNotFound)
  end

  it "is idempotent for the same library and component" do
    first = described_class.register_library(:brand, component: :BrandIcon)
    second = described_class.register_library(:brand, component: :BrandIcon)

    expect(second).to be(first)
  end

  it "refuses to redefine a component bound to another library" do
    described_class.register_library(:brand, component: :BrandIcon)

    expect { described_class.register_library(:other, component: :BrandIcon) }
      .to raise_error(ArgumentError, /already defined/)
  end
end
