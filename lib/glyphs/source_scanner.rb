# frozen_string_literal: true

require "prism"

module Glyphs
  # Scans an application's source for statically-known icon references and
  # returns a Set of IconReference. Ruby/Phlex files are parsed with Prism (a
  # real AST); templates (.erb/.haml/.slim) are text-scanned for icon calls and
  # `iconify` class strings.
  #
  # Dynamic names/variants/libraries are silently skipped — they can't be known
  # statically and are covered by the pruner's keep-list. A file that fails to
  # parse warns and is skipped rather than aborting the scan.
  class SourceScanner
    DEFAULT_RUBY_GLOBS = ["app/**/*.rb", "lib/**/*.rb"].freeze
    DEFAULT_TEMPLATE_GLOBS = ["app/**/*.erb", "app/**/*.haml", "app/**/*.slim"].freeze

    # `LucideIcon(:house` / `_lucide(:house` — component or legacy-helper call
    # with a literal symbol/string first argument. Used for template text scans.
    TEMPLATE_CALL_NAMES = (
      IconReference::LIBRARY_TO_COMPONENT.values + IconReference::LEGACY_HELPERS.keys
    ).freeze
    TEMPLATE_CALL_PATTERN = /
      \b(#{Regexp.union(TEMPLATE_CALL_NAMES)})
      \(\s*[:"']([a-z0-9_-]+)
    /x

    def initialize(root:, ruby_globs: DEFAULT_RUBY_GLOBS, template_globs: DEFAULT_TEMPLATE_GLOBS)
      @root = root
      @ruby_globs = ruby_globs
      @template_globs = template_globs
    end

    def call
      references = Set.new
      ruby_files.each { |path| scan_ruby(path, references) }
      template_files.each { |path| scan_template(path, references) }
      references
    end

    private

    attr_reader :root

    def ruby_files
      glob(@ruby_globs)
    end

    def template_files
      glob(@template_globs)
    end

    def glob(patterns)
      patterns.flat_map { |pattern| Dir.glob(File.join(root, pattern)) }.uniq
    end

    def scan_ruby(path, references)
      result = Prism.parse_file(path)
      CallVisitor.new(references).visit(result.value)
    rescue StandardError => e
      warn "[Glyphs::SourceScanner] skipped #{path}: #{e.class}: #{e.message}"
    end

    def scan_template(path, references)
      text = File.read(path)
      scan_iconify(text, references)
      text.scan(TEMPLATE_CALL_PATTERN) do |method_name, name|
        add_call(references, method_name, name, nil)
      end
    rescue StandardError => e
      warn "[Glyphs::SourceScanner] skipped #{path}: #{e.class}: #{e.message}"
    end

    def scan_iconify(text, references)
      text.scan(IconReference::ICONIFY_PATTERN) do |library, name|
        library = library.to_sym
        references << IconReference.new(library:, variant: IconReference.default_variant_for(library), name:)
      end
    end

    # Adds a reference for a `Component(name, variant:)` / legacy-helper call.
    # `variant` is a resolved string, or nil to use the library default.
    def add_call(references, method_name, name, variant)
      library = IconReference.library_for(method_name)
      return unless library

      references << IconReference.new(
        library:,
        variant: variant || IconReference.default_variant_for(library),
        name: name.to_s.tr("_", "-")
      )
    end

    # Walks the Prism AST collecting icon references from call nodes.
    class CallVisitor < Prism::Visitor
      GENERIC_CALLS = %i[Icon icon].freeze

      def initialize(references)
        @references = references
        super()
      end

      def visit_call_node(node)
        record(node) if node.receiver.nil?
        super
      end

      def visit_string_node(node)
        node.unescaped.scan(IconReference::ICONIFY_PATTERN) do |library, name|
          library = library.to_sym
          references << IconReference.new(library:, variant: IconReference.default_variant_for(library), name:)
        end
        super
      end

      private

      attr_reader :references

      def record(node)
        method = node.name.to_s
        if GENERIC_CALLS.include?(node.name)
          record_generic(node)
        elsif IconReference.library_for(method)
          record_component(node, IconReference.library_for(method))
        end
      end

      def record_component(node, library)
        name = literal_string(first_argument(node))
        return unless name

        variant = variant_for(node, library)
        return if variant == :dynamic

        references << IconReference.new(library:, variant:, name:)
      end

      def record_generic(node)
        library = literal_symbol_or_string(keyword_argument(node, %i[library from]))
        return unless library

        name = literal_string(first_argument(node))
        return unless name

        variant = variant_for(node, library.to_sym)
        return if variant == :dynamic

        references << IconReference.new(library: library.to_sym, variant:, name:)
      end

      def variant_for(node, library)
        value_node = keyword_argument(node, [:variant])
        return IconReference.default_variant_for(library) unless value_node

        value = literal_symbol_or_string(value_node)
        value || :dynamic
      end

      def first_argument(node)
        node.arguments&.arguments&.first
      end

      # Returns the value node for the first matching keyword, or nil.
      def keyword_argument(node, keys)
        pair = keyword_pairs(node).find do |element|
          element.key.is_a?(Prism::SymbolNode) && keys.include?(element.key.unescaped.to_sym)
        end
        pair&.value
      end

      def keyword_pairs(node)
        args = node.arguments&.arguments || []
        hash = args.find { |arg| arg.is_a?(Prism::KeywordHashNode) || arg.is_a?(Prism::HashNode) }
        hash ? hash.elements.grep(Prism::AssocNode) : []
      end

      def literal_string(value_node)
        literal_symbol_or_string(value_node)&.tr("_", "-")
      end

      # Returns the literal String for a symbol/string node, or nil when the
      # node is dynamic (a variable, method call, interpolation, ...).
      def literal_symbol_or_string(value_node)
        value_node.unescaped if value_node.is_a?(Prism::SymbolNode) || value_node.is_a?(Prism::StringNode)
      end
    end
  end
end
