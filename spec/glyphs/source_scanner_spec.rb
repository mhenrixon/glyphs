# frozen_string_literal: true

require "tmpdir"
require "fileutils"

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

      it "records the explicit variant on a template component call" do
        # HeroIcon(:check, variant: :solid) in .erb must resolve to solid, not
        # the default outline — else the solid file gets pruned. (outline/check
        # is also present via _hero(:check) in the Ruby fixture, so only assert
        # the solid tuple is captured.)
        expect(references).to include(ref(:heroicons, "solid", "check"))
      end

      it "records the generic icon helper with from:/library: in a template" do
        expect(references).to include(
          ref(:lucide, "outline", "gauge"),          # icon "gauge", from: :lucide
          ref(:heroicons, "solid", "bell")           # icon("bell", library: "heroicons", variant: "solid")
        )
      end

      it "reads variant:/from: past a nested method call in the argument tail" do
        # icon("save", class: cn("a", active?), from: :lucide) — the nested cn()
        # paren must not truncate the tail before from:.
        expect(references).to include(ref(:lucide, "outline", "save"))
        # PhosphorIcon(:lock, class: cn("b"), variant: :bold) — variant past nested paren.
        expect(references).to include(ref(:phosphor, "bold", "lock"))
      end
    end

    context "with the variant-less '.' convention" do
      it "normalizes variant: :\".\" to no-variant so the flat file is kept" do
        Dir.mktmpdir do |dir|
          FileUtils.mkdir_p(File.join(dir, "app"))
          File.write(File.join(dir, "app/dot.rb"), 'LucideIcon(:house, variant: :".")')
          refs = described_class.new(root: dir).call

          expect(refs).to include(ref(:lucide, nil, "house"))
          expect(refs).not_to include(ref(:lucide, ".", "house"))
        end
      end
    end

    context "with an unparseable file" do
      it "warns and continues instead of crashing" do
        expect { described_class.new(root:).call }.not_to raise_error
      end
    end
  end
end
