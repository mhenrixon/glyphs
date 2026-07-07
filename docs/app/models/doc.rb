# frozen_string_literal: true

# In-memory registry of the reference docs. One line per page — slug and view
# derive from the title (both overridable), and the sidebar nav derives from
# this registry with zero extra code (see config/initializers/docs_kit.rb's
# `nav_registries`). Add a page with `rails g docs_kit:page "Title" --group=…`,
# which appends the `page` line here and writes the class under
# app/views/docs/pages/.
#
# Uses DocsKit::Registry for the shared all/from_slug/grouped/nav_items API.
class Doc
  extend DocsKit::Registry
  path_prefix    "/docs"
  view_namespace "Views::Docs::Pages"

  page "Installation", group: "Getting started"
  page "Quick start", group: "Getting started"
  page "Components", group: "Guide"
  page "Missing icons", group: "Guide"
  page "Custom libraries", group: "Guide"
  page "Migration", group: "Guide"
  page "RuboCop cops", group: "Reference", slug: "rubocop-cops", view: "RubocopCops"
end
