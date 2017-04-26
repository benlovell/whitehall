module Taxonomy
  class PublishingApiRootTaxonParser
    def self.parse_taxons(item_hash, key: 'expanded_links')
      item_hash[key]["child_taxons"].map do |child|
        taxon = build_taxon(child)
        taxon << parse_taxons(child, key: 'links')
      end
    end

    def self.build_taxon(item_hash)
      Taxon.new(
        name: item_hash["title"],
        content_id: item_hash["content_id"],
        base_path: item_hash["base_path"]
      )
    end
  end
end
