if User.where(name: "Test user").present?
  puts "Skipping because user already exists"
else
  gds_organisation_id = "af07d5a5-df63-4ddc-9383-6a666845ebe9"
  User.create!(
    name: "Test user",
    permissions: ["signin", "GDS Admin"],
    organisation_content_id: gds_organisation_id,
  )
end

if Organisation.where(name: "Test Organisation").present?
  puts "Skipping because organisation already exists"
else
  Organisation.create!(
    name: "Test Organisation",
    slug: "test-organisation",
    acronym: "TO",
    organisation_type_key: :other,
    logo_formatted_name: "Test"
  )
end
