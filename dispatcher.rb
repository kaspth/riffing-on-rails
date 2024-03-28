# Dispatcher
# Building a Dispatcher app for service companies to plan & schedule their onsites.

class Location < AppliationRecord
  def address
  end
end

class Organization < AppliationRecord
  has_many :organization_jobs
  has_many :user_memberships
  has_many :users, through: :user_memberships
end

class Organization::Membership < AppliationRecord
  belongs_to :organization
  belongs_to :organization_user
end

class Organization::User < AppliationRecord
  has_many :organization_memberships
end

class Organization::Customer < AppliationRecord
  belongs_to :customer
end

class Organization::Job < AppliationRecord
  belongs_to :customer
  belongs_to :organization

  has_many :tasks
  has_many :onsites

  attribute :name
end

class Organization::Task < ApplicationRecord
  belongs_to :onsite

  attribute :description
  attribute :estimated_duration
end

class Organization::TaskAssignment < ApplicationRecord
  belongs_to :task
  belongs_to :onsite
end

class Organization::Onsite < ApplicationRecord
  belongs_to :job
  belongs_to :location

  has_one :calendar_events

  has_many :onsite_assignments
  has_many :onsite_tasks, through: :task_assignments

  enum status: [:draft, :finalized]

  attribute :label
  attribute :estimated_total_duration
end

class Organization::OnsiteAssignment < ApplicationRecord
  belongs_to :user
  belongs_to :onsite
end

class Calendar::Event
  belongs_to :preceding_event #??
  belongs_to :organization_onsite

  attribute :started_at
  attribute :ended_at
end

class Calendar::EventBlob
  belongs_to :calendar_event

  attribute :url # https://dispatcher.com/onsite/2
  attribute :started_at
  attribute :ended_at
  attribute :address # location
  attribute :title # onsite
  attribute :attendees # onsite_assignments
end
