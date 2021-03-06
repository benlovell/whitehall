FactoryBot.define do
  factory :consultation, class: Consultation, parent: :edition, traits: [:with_organisations, :with_topics] do
    title "consultation-title"
    body  "consultation-body"
    opening_at { 1.day.ago }
    closing_at { 6.weeks.from_now }
    transient do
      relevant_to_local_government { false }
    end
  end

  factory :imported_consultation, parent: :consultation, traits: [:imported]
  factory :draft_consultation, parent: :consultation, traits: [:draft]
  factory :submitted_consultation, parent: :consultation, traits: [:submitted]
  factory :rejected_consultation, parent: :consultation, traits: [:rejected]
  factory :published_consultation, parent: :consultation, traits: [:published]
  factory :deleted_consultation, parent: :consultation, traits: [:deleted]
  factory :superseded_consultation, parent: :consultation, traits: [:superseded]
  factory :scheduled_consultation, parent: :consultation, traits: [:scheduled]

  factory :open_consultation, parent: :published_consultation do
    opening_at { 1.day.ago }
    closing_at { 1.day.from_now }
  end

  factory :closed_consultation, parent: :published_consultation do
    opening_at { 2.days.ago }
    closing_at { 1.day.ago }
  end

  factory :unopened_consultation, parent: :published_consultation do
    opening_at { 2.days.from_now }
    closing_at { 3.days.from_now }
  end

  factory :consultation_with_outcome, parent: :closed_consultation do
    outcome { create(:consultation_outcome) }
  end

  factory :consultation_with_outcome_attachment, parent: :closed_consultation do
    outcome { create(:consultation_outcome, :with_file_attachment) }
  end
end
