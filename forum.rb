# Forum prompt:
# I'm reimagining an old-school forum app, that's a cross between GitHub Issues and Slack.
# Users have one identity in the app and can be part of many forums.
# Within a forum, there are channels that are either public or private.
# Public channels show up to everyone and private channels must be joined.
# Within channels, there are topics with posts.
# Topics are always visible to people with channel access, but you can also subscribe to a topic to receive notifications related to updates.

class User
  has_many :memberships
  has_many :forums, through: :memberships

  has_many :subscriptions

  def subscribe_to(record)
    subscriptions.create! record:
  end
end

class Membership
  belongs_to :user
  belongs_to :forum
end

class Forum
  has_many :memberships
  has_many :users, through: :memberships, after_add: :auto_enroll

  has_many :channels

  def auto_enroll(user)
    channels.unrestricted.enroll user
  end
end

class Forum::Channel
  belongs_to :forum
  has_many :topics

  has_many :enrollments

  before_create :build_enrollments, unless: :restricted?

  # name, description

  def build_enrollments
    forum.users.each do |user|
      enrollments.build user:
    end
  end
end

class Forum::Channel::Enrollment
  belongs_to :user
  belongs_to :channel

  # moderator?
end

@channel.enrollments.each do |enrollment|
  user.name + moderator_badge_for(enrollment)
end

class Forum::Topic
  belongs_to :channel
  has_many :posts
end

# app/models/forum/topic/post.rb
class Forum::Topic::Post
  belongs_to :user
  belongs_to :topic
  delegate :channel, to: :topic

  after_create { user.subscribe_to topic }
  after_create_commit :broadcast_later

  def broadcast
    User::Subscription.where(record: [topic, channel, channel.forum], user: users).each do |subscription|
      subscription.create_broadcast_for self
    end
  end
end

class User::Subscription
  belongs_to :user
  belongs_to :forum
  delegated_type :record, types: %i[ Forum Channel Topic ]
end

class Users::SubscriptionsController
  def create
    Current.user.subscribe_to params[:id]
  end
end
