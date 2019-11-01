require 'carrierwave/orm/activerecord'
# require "mini_magick"
# require 'ImageResize'
class EventsController < ApplicationController
   before_action :set_event, only: [:show, :update, :destroy]
    # skip_before_action :authenticate_request, only: %i[vital_event_name]
      
   # GET /events
  def index
    if params[:event_type].present?
            model_fields = Event.attribute_names
            data = params[:data].present? ? params[:data] : model_fields
            page_count = params[:per_page].present? ? params[:per_page] : "10"
            page = params[:page].present? ? params[:page] : "1"
            sort = params[:sort].present? && model_fields.include?(params["sort"]) ? params[:sort] : "created_at"
            order_types = ["asc", "desc", "ASC", "DESC"]
            order_by = params[:order].present? && order_types.include?(params["order"]) ? params[:order] : "DESC"
            filters = { "data" =>data,"per_page"=> page_count,"page"=> page,"sort"=>sort,"order"=>order_by }
      if (current_user.role_id == 1)
        if (params[:event_type] == "appointment")
          if params[:tab].present? && (params[:tab] == "history")
            if params[:search].present?
              @event_lists = Event.select(data).where(user_id: current_user.id, event_type: "appointment").where("event_datetime < ?", DateTime.now).search(params[:search]).order(sort => order_by).paginate(:page => page, :per_page => page_count)
            else
              @event_lists = Event.select(data).where(user_id: current_user.id, event_type: "appointment").where("event_datetime < ?", DateTime.now).order(sort => order_by).paginate(:page => page, :per_page => page_count)
            end
          else
            if params[:search].present?
              @event_lists = Event.select(data).where(user_id: current_user.id, event_type: "appointment").where("event_datetime >= ?", DateTime.now).search(params[:search]).order(sort => order_by)
            else
              @event_lists = Event.select(data).where(user_id: current_user.id, event_type: "appointment").where("event_datetime >= ?", DateTime.now).order(sort => order_by).paginate(:page => page, :per_page => page_count)
            end
          end
        else
          if params[:search].present?
            @event_lists = Event.select(data).where(user_id: current_user.id, event_type: params[:event_type]).search(params[:search]).order(sort => order_by)
          else
            @event_lists = Event.select(data).where(user_id: current_user.id, event_type: params[:event_type]).order(sort => order_by).paginate(:page => page, :per_page => page_count)
          end  
        end
      elsif (current_user.role_id == 2)
        if params[:user_id].present?
          if (params[:event_type] == "appointment")
            if params[:tab].present? && (params[:tab] == "history")
              if params[:search].present?
                @event_lists = Event.select(data).where(user_id: params[:user_id], event_type: "appointment").where("event_datetime < ?", DateTime.now).search(params[:search]).order(sort => order_by)
              else
                @event_lists = Event.select(data).where(user_id: params[:user_id], event_type: "appointment").where("event_datetime < ?", DateTime.now).order(sort => order_by).paginate(:page => page, :per_page => page_count)
              end
            else
              if params[:search].present?
                @event_lists = Event.select(data).where(user_id: params[:user_id], event_type: "appointment").where("event_datetime >= ?", DateTime.now).search(params[:search]).order(sort => order_by)
              else
                @event_lists = Event.select(data).where(user_id: params[:user_id], event_type: "appointment").where("event_datetime >= ?", DateTime.now).order(sort => order_by).paginate(:page => page, :per_page => page_count)
              end
            end
          else
            if params[:search].present?
              @event_lists = Event.select(data).where(user_id: params[:user_id], event_type: params[:event_type]).search(params[:search]).order(sort => order_by)
            else
              @event_lists = Event.select(data).where(user_id: params[:user_id], event_type: params[:event_type]).order(sort => order_by).paginate(:page => page, :per_page => page_count)
            end
          end
        else
          patient_id = UserAssociation.find_by(caregiver_id: current_user.id).patient_id
          if (params[:event_type] == "appointment")
            if params[:tab].present? && (params[:tab] == "history")
              if params[:search].present?
                @event_lists = Event.select(data).where(user_id: patient_id, event_type: "appointment").where("event_datetime < ?", DateTime.now).search(params[:search]).order(sort => order_by)
              else
                @event_lists = Event.select(data).where(user_id: patient_id, event_type: "appointment").where("event_datetime < ?", DateTime.now).order(sort => order_by).paginate(:page => page, :per_page => page_count)
              end
            else
              if params[:search].present?
                @event_lists = Event.select(data).where(user_id: patient_id, event_type: "appointment").where("event_datetime >= ?", DateTime.now).search(params[:search]).order(sort => order_by)
              else
                @event_lists = Event.select(data).where(user_id: patient_id, event_type: "appointment").where("event_datetime < ?", DateTime.now).order(sort => order_by).paginate(:page => page, :per_page => page_count)
              end
            end
          else
            if params[:search].present?
              @event_lists = Event.select(data).where(user_id: patient_id, event_type: params[:event_type]).search(params[:search]).order(sort => order_by)
            else
              @event_lists = Event.select(data).where(user_id: patient_id, event_type: params[:event_type]).order(sort => order_by).paginate(:page => page, :per_page => page_count)
            end
          end
        end
      end
      render json: { event_list: @event_lists, filters: filters, count: @event_lists.to_a.count }, status: :ok
    else
      @event_type = EnumMaster.where(category_name: "event_type").pluck(:name).uniq
      render json: { message: 'Event Type should be given' , EventTypes: @event_type }, status: :unauthorized
    end
  end

   # POST events/diary_recording
    def diary_recording
      if params[:user_id].present?
        if params[:from_date].present? && params[:end_date].present?
          diary_records = Event.where(user_id: params[:user_id], event_type: params[:event_type], created_at: params[:from_date].to_date.beginning_of_day...params[:end_date].to_date.end_of_day).order('created_at DESC').paginate(:page => params[:page], :per_page => params[:per_page])
          render json: { diary_records: diary_records }, status: :ok
        else
          diary_records = Event.where(user_id: params[:user_id], event_type: params[:event_type]).order('created_at DESC').paginate(:page => params[:page], :per_page => params[:per_page])
          render json: { diary_records: diary_records }, status: :ok
        end        
      end
    end

    # POST /events
    def create
        event_assets = params[:event_assets]
          @event = Event.new(event_name: params[:event_name], description: params[:description], value: params[:value], event_datetime: params[:event_datetime], event_type: params[:event_type], event_category: params[:event_category], event_assets: [event_assets], event_options: params[:event_options], user_id: current_user.id)
          if @event.save
            render json: @event, status: :created, location: @event
          else
            render json: @event.errors.messages, status: :unprocessable_entity
          end
    end

    # POST /events/update_image (For upload the multiple image)
    def update_image
      if params[:id].present?
        event_assets = params[:event_assets]
        event = Event.find(params[:id])
        array = event.event_assets
        image = array.push(event_assets)
        image_update = event.update(event_assets: image)
        render json: { message: "Images are updated Successfully" }, status: :ok
      else
        render json: { message: "Give the Event ID" }, status: :unprocessable_entity      
      end
    end

    # POST /events/delete_image (For deleting the Images)
    def delete_image
      if params[:id].present?
        if params[:index].present?
          event = Event.find(params[:id])
          array = event.event_assets
          img = array.reject.with_index { |e, i| params[:index].include? i }
          delete_update = event.update(event_assets: img)
          render json: { message: "Image Deleted Successfully" }, status: :ok
        else
          render json: { message: "Give the Index" }, status: :unprocessable_entity
        end
      else
        render json: { message: "Give the Event ID" }, status: :unprocessable_entity
      end
    end

    # GET events/expense_calculation
    def expense_calculation
      if params[:user_id].present?
        join_month = User.find(params[:user_id]).created_at
        first_month = Date.today.beginning_of_year.end_of_month.end_of_day
        if (join_month <= first_month)
          current_month_exp = "%.2f" % Event.where(event_type: "expense", user_id: params[:user_id], event_datetime: Time.now.beginning_of_month..Time.now.end_of_day).pluck(:value).map(&:to_i).sum #.to_f #.round(2)
          @current_month_exp = ActionController::Base.helpers.number_to_currency(current_month_exp, :unit => "")
          first_day = Date.current.beginning_of_year
          today = Time.now
          no_of_months = (today.year * 12 + today.month) - (first_day.year * 12 + first_day.month)
          # no_of_days = (today - first_day).to_i

          year_exp = Event.where(event_type: "expense", user_id: params[:user_id], event_datetime: first_day..today).pluck(:value).map(&:to_i).sum #.to_f #.round(2)
          yearly_exp = '%.2f' % year_exp
          @yearly_exp = ActionController::Base.helpers.number_to_currency(yearly_exp, :unit => "")

          month_projection = (year_exp / no_of_months).round(2)  #.to_f
          @monthly_projection = '%.2f' % month_projection

          year_projection = (month_projection * 12).round(2) #.to_f
          @yearly_projection = '%.2f' % year_projection
          render json: { CurrentMonth: @current_month_exp, Yearly: @yearly_exp, MonthProjection: @monthly_projection, YearlyProjection: @yearly_projection, status: true }, status: :ok
        else
          current_month_exp = "%.2f" % Event.where(event_type: "expense", user_id: params[:user_id], event_datetime: Time.now.beginning_of_month..Time.now.end_of_day).pluck(:value).map(&:to_i).sum #.to_f #.round(2)
          @current_month_exp = ActionController::Base.helpers.number_to_currency(current_month_exp, :unit => "")

          first_day = Date.current.beginning_of_year
          today = Time.now
          no_of_months = (today.year * 12 + today.month) - (first_day.year * 12 + first_day.month)
          # no_of_days = (today - first_day).to_i

          year_exp = Event.where(event_type: "expense", user_id: params[:user_id], event_datetime: first_day..today).pluck(:value).map(&:to_i).sum #.to_f #.round(2)
          yearly_exp = '%.2f' % year_exp
          @yearly_exp = ActionController::Base.helpers.number_to_currency(yearly_exp, :unit => "")

          render json: { CurrentMonth: @current_month_exp, Yearly: @yearly_exp, status: false }, status: :ok
        end
      else
        render json: { message: "Give the user_id" }, status: :unprocessable_entity
      end
    end


    # GET events/expense_cals_chart
    def expense_cals_chart
      if params[:user_id].present?

        cm_from_date = Time.now.beginning_of_month.to_date.beginning_of_day
        cm_end_date = Time.now.end_of_day

        current = Event.where(:event_type => "expense", user_id: params[:user_id], event_datetime: cm_from_date...cm_end_date).select(:id, :event_name, :event_datetime, :value).order('event_datetime DESC').group_by{|i| i.event_datetime.to_date}

        cm_ans = current.each{|k, v| current[k] = v.sort_by(&:"event_name").group_by{|i| i.event_datetime.to_date}}

        current_month = cm_ans.each do |k, v|
            arr = []
            v.each do |i, j|
              arr << {event_datetime: i, value: j.pluck(:value).map(&:to_i).sum, data: j.group_by(&:event_name).map{|en, dt| [en, dt.pluck(:value).map(&:to_i).sum]}}
            end
            cm_ans[k] = arr
        end

        cy_from_date = Date.current.beginning_of_year.beginning_of_day
        cy_end_date = Time.now.end_of_day

        yr = Event.where(event_type: "expense", user_id: params[:user_id], event_datetime: cy_from_date...cy_end_date).select(:id, :event_name, :event_datetime, :value).order('event_datetime DESC').group_by{ |t| t.event_datetime.strftime("%B")}

        cy_ans = yr.each{|k, v| yr[k] = v.sort_by(&:"event_name").group_by{|i| i.event_datetime.strftime("%B")}}

        year = cy_ans.each do |k, v|
          arr = []
          v.each do |i, j|
            arr << {event_datetime: i, value: j.pluck(:value).map(&:to_i).sum, data: j.group_by(&:event_name).map{|en,dt| [en, dt.pluck(:value).map(&:to_i).sum]}}
          end
          cy_ans[k] = arr
        end

        # total_year = Event.where(event_type: "expense", user_id: params[:user_id], event_datetime: cy_from_date...cy_end_date)
        total_value = Event.where(event_type: "expense", user_id: params[:user_id], event_datetime: cy_from_date...cy_end_date).pluck(:value).map(&:to_i).sum

        if cy_from_date.strftime('%Y') == cy_end_date.strftime('%Y')
          c_year = cy_from_date.strftime('%Y') && cy_end_date.strftime('%Y')
          total_year = []
          total_year << {year: c_year, value: total_value }
        end

        render json: { Currentmonth: current_month, Year: year, Totalyear: total_year }, status: :ok # Lastmonth: last_month, 
      else
        render json: { message: "Give the user_id" }, status: :unprocessable_entity
      end
    end

    # Get /events/expense_chart_filter
    def expense_chart_filter
      if params[:user_id].present?
        from_date = params[:from_date].to_date.beginning_of_day
        end_date = params[:end_date].to_date.end_of_day
        if params[:event_name].present?
          expense_name = Event.where(:event_type => "expense", user_id: params[:user_id], event_datetime:from_date...end_date, :event_name => params[:event_name]).select(:id, :event_name, :event_datetime, :value, :updated_at).order('event_datetime DESC').group_by{|i| i.event_name}
          ans = expense_name.each{|k, v| expense_name[k] = v.group_by{|i| i.event_datetime.to_date}}
          expense = ans.each do |k, v|
             arr = []
             v.each do |i, j|
                 arr << {event_datetime: i, value: j.pluck(:value).map(&:to_i).sum}
              end
             ans[k] = arr
          end
          render json: {expense: expense, from_date: from_date.to_date, end_date: end_date.to_date}, status: :ok
        else
          expense_names = Event.where(event_type: "expense", user_id: params[:user_id]).pluck(:event_name).uniq
          expense_name = Event.where(:event_type => "expense", user_id: params[:user_id], event_datetime:from_date...end_date, :event_name => expense_names).select(:id, :event_name, :event_datetime, :value, :updated_at).order('event_datetime DESC').group_by{|i| i.event_name}
          ans = expense_name.each{|k, v| expense_name[k] = v.group_by{|i| i.event_datetime.to_date}}
          expense = ans.each do |k, v|
             arr = []
             v.each do |i, j|
                 arr << {event_datetime: i, value: j.pluck(:value).map(&:to_i).sum}
              end
             ans[k] = arr
          end
          render json: {expense: expense, from_date: from_date.to_date, end_date: end_date.to_date}, status: :ok
        end
      else
        render json: { errors: "Give the user_id" }, status: :unprocessable_entity
      end
    end

    # GET /events/expense_list
    def expense_list
      if params[:user_id].present?
        from_date = params[:from_date].present? ? params[:from_date].to_date.beginning_of_day : (Date.today - 30.days).beginning_of_day
        end_date = params[:end_date].present? ? params[:end_date].to_date.end_of_day : Date.today.end_of_day 

        data = Event.select(:id, :event_name, :value, :description, :event_datetime, :created_at, :updated_at).where(event_type: "expense", user_id: params[:user_id], event_datetime: from_date..end_date).order('event_datetime DESC').map {|ind| [id: ind.id,event_name: ind.event_name, description: ind.description, value: ind.value.to_i, event_datetime: ind.event_datetime, created_at: ind.created_at, updated_at: ind.updated_at]}
        data.flatten!

        expense = data.group_by{|h| h[:event_name]}
        
        render json: {expense: expense, from_date: from_date.to_date, end_date: end_date.to_date}, status: :ok
      else
        render json: { errors: "Give the user_id" }, status: :unprocessable_entity
      end
      
    end
   
    # GET /events/expense_chart
    def expense_chart
      if params[:user_id].present?
        from_date = Time.now.beginning_of_month.to_date.beginning_of_day
        end_date = Time.now.end_of_day

        named_events = Event.where(:event_type => "expense", user_id: params[:user_id], event_datetime:from_date...end_date).select(:id, :event_name, :event_datetime, :value, :updated_at).order('event_datetime DESC').group_by{|i| i.event_name}

        ans = named_events.each{|k, v| named_events[k] = v.group_by{|i| i.event_datetime.to_date}}

        expense = ans.each do |k, v|
           arr = []
           v.each do |i, j|
               arr << {event_datetime: i, value: j.pluck(:value).map(&:to_i).sum } #, data: j.pluck(:event_name, :value)}
            end
           ans[k] = arr
        end

        render json: expense, status: :ok
      else
        render json: { errors: "Give the user_id" }, status: :unprocessable_entity
      end
    end


    # POST /events/vitals_list_filter
    def vitals_list_filter
      if params[:user_id].present?
        from_date = params[:from_date].to_date.beginning_of_day
        end_date = params[:end_date].to_date.end_of_day
        if params[:event_name].present?
          named_events = Event.where(event_name: params[:event_name], event_type: "vital", user_id: params[:user_id], event_datetime: from_date...end_date).order('event_datetime DESC').group_by(&:event_name)
          named_events.each do |k, v|
              named_events[k] = v.group_by{|event| event.event_datetime.to_date}
              named_events[k].each do |dat, val|
                named_events[k][dat] = val.group_by(&:event_category)
              end
          end
          render json: {vitals: named_events, from_date: from_date, end_date: end_date}, status: :ok
        else
          vital_names = Event.where(event_type: "vital", user_id: params[:user_id]).pluck(:event_name).uniq
          named_events = Event.where(event_name: vital_names, event_type: "vital", user_id: params[:user_id], event_datetime: from_date...end_date).order('event_datetime DESC').group_by(&:event_name)
          named_events.each do |k, v|
              named_events[k] = v.group_by{|event| event.event_datetime.to_date}
              named_events[k].each do |dat, val|
                named_events[k][dat] = val.group_by(&:event_category)
              end
          end
          render json: {vitals: named_events, from_date: from_date.to_date, end_date: end_date.to_date}, status: :ok
        end
      else
        render json: { errors: "Give the user_id" }, status: :unprocessable_entity
      end
    end




    # DELETE events/vital_delete
    def vital_delete
      if params[:user_id].present?
        event = Event.where(id: params[:id],user_id: params[:user_id])
        event.delete_all
        render json: true
      else
        render json: false
      end
    end



