# Make a First Ruby Friend app that automatically does the matching of mentors and mentees,
# based on geography (local context and timezone), current level, mentor demographic preference.

class User
  belongs_to :profile

  has_many :groups
  has_many :cohorts, through: :groups
end

class Program::Cohort
  # started_at ended_at
  has_many :groups
end

class Program::Cohort::Group
  has_many :participants
end

class Program::Cohort::Participant
  enum role: %i[ mentor mentee ]
end

class Program::IntentRequest
  belongs_to :cohort

  has_many :request_details
  has_rich_text :description
end

class Program::RequestDetail
  belongs_to :intent_request
  belongs_to :detail

  enum :kind, %i[ required preferred ]
end

class Profile::Detail
end

class Mentor
  belongs_to :user
end

class Mentee
  belongs_to :user
end

class Profile
  belongs_to :user

  # country
  # time_zone
end
