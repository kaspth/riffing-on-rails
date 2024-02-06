# Spotify Mix Playlists: Assuming we have a history of played songs for a user,
# we have song recommendations via nearest neighbor search,
# and we have categorizations (genre, mood, era, instrumental/vocal, cultural/regional, theme),
# let system admins create mix templates based on music categorizations
# and then generate refreshable custom playlists for each user.

class User
  has_many :playlists
  has_one :history
end

class History
  has_many :listens
  has_many :tracks, through: :listens
end

class History::Listen
  belongs_to :history
  belongs_to :track
end

class Track
  has_many :categorizations
  has_many :categories, through: :categorizations
end

track.inner_joins(Track::Category.genres).nearest(100)

Track::Category.genres.where(value: ["pop", "hiphop"])
Track::Category.eras.where(value: ["80s", "90s"])

class Track::Category
  has_many :categorizations
  has_many :tracks, through: :categorizations

  belongs_to :details
end

class Track::Category::Categorization
  belongs_to :track
  belongs_to :category
end

class Playlist
end

class Mix::Template
  has_many :categories

  def build_for(user)
    from_own_history = user.history.tracks.ordered_by_popularity.joins(:categories).where(categories:).limit(100).flat_map do |track|
      [track, track.nearest(10)]
    end.uniq.first(100)

    if from_own_history >= 100
      from_own_history
    else
      Track.ordered_by_popularity.joins(:categories).where(categories:).limit(100).flat_map do |track|
        [track, track.nearest(10)]
      end.including(from_own_history).uniq.first(100)
    end
  end
end

class Mix::Build
  belongs_to :template
  belongs_to :user

  has_many :links
  has_many :tracks, through: :links

  def regenerate
    update! tracks: template.build_for(user)
  end
end

class Mix::Build::Link
  belongs_to :build
  belongs_to :track
end
