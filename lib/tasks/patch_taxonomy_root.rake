desc "One time task to setup the Homepage as taxonomic root"
task :set_homepage_as_taxonomic_root => [:environment] do
  education_taxon_root = "c58fdadd-7743-46d6-9629-90bb3ccc4ef0"
  homepage = "f3bbdec2-0e62-4520-a7fd-6ffd5d36e03a"

  Services.publishing_api.patch_links(
    education_taxon_root,
    links: { parent_taxons: [homepage] }
  )
end
