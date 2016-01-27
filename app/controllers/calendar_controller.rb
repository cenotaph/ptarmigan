# -*- encoding : utf-8 -*-
class CalendarController < ApplicationController
#
#   def index
#     @period = [Time.now.strftime("%Y").to_i, Time.now.strftime('%m').to_i]
#   end
#
#   def update_calendar
#     @period = [params[:year], params[:month]]
#
#     render :layout => false, :template => 'calendar/index'
#   end
# end
  def index
    events = Event.where(nil)
    events = Event.by_location(@location.id).published.between(params['start'], params['end']) if (params['start'] && params['end'])
    @events = []
    @events += events.map(&:instances).flatten
    @events += events.reject{|x| !x.one_day? }

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @events }
    end
  end
  
  def show
    @event = Event.friendly.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @event }
    end
  end
    
end
