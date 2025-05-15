# Riffed on joining a User, which would probably be in most databases
# with tables in Memory in ActiveRecord. Based on the availability of cross
# database joins starting in Rails 7, the :disable_joins flag creates separate
# queries.
#
# I'll probably do another one soon joining straight into duckdb.
# These are especially useful for agentic activity, where some data will always
# be ephemeral.
#
# See this hack for running it.  https://thoughtbot.com/blog/rails-runner
# Based on https://github.com/kaspth/riffing-on-rails --see README
#
# Place this script in lib/joiner.rb or name similarly.
# This assumes a User model in a rails app, with a different ActiveRecord connection
# that the in memory one can join to.

require "bundler/setup"
require "active_record"
require "action_controller"

class MemoryRecord < ActiveRecord::Base
  self.abstract_class = true
  establish_connection(
    adapter:  "sqlite3",
    database: ":memory:",   # keeps everything in RAM
    pool:     1,
    timeout:  1000
  )
end

class Limb < MemoryRecord
  belongs_to :body
  has_one :user, through: :body, disable_joins: true

  scope :dominant, ->(side) { where("name LIKE ?", "%" + side.to_s.titleize + "%") }
  scope :head, -> { where("name LIKE ?", "%Head%") }
end

class Body < MemoryRecord
  has_many :limbs
  belongs_to :user
end

MemoryRecord.connection.create_table :limbs do |t|
  t.references :body, null: false, index: true
  t.string :name, null: false
end

MemoryRecord.connection.create_table :bodies do |t|
  t.string :title, null: false
  t.text :content, null: false
  t.references :user, null: false, index: true
end

class User # this is going to add to the user in rails, these relations
  has_one :body
  has_many :limbs, through: :body, disable_joins: true

end

User.all.each do |user|
  body = Body.create!(title: "Homo Sapiens", content: "A standard body", user: )
  limbs = ["Left Leg", "Right Leg", "Left Arm", "Right Arm", "Head"]
  limbs.each do
    Limb.create!(body:, name: _1)
  end
end

pp User.all.sample.limbs.map(&:name)

binding.irb

MemoryRecord.connection_pool.disconnect!
