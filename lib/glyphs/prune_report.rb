# frozen_string_literal: true

module Glyphs
  # The result of an IconPruner run: per-(library, variant) counts, a sample of
  # deleted names, and a human-readable summary. Value object, no side effects.
  class PruneReport
    LibraryStat = Data.define(:library, :variant, :kept, :deleted, :bytes_freed)

    SAMPLE_LIMIT = 20

    attr_reader :stats, :deleted_names, :dry_run

    def initialize(stats:, deleted_names:, dry_run:)
      @stats = stats
      @deleted_names = deleted_names
      @dry_run = dry_run
    end

    def deleted_count = stats.sum(&:deleted)
    def kept_count = stats.sum(&:kept)
    def bytes_freed = stats.sum(&:bytes_freed)

    def to_s
      lines = [headline, *stat_lines]
      lines << sample_line if deleted_names.any?
      lines << "  Re-run with PRUNE=1 GLYPHS_PRUNE_ICONS=1 to delete." if dry_run
      lines.join("\n")
    end

    private

    def headline
      prefix = dry_run ? "[dry-run] " : ""
      verb = dry_run ? "Would prune" : "Pruned"
      "#{prefix}#{verb} #{deleted_count} icons, kept #{kept_count}, freed #{human_bytes(bytes_freed)}"
    end

    def stat_lines
      stats.sort_by { |stat| [stat.library.to_s, stat.variant.to_s] }.map do |stat|
        "  #{stat.library}/#{stat.variant || '.'}: #{stat.deleted} deleted, #{stat.kept} kept"
      end
    end

    def sample_line
      shown = deleted_names.first(SAMPLE_LIMIT).join(", ")
      extra = deleted_names.size - SAMPLE_LIMIT
      extra.positive? ? "  e.g. #{shown} … and #{extra} more" : "  e.g. #{shown}"
    end

    def human_bytes(bytes)
      units = %w[B KB MB GB]
      size = bytes.to_f
      unit = units.shift
      while size >= 1024 && units.any?
        size /= 1024
        unit = units.shift
      end
      unit == "B" ? "#{bytes} B" : format("%.2f %s", size, unit)
    end
  end
end
