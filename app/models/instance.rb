class Instance < ActiveRecord::Base
  belongs_to :event
  belongs_to :place
  extend FriendlyId
  friendly_id :title_en, :use => [:slugged, :finders, :history]
  has_attached_file :specialimage, :styles => { :largest => "1280x800>", :medium => "400x400>",
                                       :thumb => "100x100>", :archive => "115x115#" },
        :path =>  ":rails_root/public/images/events/instances/:id/:style/:basename.:extension", 
        :url => "/images/events/instances/:id/:style/:basename.:extension"
  translates :special_information, :notes
  accepts_nested_attributes_for :translations, :reject_if => proc { |attributes| attributes['special_information'].blank? && attributes['notes'].blank? }
  validates_presence_of :event_id, :start_at, :end_at
  validates_attachment_content_type :specialimage, :content_type => ["image/jpg", "image/jpeg", "image/png", "image/gif"] 
  
  def as_json(options = {})
    {
      :id => self.id,
      :title => self.event.title,
      :description => self.special_information.blank? ? self.event.description : self.special_information,
      :start => start_at.rfc822,
      :end => end_at.nil? ? start_at.rfc822 : end_at.rfc822,
      :allDay => false, 
      :recurring => false,
      :url => self.title.blank? ? Rails.application.routes.url_helpers.event_path(self.event.slug) : 
        Rails.application.routes.url_helpers.event_instance_path(self.event.slug, self.title.parameterize)
      #:color => "red"
    }
  end
  
  def future?
    self.start_at >= Date.parse(Time.now.strftime('%Y/%m/%d'))
  end
  
  def title_en
       self.title.blank? ? self.id.to_s : self.title
  end
  
  def siblings
    event.instances.where(title: title)
  end
  
end