# def vitals_list
# if params[:user_id].present?
# events = Event.select(:id,:event_name,:event_datetime,:event_category,:event_options).where(event_type: "vital", user_id: params[:user_id], event_datetime: Date.today.beginning_of_month...Date.today.end_of_day).order('event_datetime DESC')
# event_list = []
# event_list = events.pluck(:event_name).concat(["pluse_rate","HbA1c"]).uniq
# sample_data = {}
# event_list.each {|i| sample_data[i] = [] }

# events.each do |i|
#   sample_data[i.event_name].push({date: i.event_datetime.to_date,event_time: i.event_category, event_options: i.event_options})
# end


# sample_data["Blood Pressure"].each {|i| sample_data["pluse_rate"].push(sample_data["Blood Pressure"].delete(i)) if i[:event_options].keys.include?("value3") } if sample_data["Blood Pressure"]

# sample_data["Blood Glucose"].each {|i| sample_data["HbA1c"].push(sample_data["Blood Glucose"].delete(i)) if i[:event_options].keys.include?("value3") } if sample_data["Blood Glucose"]

#  render json: sample_data, status: :ok

# else
# render json: { errors: "Give the user_id" }, status: :unprocessable_entity
# end
# end

 # POST events/vital_update
  def vital_update
    # if params[:user_id].present?
    if (params[:event_name] == "Cholesterol")
      vital_data = Event.where(event_name: params[:event_name], event_type: "vital", event_datetime: params[:event_datetime].to_date.beginning_of_day...params[:event_datetime].to_date.end_of_day, user_id: current_user.id)
      if vital_data.present?
        event_vital = vital_data.update(event_datetime: params[:event_datetime], description: params[:description], event_category: params[:event_category], event_options: params[:event_options])
        vital = vital_data
      else
        vital = Event.create(event_name: params[:event_name], description: params[:description], value: params[:value], event_datetime: params[:event_datetime], event_type: params[:event_type], event_category: params[:event_category], event_options: params[:event_options], user_id: current_user.id)  # event_assets: [event_assets], 
      end
    else
      vital_data = Event.where(event_name: params[:event_name], event_category: params[:event_category], event_type: "vital", event_datetime: params[:event_datetime].to_date.beginning_of_day...params[:event_datetime].to_date.end_of_day, user_id: current_user.id)
      if vital_data.present?
        event_vital = vital_data.update(event_datetime: params[:event_datetime], description: params[:description], event_options: params[:event_options])
        vital = vital_data
      else
        vital = Event.create(event_name: params[:event_name], description: params[:description], value: params[:value], event_datetime: params[:event_datetime], event_type: params[:event_type], event_category: params[:event_category], event_options: params[:event_options], user_id: current_user.id)  # event_assets: [event_assets], 
      end      
    end
     #  vital_data = Event.find_by(event_name: params[:event_name], event_category: params[:event_category], event_type: "vital", event_datetime: params[:event_datetime].to_date.beginning_of_day...params[:event_datetime].to_date.end_of_day, user_id: current_user.id)
     # if vital_data.present?
     #  if (vital_data.event_name == "Cholesterol") # (params[:event_name] == "Cholesterol")#
     #    event_vital = vital_data.update(event_datetime: params[:event_datetime], description: params[:description], event_category: params[:event_category], event_options: params[:event_options])
     #    vital = vital_data
     #  else
     #    event_vital = vital_data.update(event_datetime: params[:event_datetime], description: params[:description], event_options: params[:event_options])
     #    vital = vital_data
     #  end
     #  else
     #    vital = Event.create(event_name: params[:event_name], description: params[:description], value: params[:value], event_datetime: params[:event_datetime], event_type: params[:event_type], event_category: params[:event_category], event_options: params[:event_options], user_id: current_user.id)  # event_assets: [event_assets],          
     #  end
      render json: vital, status: :ok
     
    # else
      # render json: { errors: "Give the user_id" }, status: :unprocessable_entity
    # end
  end

