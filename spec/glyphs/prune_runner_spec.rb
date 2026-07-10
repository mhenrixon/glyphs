# frozen_string_literal: true

require "tmpdir"
require "fileutils"

RSpec.describe Glyphs::PruneRunner do
  let(:root) { Dir.mktmpdir("glyphs-runner") }
  let(:icons_root) { File.join(root, "app/assets/svg/icons") }

  before do
    FileUtils.mkdir_p(icons_root)
    FileUtils.cp_r(Dir.glob(File.expand_path("../fixtures/svg/icons/*", __dir__)), icons_root)
    Glyphs.configure do |config|
      config.fallback_icons = { lucide: "circle-question-mark", phosphor: "question" }
      config.keep_icons = %w[triangle-alert]
    end
  end

  after { FileUtils.remove_entry(root) }

  def write_source(relative, contents)
    path = File.join(root, relative)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, contents)
  end

  def exists?(relative)
    File.exist?(File.join(icons_root, relative))
  end

  def run(dry_run: false)
    described_class.new(root:, icons_root:, dry_run:).call
  end

  it "prunes based on scanned references plus config keep_icons and fallbacks" do
    write_source("app/components/demo.rb", <<~RUBY)
      class Demo
        def view_template
          LucideIcon(:house)
          PhosphorIcon(:lock)
        end
      end
    RUBY

    run

    expect(exists?("lucide/outline/house.svg")).to be(true)          # referenced
    expect(exists?("lucide/outline/triangle-alert.svg")).to be(true) # keep_icons
    expect(exists?("lucide/outline/circle-question-mark.svg")).to be(true) # fallback
    expect(exists?("phosphor/regular/lock.svg")).to be(true)         # referenced
    expect(exists?("lucide/outline/circle-check.svg")).to be(false)  # pruned
  end

  it "returns a report" do
    write_source("app/components/demo.rb", "LucideIcon(:house)")

    report = run

    expect(report).to be_a(Glyphs::PruneReport)
    expect(report.deleted_count).to be > 0
  end

  it "keeps scanning templates when prune_source_globs adds extra locations" do
    # Referenced in a template AND an extra scanned location; the default
    # template scan must NOT be dropped when prune_source_globs is set.
    write_source("app/views/foo.html.erb", "<%= render LucideIcon(:house) %>")
    write_source("config/icons.yml", "badge: \"iconify lucide--circle-check\"")
    Glyphs.configure do |config|
      config.fallback_icons = { lucide: "circle-question-mark" }
      config.keep_icons = []
      config.prune_source_globs = ["config/**/*.yml"]
    end

    run

    expect(exists?("lucide/outline/house.svg")).to be(true)         # template default still scanned
    expect(exists?("lucide/outline/circle-check.svg")).to be(true)  # from the extra yml location
    expect(exists?("lucide/outline/triangle-alert.svg")).to be(false)
  end

  describe "#verify!" do
    it "raises when a kept icon is missing after pruning" do
      write_source("app/components/demo.rb", "LucideIcon(:house)")
      runner = described_class.new(root:, icons_root:, dry_run: false)
      runner.call

      # Simulate a bad state: delete a kept icon out from under the runner.
      File.delete(File.join(icons_root, "lucide/outline/house.svg"))

      expect { runner.verify! }.to raise_error(Glyphs::PruneRunner::VerificationError, /house/)
    end

    it "passes when every kept icon still resolves" do
      write_source("app/components/demo.rb", "LucideIcon(:house)")
      runner = described_class.new(root:, icons_root:, dry_run: false)
      runner.call

      expect { runner.verify! }.not_to raise_error
    end

    it "ignores fallbacks for libraries that aren't synced on disk" do
      # Configure a fallback for tabler, which has no directory under icons_root.
      Glyphs.configure { |config| config.fallback_icons = { lucide: "circle-question-mark", tabler: "help" } }
      write_source("app/components/demo.rb", "LucideIcon(:house)")
      runner = described_class.new(root:, icons_root:, dry_run: false)
      runner.call

      expect { runner.verify! }.not_to raise_error
    end
  end
end
