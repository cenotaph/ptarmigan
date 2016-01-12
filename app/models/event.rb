# -*- encoding : utf-8 -*-
class Event < ActiveRecord::Base
  paginates_per 8
  extend FriendlyId
  friendly_id :title_en, :use => [:slugged, :finders, :history]
  has_many :instances
  belongs_to :location
  belongs_to :artist
  belongs_to :project
  belongs_to :subsite
  belongs_to :place
  has_many :videos, :dependent => :destroy
  has_many :flickers, :dependent => :destroy
  has_many :resources, :dependent => :destroy
  has_many :attendees, :dependent => :destroy
  has_and_belongs_to_many :eventcategories
  accepts_nested_attributes_for :eventcategories
  has_attached_file :avatar, :styles => { :larger => "350x350>", :medium => "400x400#",  :small => "240x240>",
                                       :thumb => "100x100>", :archive => "115x115#" },
        :path =>  ":rails_root/public/images/events/:id/:style/:basename.:extension", 
        :url => "/images/events/:id/:style/:basename.:extension", :default_url => "/assets/missing.png"

  has_attached_file :carousel, :styles => {:largest => "1583x454#", :new_carousel => "1180x338#", :full => "960x400#", :small => "320x92#", :thumb => "100x100>"}, 
  :path =>  ":rails_root/public/images/carousel/events/:id/:style/:basename.:extension", :url => "/images/carousel/events/:id/:style/:basename.:extension"
  translates :notes, :description, :title, fallbacks_for_empty_translations: true
  accepts_nested_attributes_for :translations, reject_if: proc { |attr| attr['title'].blank? || attr['description'].blank? }
  #has_many :translations
  scope :has_events_on, -> (*args) { where(['public is true and (date = ? OR (enddate is not null AND (date <= ? AND enddate >= ?)))', args.first, args.first, args.first] )}
  
  scope :in_month, -> (*args) { where( :public => 1,  :date => args.first.to_date.beginning_of_month..args.first.to_date.end_of_month ) }
  scope :future, -> () { where(['public is true AND date >= ?', Time.now.to_date]).order(:date) }
  scope :published,  -> () {where(:public => true) }
  scope :by_location, -> (x) { where(['location_id = ? AND (subsite_id is null OR show_on_main is true)', x])}
  scope :by_subsite, ->(subsite_id) { where(subsite_id: subsite_id) }
  validates_presence_of :location_id, :date, :place_id  
  validates_attachment_content_type :avatar, :content_type => ["image/jpg", "image/jpeg", "image/png", "image/gif"]
  validates_attachment_content_type :carousel, :content_type => ["image/jpg", "image/jpeg", "image/png", "image/gif"]
  alias_attribute :name, :title
  before_save :perform_avatar_removal
  before_save :extract_dimensions
  serialize :carousel_dimensions
  serialize :avatar_dimensions 
  after_save :remove_blank_translations
  attr_accessor :remove_avatar, :remove_carousel

  include PublicActivity::Model
  tracked owner: ->(controller, model) { controller.current_user }
  
  scope :between, -> (start_time, end_time) { 
    where( [ "(date >= ?  AND  enddate <= ?) OR ( enddate >= ? AND enddate <= ? ) OR (date >= ? AND date <= ?)  OR (date < ? AND enddate > ? )",
    start_time, end_time, start_time, end_time, start_time, end_time, start_time, end_time])
  }
  
  def is_festival?
    if instances.empty?
      return false
    elsif instances.map(&:title).delete_if(&:blank?).empty?
      return false
    else
      true
    end
  end
    
  
  def as_json(options = {})
    {
      :id => self.id,
      :title => self.title,
      :description => self.description || "",
      :start => date.rfc822,
      :end => enddate.nil? ? date.rfc822 : enddate.rfc822,
      :allDay => false, 
      :recurring => false,
      :url => Rails.application.routes.url_helpers.event_path(slug),
      #:color => "red"
    }

  end
  
  def carousel_image?
    carousel_content_type =~ %r{^(image|(x-)?application)/(bmp|gif|jpeg|jpg|pjpeg|png|x-png)$}
  end
  
  def avatar_image?
    avatar_content_type =~ %r{^(image|(x-)?application)/(bmp|gif|jpeg|jpg|pjpeg|png|x-png)$}
  end
  
  
  
  def one_day?
    if self.enddate.nil?
      return true
    else
      self.date.to_date == self.enddate.to_date
    end
  end
   
  def self.format_date(date_time)
    Time.at(date_time.to_i).to_formatted_s(:db)
  end
  
  def remove_blank_translations
    translations.each{|x| x.destroy if  x.title.nil? && x.description.nil? }
  end
    

  def icon
    avatar
  end
  
  def image
    carousel
  end

  def bordercss
    out = []
    eventcategories.each_with_index do |ec, index|
      next if index == 0
      out << "0 -#{(index)* 3}px 0 ##{ec.colour}"
    end
    "border-top-color: ##{eventcategories.first.colour}; box-shadow: " + out.join(',')
  end
  
  def begin_time
    [date, event_time].join(' ').to_time
  end
  
  def end_time
    [ enddate.blank? ?  date : enddate, '23:59'].join(' ').to_datetime
  end
  
  def carousel_link
    self
  end

  def carousel_date
    enddate.blank? ? [date.to_date] : [date.to_date, enddate.to_date]
  end

  def perform_avatar_removal 
    self.avatar = nil if self.remove_avatar=="1" && !self.avatar.dirty? 
    self.carousel = nil if self.remove_carousel== "1" && !self.carousel.dirty?
    true 
  end 
  
  def feed_date
    enddate.blank? ? date.to_time : enddate.to_time
  end

  # def end_time
  #   if self.notes.nil? || self.notes.match(/\d\d\:\d\d/).nil?
  #     (date.to_s + ' 22:30').to_datetime
  #   elsif self.notes.scan(/\d\d\:\d\d/).size > 1
  #     (self.date.to_s + " " + self.notes.scan(/\d\d\:\d\d/)[1]).to_datetime
  #   else
  #     DateTime.strptime((self.start_time.to_i + 10800).to_s, '%s')
  #   end
  # end
    
  def start_time
    if self.notes.nil? || self.notes.match(/\d\d\:\d\d/).nil?
      (date.to_s + ' 20:00').to_datetime
    else 
      (self.date.to_s + " " + self.notes.match(/\d\d\:\d\d/)[0]).to_datetime 
    end
  end
  
  def title_en
       self.title(:en).blank? ? self.translations.first.title : self.title(:en)
  end

  def title_with_date
    "#{self.title(:en)} (#{self.date.strftime('%d %b %Y')})"
  end
  
  
  def longer_title
    title_with_date + ", #{self.location.name}"
  end
  
  def future?
    self.date >= Date.parse(Time.now.strftime('%Y/%m/%d'))
  end
  
  
  def madhouse_season
    return false unless location_id == 4
    if date.year == 2014 
      1
    elsif date.year == 2015
      2
    elsif date.year == 2016
      if date.month < 9
        3
      else
        4
      end
    else
      false
    end
  end

  def rss_description(locale)
    out = ""
    if avatar?
      out += ActionController::Base.helpers.image_tag("http://ptarmigan.fi" + avatar.url(:medium)) 
    end
    out += "<p>#{I18n.l(feed_date.to_date, :format => :long)}</p>"
    out + description(locale)
  end

  def is_full?
    if registration_required
      if future?
        if registration_limit
          if registration_limit - self.attendees.delete_if{|x| x.waiting_list == true}.size.to_i <= 0
            return true
          else
            return false
          end
        else 
          return false
        end
      else 
        return false
      end
    else
      return false
    end
  end

  # def description(locale)
  #    if locale == 'fi'
  #      if description_fi.blank?
  #        return description_en
  #      else
  #        return description_fi
  #      end
  #    else
  #      return description_en
  #    end
  #  end
  #   
  # 
  #  def metadata(locale)
  #    if locale == 'fi'
  #      return metadata_fi
  #    else
  #      return metadata_en
  #    end
  #  end
  #  
  #  def local_promoter(locale)
  #    if locale.to_s == 'fi'
  #      return self.promoter + ' esittää'
  #    else
  #      return "presented by " + self.promoter
  #    end
  #  end
  #  
   # def price
   #   if self.cost.blank?
   #     return ""
   #   elsif self.cost == 0
   #     return :free
   #   else
   #     return self.cost
   #   #   unless self.discountedcost.blank?
   #   #     if self.discountedcost == 0
   #   #       return '&euro;' + sprintf("%0.2f", self.cost)  + ' (' + self.discountreason + ')'
   #   #     else
   #   #       return '&euro;' + sprintf("%0.2f", self.cost) + '; &euro;' + sprintf("%0.2f",(self.discountedcost.to_f ).to_s) + ' (' + self.discountreason + ')'
   #   #     end
   #   #   else
   #   #     return '&euro;' + sprintf("%0.2f", self.cost)
   #   #   end
   #   end
   # end
  
   private

   # Retrieves dimensions for image assets
   # @note Do this after resize operations to account for auto-orientation.
   def extract_dimensions
     if carousel_image?
       tempfile = carousel.queued_for_write[:original]
       unless tempfile.nil?
         geometry = Paperclip::Geometry.from_file(tempfile)
         self.carousel_dimensions = [geometry.width.to_i, geometry.height.to_i].join('x')
       end
     end
     if avatar_image?
       atmp = avatar.queued_for_write[:original]
       unless atmp.nil?
         geometry = Paperclip::Geometry.from_file(atmp)
         self.avatar_dimensions = [geometry.width.to_i, geometry.height.to_i].join('x')
       end
     end
   end

  
end