#------------------------------------------- Vitals Tables APIs Starts ----------------------------------------------------------------------------------

  # GET events/event_name_list
  def event_name_list
    if params[:user_id].present? && params[:event_type].present?
      from_date = params[:from_date].present? ? params[:from_date].to_date.beginning_of_day : DateTime.now.beginning_of_month
      end_date = params[:end_date].present? ? params[:end_date].to_date.end_of_day : DateTime.now.end_of_day
      event_name_list = Event.where(event_datetime: from_date...end_date, user_id: params[:user_id], event_type: params[:event_type]).pluck(:event_name).uniq
      render json: event_name_list, status: :ok
    else
      render json: { errors: "Give the user_id" }, status: :unprocessable_entity
    end
  end

  # POST events/vitals_list1
  def vitals_list1
    if params[:user_id].present?
      from_date = params[:from_date].present? ? params[:from_date].to_date.beginning_of_day : DateTime.now.beginning_of_month
      end_date = params[:end_date].present? ? params[:end_date].to_date.end_of_day : DateTime.now.end_of_day
      v_name = EnumMaster.where(category_name: "vital").pluck(:name)
      vital_name = params[:event_name].present? ? params[:event_name] : v_name #["Body Temperature", "Oxygen Saturation"]
      named_events = Event.select(:event_datetime, :event_category, :event_options, :user_id, :event_name).where(event_name: vital_name,event_type: "vital", user_id: params[:user_id], event_datetime: from_date...end_date).order('event_datetime DESC').group_by(&:event_name)
        named_events.each do |k, v|
          named_events[k] = v.group_by{|event| event.event_datetime.to_date}
          named_events[k].each do |dat, val|
            named_events[k][dat] = val.group_by(&:event_category)
          end
        end
      render json: named_events, status: :ok
    else
      render json: { errors: "Give the user_id" }, status: :unprocessable_entity
    end
  end

  # POST events/vitals_lis2
  def vitals_list2
    if params[:user_id].present?
      from_date = params[:from_date].present? ? params[:from_date].to_date.beginning_of_day : DateTime.now.beginning_of_month
      end_date = params[:end_date].present? ? params[:end_date].to_date.end_of_day : DateTime.now.end_of_day
      vital_name = params[:event_name].present? ? params[:event_name] : ["Blood Pressure", "Blood Glucose", "Cholesterol" ]
      data = Event.where(event_name: vital_name, event_type: "vital", user_id: params[:user_id], event_datetime: from_date...end_date).select(:id, :event_datetime, :event_category, :event_options, :user_id).order('event_datetime DESC').group_by{|event| event.event_datetime.to_date}
      # some = []
      # data.each do |k, data|
      #   some.push({k=>data.group_by(&:event_category)})
      # end
      # hai = some.reduce { |acc, h| (acc || {}).merge h }
      # #hai = some.flatten.group_by { |d|  d[:type] }
      # render json: hai
      ans = data.each{|k,v| data[k] = v.group_by{|i| i.event_category}}
      render json: ans
    else
      render json: { errors: "Give the user_id" }, status: :unprocessable_entity
    end
  end

