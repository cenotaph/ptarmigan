# -*- encoding : utf-8 -*-
class Admin::PostsController < InheritedResources::Base
  before_filter :authenticate_user!
  layout 'staff'
  has_scope :page, :default => 1

  def index
    @posts = Post.all
  end
  
  def show
    redirect_to post_path(:id => params[:id])
  end

end
