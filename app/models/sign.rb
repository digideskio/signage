class Sign < ActiveRecord::Base
  has_many :sign_users
  has_many :users, through: :sign_users, dependent: :destroy, prevent_dups: true

  has_many :sign_slides
  has_many :slides, through: :sign_slides, dependent: :destroy, prevent_dups: true

  # These states are shown as 'Public' and 'Private' to the user, however due to column name restrictions from Postgres, I can't use `public` or `private` in the
  # database, and resorted to `listed` and `hidden`. So `public` => `listed` as `private` => `hidden`
  # NOTE: visibility 0 means visible. (Yikes. How did this pass review?)
  enum visibility: { listed: 0, hidden: 1 }

  scope :search, -> (search) { where("signs.name ILIKE ?", "%#{search}%") if search.present? }
  scope :owned_by, -> (user) { joins(:sign_users).where('sign_users.user_id' => user.id) }
  # This is a bit of a doozy, but needed for getting visible signs & potentially private signs owned by the current user at the same time (Left Outer Join on sign_users)
  scope :visible_or_owned_by, -> (user) { eager_load(:sign_users).where("signs.visibility = ? OR sign_users.user_id = ?", 0, user.id) }

  validates :name, presence: true

  extend FriendlyId
  friendly_id :name, use: :slugged

  include PublicActivity::Common

  include OwnableModel

  alias_method :owners, :users

  def self.menus
    @_menus ||= Dir[Rails.root.join('app', 'views', 'signs', 'menus', '*.html.erb')].map {|f| f[/\/_(.*)\.html\.erb$/, 1]}.sort
  end

  def self.transitions
    @_transitions ||= ['fade', 'swipe', 'drop', 'rotate']
  end

  def playable_slides
    slides.shown.active.approved.ordered
  end

  def unexpired_slides
    sign_slides.unexpired
  end

  def directory_slides
    playable_slides.where('template ILIKE ?', '%directory%')
  end

  def menu
    template.to_s[/(\w+)(\.mustache)?$/, 1].underscore
  end

  def any_emergency?
    emergency? || panther_alert?
  end

  def emergency?
    [emergency, emergency_detail].any? do |field|
      !field.blank?
    end
  end

  def panther_alert?
    [panther_alert, panther_alert_detail].any? do |field|
      !field.blank?
    end
  end

  def touch_last_ping
    update_column(:last_ping, Time.zone.now)
  end

  def active?
    last_ping && (Time.zone.now - 8.seconds) <= last_ping  # The poll is every 5 seconds (3 second delay is fine)
  end

  # Alias methods generated by :visibility enum
  # alias_method doesn’t work here. I think there’s an issue with the enum field methods not
  # being defined yet in runtime.
  def public?() listed? end
  def private?() hidden? end
end