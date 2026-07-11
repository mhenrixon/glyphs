# frozen_string_literal: true

namespace :glyphs do
  desc "Prune synced icons not referenced in source. Dry-run unless PRUNE=1 GLYPHS_PRUNE_ICONS=1."
  task prune_icons: :environment do
    commit = ENV["PRUNE"] == "1" && ENV["GLYPHS_PRUNE_ICONS"] == "1"

    begin
      report = Glyphs::PruneRunner.call(dry_run: !commit)
    rescue Glyphs::PruneRunner::VerificationError => e
      warn "[glyphs:prune_icons] #{e.message}"
      abort "[glyphs:prune_icons] prune verification failed — aborting."
    end

    puts report
  end
end
