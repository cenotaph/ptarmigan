# -*- encoding : utf-8 -*-
class Admin::ChattersController < InheritedResources::Base
  layout 'staff'
  before_filter :authenticate_user!
  
  def index
    @chatters = Chatter.includes(:comments).sort_by{|x| x.latest }.reverse
  end
  
end
