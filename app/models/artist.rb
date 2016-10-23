# -*- encoding : utf-8 -*-
class Artist < ActiveRecord::Base
  paginates_per 8
  extend FriendlyId
  friendly_id :name, :use => :history
  has_many :events
  has_attached_file :avatar, :styles => { :new_carousel => "960x400#", :medium => "400x400>", :thumb => "100x100>" },
                                 :url =>':s3_domain_url',
                               path:  "artists/:id/:style/:basename.:extension", :default_url => "/assets/missing.png"
                               
  has_attached_file :carousel, :styles => {:largest => "1180x492#", :new_carousel => "960x400#", :full => "600x400#", :small => "300x200#", :thumb => "100x100>"}, 
                                :url =>':s3_domain_url',
                               path: "carousel/artists/:id/:style/:basename.:extension", :default_url => "/assets/missing.png"
  has_many :resources
  belongs_to :location
  translates :bio
  accepts_nested_attributes_for :translations, :reject_if => proc { |attributes| attributes['bio'].blank? }
  validates_presence_of :name, :location_id, :startdate, :enddate, :country
  scope :by_location, -> (x) { where(location_id: x)}
  scope :current, -> () { where(["enddate >= ?", Time.now.strftime('%Y-%m-%d')] )}
  scope :with_carousel,  -> () { where(["carousel_file_name is not null AND carousel_file_size > 0" ] )}
  before_save :perform_avatar_removal 
  attr_accessor :remove_avatar, :remove_carousel
  # attr_accessible :remove_avatar, :remove_carousel, :include_in_carousel, :location_id, :startdate, :enddate, :name, :country, :website1, :website2, :translations_attributes, :avatar, :carousel
  
  include PublicActivity::Model
  tracked owner: ->(controller, model) { controller.current_user }


  def icon
    avatar
  end
  
  def carousel_date
    dates_of_stay
  end

  def image
    carousel
  end

  def carousel_link
    self
  end

  def dates_of_stay
    [startdate, enddate]
  end
  
  def description
    bio
  end
  
  def perform_avatar_removal 
    self.avatar = nil if self.remove_avatar=="1" && !self.avatar.dirty? 
    self.carousel = nil if self.remove_carousel== "1" && !self.carousel.dirty?
    true 
  end   
  
end
