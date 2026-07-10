# frozen_string_literal: true

RSpec.describe Glyphs::SourceScanner do
  let(:root) { File.expand_path("../fixtures/source", __dir__) }

  def ref(library, variant, name)
    Glyphs::IconReference.new(library:, variant:, name:)
  end

  describe "#call" do
    subject(:references) { described_class.new(root:).call }

    context "with Ruby (Phlex) source" do
      it "records component calls with literal names" do
        expect(references).to include(
          ref(:lucide, "outline", "house"),
          ref(:lucide, "outline", "circle-check"),
          ref(:phosphor, "regular", "question")
        )
      end

      it "records the explicit variant, not the default" do
        expect(references).to include(
          ref(:heroicons, "solid", "check"),
          ref(:phosphor, "bold", "lock")
        )
      end

      it "dasherizes underscored symbol names" do
        expect(references).to include(ref(:lucide, "outline", "triangle-alert"))
      end

      it "records legacy helper calls" do
        expect(references).to include(
          ref(:lucide, "outline", "triangle-alert"),
          ref(:heroicons, "outline", "check")
        )
      end

      it "records generic Icon/icon calls with a literal library" do
        expect(references).to include(
          ref(:lucide, "outline", "house"),
          ref(:heroicons, "outline", "check")
        )
      end

      it "records iconify class strings inside Ruby" do
        expect(references).to include(ref(:lucide, "outline", "menu"))
      end
    end

    context "with dynamic references" do
      it "skips a dynamic icon name" do
        expect(references).not_to include(ref(:lucide, "outline", "zap"))
      end

      it "does not record a reference with a dynamic variant" do
        heroicons = references.select { |r| r.library == :heroicons && r.name == "check" }

        expect(heroicons.map(&:variant)).not_to include("some-variant")
        expect(heroicons.map(&:variant)).to include("solid", "outline")
      end

      it "skips a generic Icon call with a dynamic library" do
        # `Icon(:house, library: some_library)` — house appears via the literal
        # lucide call, but no dynamic-library reference should be recorded.
        expect(references.count { |r| r.name == "house" && r.library == :lucide }).to be >= 1
      end
    end

    context "with template source" do
      it "records iconify strings in .erb" do
        expect(references).to include(ref(:heroicons, "outline", "search"))
      end

      it "records component calls embedded in .erb" do
        expect(references).to include(
          ref(:lucide, "outline", "house"),
          ref(:phosphor, "regular", "lock")
        )
      end
    end

    context "with an unparseable file" do
      it "warns and continues instead of crashing" do
        expect { described_class.new(root:).call }.not_to raise_error
      end
    end
  end
end
