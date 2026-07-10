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
  end
end
