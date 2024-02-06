# 1. Spam post detection: Run a forum post through a series of configurable checks to give it a spam score,
# and flag the post when it crosses the threshold, with details on what led to the score.

require "bundler/setup"
require "active_record"

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")

ActiveRecord::Schema.define do
  create_table :posts do |t|
    t.string :title, null: false
    t.text :content, null: false
  end

  create_table :users do |t|
  end
end

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end

class Post < ApplicationRecord
end

class User < ApplicationRecord
  has_many :posts
end

module Spam
  module Detectors
    def self.check(post)
      Check.new post, Abstract.detectors
    end

    class Check
      def initialize(post, detectors)
        @detectors = detectors.map { _1.new(post:) }
      end

      def score
        @detectors.sum(&:score) / @detectors.size
      end
    end

    class Abstract < Struct.new(:post, :max_hits, keyword_init: true)
      def initialize(post:, max_hits: 1) = super

      singleton_class.attr_reader :detectors
      @detectors = []
      def self.inherited(detector) = detectors << detector

      def hits
        hit? ? 1 : 0
      end

      def score
        hits / max_hits.to_f
      end
    end

    module Content
    end

    module Account
    end
  end
end

class Spam::Detectors::Account::PostCount < Spam::Detectors::Abstract
  def hit?
    post.user.posts.where(created_at: 1.hour.ago..).count >= 50
  end
end

# The first check we did, just to start us off and then we continued from here.
# We also had checks respond to `score` but ultimately moved on to hits/max_hits though I don't quite remember the reasoning now.
class Spam::Detectors::Content::FirstPost < Spam::Detectors::Abstract
  def hit?
    post.content == "My first post"
  end
end

class Spam::Detectors::Content::LinkCount < Spam::Detectors::Abstract
  def hits
    content_links.size
  end

  def max_hits
    10
  end

  private

  def content_links
    post.content.scan /https?:.*? /
  end
end

class Spam::Detectors::Content::Dictionary < Spam::Detectors::Abstract
  def initialize(post, words)
    super
    @words = words
  end

  def hits
    content_words.uniq.size
  end

  def max_hits
    words.size
  end

  private

  def content_words
    post.content.scan Regexp.new(@words.join("|"))
  end
end

class Post::SpamDetectionsController < ApplicationController
  def create
    @detection = Spam::Detectors.check @post
  end
end