#--------------------------------------------- Vitals Tables APIs Ends --------------------------------------------------------------------------


#-----------------Unwanted API-----------------
  #  def hb1ac
  #   if params[:user_id].present?
  #     from_date = params[:from_date].present? ? params[:from_date].to_date.beginning_of_day : DateTime.now.beginning_of_month
  #     end_date = params[:end_date].present? ? params[:end_date].to_date.end_of_day : DateTime.now.end_of_day
  #     data = Event.where(event_name: "Blood Glucose", event_type: "vital", user_id: params[:user_id], event_datetime: from_date...end_date).select(:event_datetime, :event_category, :event_options, :user_id).group_by{|event| event.event_datetime.to_date}
  #     some = []
  #     data.each do |k, data|
  #        some.push({k=>data.group_by(&:event_category)})
  #     end
  #     hai = some.reduce { |acc, h| (acc || {}).merge h }
  #     #hai = some.flatten.group_by { |d|  d[:type] }
  #     render json: hai
  #   else
  #     render json: { errors: "Give the user_id" }, status: :unprocessable_entity
  #   end
  #  end


  # def blood_pressure
  #  if params[:user_id].present?
  #   from_date = params[:from_date].present? ? params[:from_date].to_date.beginning_of_day : DateTime.now.beginning_of_month
  #   end_date = params[:end_date].present? ? params[:end_date].to_date.end_of_day : DateTime.now.end_of_day
  #   data = Event.where(event_name: "Blood Pressure", event_type: "vital", user_id: params[:user_id], event_datetime: from_date...end_date).select(:event_datetime, :event_category, :event_options, :user_id).group_by{|event| event.event_datetime.to_date}
  #   some = []
  #   data.each do |k, data|
  #      some.push({k=>data.group_by(&:event_category)})
  #   end
  #   hai = some.reduce { |acc, h| (acc || {}).merge h }
  #   #hai = some.flatten.group_by { |d|  d[:type] }
  #   render json: hai
  #  else
  #   render json: { errors: "Give the user_id" }, status: :unprocessable_entity
  #  end
  # end

  
  # def cholesterol
  #   if params[:user_id].present?
  #     from_date = params[:from_date].present? ? params[:from_date].to_date.beginning_of_day : DateTime.now.beginning_of_month
  #     end_date = params[:end_date].present? ? params[:end_date].to_date.end_of_day : DateTime.now.end_of_day
  #     data = Event.where(event_name: "Cholesterol", event_type: "vital", user_id: params[:user_id], event_datetime: from_date...end_date).select(:event_datetime, :event_category, :event_options, :user_id).group_by{|event| event.event_datetime.to_date}
  #     some = []
  #     data.each do |k, data|
  #        some.push({k=>data.group_by(&:event_category)})
  #     end
  #     hai = some.reduce { |acc, h| (acc || {}).merge h }
  #     #hai = some.flatten.group_by { |d|  d[:type] }
  #     render json: hai
  #   else
  #     render json: { errors: "Give the user_id" }, status: :unprocessable_entity
  #   end
  # end

  # def others
  #   if params[:user_id].present?
  #   data = Event.where.not(event_name: ["Cholesterol","Blood Pressure","Blood Glucose"]).where(event_type: "vital",user_id: params[:user_id]).select(:event_datetime,:event_category,:event_options,:user_id).group_by{|event| event.event_datetime.to_date}
  #   some = []
  #   data.each do |k, data|
  #      some.push({k=>data.group_by(&:event_category)})
  #   end
  #   hai = some.reduce { |acc, h| (acc || {}).merge h }
  #   #hai = some.flatten.group_by { |d|  d[:type] }
  #   render json: hai
  #  else
  #   render json: { errors: "Give the user_id" }, status: :unprocessable_entity
  #  end
  # end

  # def some
  #   if params[:user_id].present?
  #     from_date = params[:from_date].present? ? params[:from_date].to_date.beginning_of_day : DateTime.now.beginning_of_month
  #     end_date = params[:end_date].present? ? params[:end_date].to_date.end_of_day : DateTime.now.end_of_day
  #     data = Event.where.not(event_name: ["Cholesterol","Blood Pressure","Blood Glucose","Body Temperature","Oxygen Saturation"]).where(event_type: "vital",user_id: params[:user_id], event_datetime: from_date...end_date).select(:event_datetime, :event_category, :event_options, :user_id, :event_name).group_by{|event| event.event_name}
  #     if data.present?
  #       some = []
  #       data.each do |k, data|
  #         some.push({k=>data.group_by{|event| event.event_datetime.to_date}})
  #       end
  #       hai = some.reduce { |acc, h| (acc || {}).merge h }
  #       hello = []
  #       hai.each do |key,value|
  #         value.each do |some,some1|
  #           hello.push({key=>{some=>some1.group_by(&:event_category)}})
  #         end
  #       end
  #       values = hello.reduce { |acc, h| (acc || {}).merge h }
  #       render json: values
  #     else
  #      render json: []
  #     end
  #   else
  #      render json: { errors: "Give the user_id" }, status: :unprocessable_entity
  #   end
  # end
