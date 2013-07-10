# -*- encoding : utf-8 -*-
class PagesController < ApplicationController

  before_filter :find_page



  def air
    if applicant_in?
      @airforms = Airform.find_all_by_applicant_id(current_applicant.id)
    end
  end
  
  def frontpage
    set_meta_tags :open_graph => {
      :title => (@subsite.nil? ? "" : (@subsite.human_name.blank? ? "#{@subsite.name} | " : "#{@subsite.human_name} | ")) + "Ptarmigan" ,
      :type  => "ptarmigan:article",
      :url   =>   'http://' + (@subsite.nil? ? 'www.' : 'donekino.') + 'ptarmigan.' + @location.locale },
      :canonical =>  'http://www.ptarmigan.' + @location.locale,
      :keywords => 'Helsinki,Finland,Tallinn,Estonia,Ptarmigan,culture,art,workshops,artist-run,project space,maker culture, DIY,experimental, avant-garde, music, sound, visual art, Tiib,Baltic,residency',
      :description => 'Ptarmigan is a cultural platform in ' + (@location.locale == 'fi' ? "Helsinki, Finland" : "Tallinn, Estonia."),
      :title => nil
    @upcoming = Event.published.future.where(:hide_from_front => false).where("subsite_id is null OR show_on_main = true")
    @carousel = []
    @upcoming.reject{|x| !x.carousel? }.each {|x| @carousel << x }
    
    @carousel <<  Project.by_location(@location.id).with_carousel.order('rand()').first
   
    Artist.by_location(@location.id).current.with_carousel.order.each {|x| @carousel << x }

    # @artists = Artist.by_location(@location.id).all(:order => 'startdate DESC', :limit => 3)
    
    # @flickrwall = []
    # @flickrwall = Flicker.find_by_sql("select * from (select * from flickers where image_file_name is not null and image_file_size > 0 order by rand()) as t group by event_id order by rand() limit 28")

    @new_carousel = Flicker.includes(:event).where(:include_in_carousel => true).where("events.location_id = ?", @location.id).group("events.id")
    # @new_carousel = Flicker.find_by_sql("select * from flickers, events  where events.id = flickers.event_id and events.location_id = 1 and image_file_name is not null and include_in_carousel is true and image_file_size > 0 order by rand()").group_by{|x| x.event_id }.map(&:last).flatten

    
    @new_carousel = @new_carousel.sort_by{ rand }[0..5]

    @about = Page.find_by_slug('about')
    @where = Page.by_location(@location.id).where(:slug => 'where').first

    projects = Project.by_location(@location.id).where(:include_in_carousel => true)
    unless projects.empty?
      projects.each {|x| @new_carousel.unshift(x) }
    end

    events = Event.by_location(@location.id).future.delete_if{|x| !x.carousel? }
    unless events.empty?
      events.sort_by{rand}.each do |e|
        @new_carousel.unshift(e)
      end
    end


    
    @artist = Artist.current
    unless @artist.empty?
      @new_carousel.unshift(@artist.first)
    end

    Post.by_location(@location.id).with_carousel.published.each {|x| @new_carousel.unshift(x) }

    carousel = @carousel.reverse
    if @subsite
      @posts = Post.by_subsite(@subsite).published.order('created_at DESC').page params[:page]
    else
      @posts = Post.by_location(@location.id).published.news.order('created_at DESC').page params[:page]
    end
    @new_carousel = @new_carousel[0..14]
    respond_to do |format|
      format.html { render :layout => 'frontpage'}
      format.xml  { render :xml => @page }
    end
    
  end
  
  def press
    resources = Resource.where(["((location_id is null OR location_id = ?) OR all_locations is true)", @location.id])
    @pagelinks = Presslink.where(["((location_id is null OR location_id = ?) OR all_locations is true)", @location.id]).order("sortorder, presslinks.when DESC")
    @resources = resources.reject{|x| x.press_page != true}
    @other_resources = resources.delete_if{|x| x.item_location != @location}
  end


  def show
    set_meta_tags :open_graph => {
      :title => (@subsite.nil? ? "" : (@subsite.human_name.blank? ? "#{@subsite.name} : " : "#{@subsite.human_name} : ")) + @page.title + " | Ptarmigan" ,
      :type  => "ptarmigan:article",
      :url   =>  url_for(@page)},
      :canonical =>  url_for(@page),
      :keywords => 'Helsinki,Finland,Tallinn,Estonia,Ptarmigan,proposals,application,residency,culture,art',
      :description => @page.description,
      :title => (@subsite.nil? ? "" : (@subsite.human_name.blank? ? "#{@subsite.name} : " : "#{@subsite.human_name} : ")) +  @page.title.humanize
    if params[:id] == 'about' && @subsite.nil?
      @who_we_are = Page.by_location(@location.id).where(:slug => 'who_we_are').first
      @resources = Resource.where(["press_page is true AND ((location_id is null OR location_id = ?) OR all_locations is true)", @location.id])
      @pagelinks = Presslink.where(["((location_id is null OR location_id = ?) OR all_locations is true)", @location.id]).order("sortorder, presslinks.when DESC")
      @contact = Page.where(:slug => 'contact').first
      render :template => 'pages/about'
    else
      respond_to do |format|
        format.html
        format.xml  { render :xml => @page }
      end
    end
  end


  private

  def find_page
    if @subsite.nil?
      @page = Page.where(:slug => params[:id]).where(:location_id => @location.id).where(:subsite_id => nil).first if params[:id]
    else
      if params[:id]
        @page = Page.where(:slug => params[:id]).where(:location_id => @location.id).where(:subsite_id => @subsite.id)
        if @page.blank?
          @page = Page.find(params[:id])
        else
          @page = @page.first
        end
      end  
    end
  end

end
