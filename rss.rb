# RSS Feed Reader: Users subscribe to RSS and Atom feeds, and get a list of posts they can read and favorite.

class User
  has_many :subscriptions
  has_many :feeds, through: :subscriptions

  belongs_to :timeline

  has_many :favorites

  def favorite(item)
    favorites.create_or_find_by! item:
  end

  def unfavorite(item)
    favorites.destroy_by item:
  end
end

class Subscription
  belongs_to :user
  belongs_to :feed
end

class Feed
  has_many :subscriptions
  has_many :users, through: :subscriptions

  # url

  def public?
    !personal?
  end

  def personal?
    password_details?
  end
end

class Feed::Post
end

class User::Timeline
  has_many :items
end

class User::Favorite
  belongs_to :user
  belongs_to :item
end

class User::Timeline::Item
  belongs_to :timeline
  belongs_to :post

  # accepted_at
  # rejected_at
  belongs_to :download, optional: true
end

class User::TimelinesController < ApplicationController
  def show
    @items = Current.user.timeline.items.order(:created_at)
  end
end

# app/views/user/timelines/show.html.erb
@items.each do |item|
  if Current.user.favorite?(item)
    button_to unfavorite_item_path(item), method: :delete
  else
    button_to favorite_item_path(item)
  end
end

class User::Items::FavoritesController < ApplicationController
  def show
  end

  def create
    @item = Current.user.timeline.items.find(params[:id])
    Current.user.favorite @item
  end

  def destroy
    @item = Current.user.timeline.items.find(params[:id])
    Current.user.unfavorite @item
  end
end


resources :users do
  namespace :timeline do
    resources :favorites
  end
end


class Current < ActiveSupport::CurrentAttributes
  attribute :user
end
