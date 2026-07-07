# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Docs site" do
  it "renders the landing page" do
    get "/"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("glyphs")
  end

  it "renders every registered docs page" do
    expect(Doc.all).not_to be_empty

    Doc.all.each do |doc|
      get "/docs/#{doc.slug}"

      expect(response).to have_http_status(:ok), "expected /docs/#{doc.slug} to render, got #{response.status}"
    end
  end

  it "serves every page as a Markdown twin" do
    Doc.all.each do |doc|
      get "/docs/#{doc.slug}.md"

      expect(response).to have_http_status(:ok), "expected /docs/#{doc.slug}.md to render, got #{response.status}"
    end
  end

  it "serves the AI surfaces" do
    get "/llms.txt"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("glyphs")

    get "/llms-full.txt"
    expect(response).to have_http_status(:ok)
  end

  it "answers the healthcheck" do
    get "/up"

    expect(response).to have_http_status(:ok)
  end
end
