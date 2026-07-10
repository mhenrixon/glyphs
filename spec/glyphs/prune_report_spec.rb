# frozen_string_literal: true

RSpec.describe Glyphs::PruneReport do
  def entry(library:, variant:, kept:, deleted:, bytes_freed:)
    Glyphs::PruneReport::LibraryStat.new(library:, variant:, kept:, deleted:, bytes_freed:)
  end

  describe "#to_s" do
    it "summarizes deleted, kept and bytes freed" do
      report = described_class.new(
        stats: [entry(library: :lucide, variant: "outline", kept: 9, deleted: 1736, bytes_freed: 7_090_176)],
        deleted_names: [],
        dry_run: false
      )

      expect(report.to_s).to include("1736 deleted", "9 kept", "lucide/outline")
      expect(report.to_s).to include("6.76 MB")
    end

    it "prefixes dry-run output and hints how to delete" do
      report = described_class.new(
        stats: [entry(library: :lucide, variant: "outline", kept: 9, deleted: 1736, bytes_freed: 100)],
        deleted_names: [],
        dry_run: true
      )

      expect(report.to_s).to include("[dry-run]")
      expect(report.to_s).to include("PRUNE=1")
    end
  end

  describe "totals" do
    subject(:report) do
      described_class.new(
        stats: [
          entry(library: :lucide, variant: "outline", kept: 9, deleted: 1736, bytes_freed: 6_000_000),
          entry(library: :phosphor, variant: "regular", kept: 2, deleted: 3, bytes_freed: 4_000)
        ],
        deleted_names: [],
        dry_run: false
      )
    end

    it "sums deleted across libraries" do
      expect(report.deleted_count).to eq(1739)
    end

    it "sums kept across libraries" do
      expect(report.kept_count).to eq(11)
    end

    it "sums bytes freed across libraries" do
      expect(report.bytes_freed).to eq(6_004_000)
    end
  end
end
