# -*- encoding : utf-8 -*-
class Post < ActiveRecord::Base
  paginates_per 3
  extend FriendlyId
  friendly_id :title, :use => :history

  belongs_to :user
  belongs_to :location
  belongs_to :subsite

  has_attached_file :carousel, :styles => {:largest => "1200x492#", :new_carousel => "960x400#", 
                                          :full => "600x400>", :small => "300x200#",
                                          :thumb => "100x100>" },
                                          :path =>  ":rails_root/public/images/carousel/posts/:id/:style/:normalized_resource_file_name",
                                          :url =>  "/images/carousel/posts/:id/:style/:normalized_resource_file_name"

  translates :title, :body
  attr_accessible :translations,  :remove_carousel, :embed_above_post, :embed_gallery_id, :subsite_id, :show_on_main, :user_id, :carousel, :not_news, :is_personal, :location_id, :translations_attributes, :hide_carousel, :published
  accepts_nested_attributes_for :translations, :reject_if => proc { |attributes| attributes['title'].blank? && attributes['body'].blank? }
  scope :by_location, lambda {|x| {:conditions => ['location_id = ? AND (subsite_id is null OR show_on_main is true)', x]}}
  scope :by_subsite, lambda {|x| {:conditions => {:subsite_id => x} }}  
  scope :with_carousel, :conditions => ["hide_carousel is false AND carousel_file_name is not null AND carousel_file_size > 0" ]
  scope :not_news, :conditions => {:not_news => true}
  scope :news, :conditions  => {:not_news => false}
  scope :published, :conditions => {:published => true }
  validates_presence_of :location_id
  attr_accessor :remove_carousel
  before_validation { carousel.clear if remove_carousel == '1' }
  include PublicActivity::Model
  tracked owner: ->(controller, model) { controller.current_user }  
  Paperclip.interpolates :normalized_resource_file_name do |attachment, style|
    attachment.instance.normalized_resource_file_name
  end

  def carousel_link
    self
  end

  def carousel_date
    [created_at]
  end

  def description
    body
  end

  def rss_description(locale = :en)
    out = ""
    if carousel?
      out += ActionController::Base.helpers.image_tag("http://ptarmigan.fi" + carousel.url(:full)) 
    end
    out += "<p>#{I18n.l(feed_date.to_date, :format => :long)}</p>"
    out + body(locale)
    body(locale)
  end

  def feed_date
    created_at
  end

  def icon
    carousel
  end
  
  def image
    carousel
  end

  def normalized_resource_file_name
    "#{self.id}-#{self.carousel_file_name.gsub( /[^a-zA-Z0-9_\.]/, '_')}"
  end  
  def name
    title
  end

  
end