#-----------------------------------

#------------Single APi-------------
  # def some1
  #   if params[:user_id].present?
  #     data = Event.where(event_type: "vital",user_id: params[:user_id]).select(:event_datetime, :event_category, :event_options, :user_id, :event_name).group_by{|event| event.event_name}
  #     if data.present?
  #       some = []
  #       data.each do |k, data|
  #          some.push({k=>data.group_by{|event| event.event_datetime.to_date}})
  #       end
  #       hai = some.reduce { |acc, h| (acc || {}).merge h }
  #       hello = []
  #       hai.each do |key,value|
  #        value.each do |some,some1|
  #        hello.push({key=>{some=>some1.group_by(&:event_category)}})
  #       end
  #       end
  #        values = hello.reduce { |acc, h| (acc || {}).merge h }
  #        render json: values
  #     else
  #     render json: []
  #     end
  #   else
  #     render json: { errors: "Give the user_id" }, status: :unprocessable_entity
  #   end
  # end
#--------------------------------------------

   def vital_names_list
      if params[:user_id].present?
        page_count = params[:per_page].present? ? params[:per_page]  : "10"
        page = params[:page].present? ? params[:page] : "1"
        names = Event.where(user_id: params[:user_id], event_type: "vital").order('event_datetime DESC').select(:id, :event_category, :description, :event_name, :event_datetime, :event_options, :created_at, :updated_at).group_by(&:event_name)
        names.each{|event_name, events| names[event_name] = events.take(7)}
        render json: names, status: :ok
      else
        render json: { errors: "Give the user_id"}, status: :unprocessable_entity
      end
    end

  # GET events/vital_names_list
    def vital_names_list1
      if params[:user_id].present?
        page_count = params[:per_page].present? ? params[:per_page]  : "10"
        page = params[:page].present? ? params[:page] : "1"
        names = Event.where(user_id: params[:user_id], event_type: "vital").order('event_datetime DESC').select(:id, :event_category, :description,:event_name, :event_options, :updated_at).group_by(&:event_name)  # .paginate(:page => page, :per_page => page_count).group_by(&:event_name)
        vital = []
        names.each{|k, v| vital << {:event_name => k, :value=> v.last(10)}}#.pluck(:event_options)}}
        render json: vital, status: :ok
      else
        render json: { errors: "Give the user_id"}, status: :unprocessable_entity
      end
    end

    def vital_history
      if params[:user_id].present?
        page_count = params[:per_page].present? ? params[:per_page] : "10"
        page = params[:page].present? ? params[:page] : "1"
        from_date = params[:from_date].present? ? params[:from_date].to_date.beginning_of_day : Date.today.beginning_of_month
        end_date = params[:end_date].present? ? params[:end_date].to_date.end_of_day : Date.today.end_of_day 

        name_wise_vital = Event.where(event_name: params[:event_name], user_id: params[:user_id], event_type: "vital", event_datetime: from_date...end_date).order('event_datetime DESC').paginate(:page => page, :per_page => page_count)

        # if params[:from_date].present? && params[:end_date].present?
        #   name_wise_vital = Event.where(event_name: params[:event_name], user_id: params[:user_id], event_type: "vital", event_datetime: params[:from_date].to_date.beginning_of_day...params[:end_date].to_date.end_of_day).order('event_datetime DESC').paginate(:page => page, :per_page => page_count)
        # else
        #   name_wise_vital = Event.where(event_name: params[:event_name], user_id: params[:user_id], event_type: "vital").order('event_datetime DESC').paginate(:page => page, :per_page => page_count)
        # end
        render json: name_wise_vital, status: :ok
          # render json: { vital_history: name_wise_vital, from_date: from_date.to_date, end_date: end_date.to_date }, status: :ok
      else
        render json: { errors: "Give the user_id"}, status: :unprocessable_entity
      end
    end


    # GET /events/1
    def show
      render json: @event_list
    end

  # PATCH/PUT /events/1
    def update
      if @event_list.update(event_params)
        render json: { "message": "Updated Successfully" } 
      else
        render json: @event.errors.messages
      end
    end

    # DELETE /events/1
    def destroy
      @event_list.destroy
    end

    # GET /events/appointment_list
    def appointment_list
      if params[:user_id].present?
        appointment_list = Event.where('event_datetime >= ?', Time.now).where(event_type: "appointment", user_id: params[:user_id]).order('event_datetime ASC').paginate(:page => params[:page], :per_page => params[:page_count])

        render json: { appointment_list: appointment_list }, status: :ok
      else
        render json: { error: "Should be given the user_id" }
      end
      
    end

    # POST /events/event_asset_update
    def event_asset_update
      event = Event.where(user_id: current_user.id, event_type: "alert")
      if event.present?
        Event.find(params[:id]).update(event_assets: params[:event_assets].path)
      end
        if @event_list.update(event_assets: params[:event_assets].path)
          render json: { "message": "Image updated Successfully" }
        else
         render json: @event_list.errors.messages
        end
    end

   private

     # Use callbacks to share common setup or constraints between actions.
    def set_event 
      @event_list = Event.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def event_params
    	params.require(:event).permit!#(:id, :event_name, :description, :value, :event_datetime, :event_type, :event_category, :event_options, :meal,:user_id, { event_assets: [] })
    end
end
   
