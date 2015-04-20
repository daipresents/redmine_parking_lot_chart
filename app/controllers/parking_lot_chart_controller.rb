# encoding: utf-8

require 'parking_lot_chart_data'

class ParkingLotChartController < ApplicationController
  unloadable
  menu_item :parking_lot_chart
  before_filter :find_project, :find_issues_open_status, :find_all_versions

  DEBUG = false
  
  def index
    if DEBUG
      @today = Date::new(2010, 3, 8)
    else
      @today = Date.today
    end
    versions = find_versions
    @chart_data = []
    versions.each do |version|
      data = ParkingLotChartData.new
      data.id = version.id
      data.name = version.name
      if version.estimated_hours
        data.estimated_hours = round(version.estimated_hours)
      else
        data.estimated_hours = 0
      end
      data.open_issues_count = version.open_issues_count
      data.closed_issues_count = version.closed_issues_count
      data.effective_date = version.effective_date
      data.status = version.status
      if version.effective_date
        if data.open_issues_count == 0 && 0 < data.closed_issues_count
          data.issues_status = "closed"
        elsif version.effective_date < @today
          data.issues_status = "late"
        elsif version.effective_date <= (@today + 2)
          data.issues_status = "pinch"
        elsif (data.effective_date - 6) <= @today
          data.issues_status = "one more week"
        else
          data.issues_status = "relax"
        end
      else
        data.issues_status = "late"
      end
      data.open_issues_pourcent = calc_open_issues_pourcent(version.id, version.estimated_hours)
      data.closed_issues_pourcent = 100 - data.open_issues_pourcent

      workday_setting = Setting.plugin_redmine_parking_lot_chart['workday_custom_fields']
      if !workday_setting.nil?
        workday_name = CustomField.find_by_id(workday_setting)
        workday_value = CustomValue.find(:first,
                                          :select => :value,
                                          :conditions => ["customized_type = 'Version' AND custom_field_id = ? AND customized_id = ?", workday_setting, version.id]
                                          )
        if !workday_name.nil? and !workday_value.nil?
          data.workday = "#{workday_name.name}:#{workday_value.value} "
        end
      end

      day_setting = Setting.plugin_redmine_parking_lot_chart['day_custom_fields']
      if !day_setting.nil?
        day_name = CustomField.find_by_id(day_setting)
        day_value = CustomValue.find(:first,
                                      :select => :value,
                                      :conditions => ["customized_type = 'Version' AND custom_field_id = ? AND customized_id = ?", day_setting, version.id]
                                      )
        if !day_name.nil? and !day_value.nil?
          data.day = "#{day_name.name}:#{day_value.value}"
        end
      end

      @chart_data.push(data)
    end
  end

  def calc_open_issues_pourcent(version_id, total_hours)
    return 100 if total_hours == 0
    sum = 0
    @open_statuses.each do |status|
      sum += Issue.sum(:estimated_hours, :conditions => {:fixed_version_id => version_id, :status_id => status.id})
    end

    if sum == 0
      return 0
    else
      return round(sum / total_hours * 100)
    end
  end

  def round(value)
    if value.nil? || value == 0
      return 0
    else
      return ((value * 10.0).round / 10.0).to_f
    end
  end

  def find_versions
    unless params[:status]
      return find_open_versions
    else
      if params[:status] == "closed"
        return find_closed_versions
      elsif params[:status] == "locked"
        return find_locked_versions
      elsif params[:status] == "no_effective_date"
        return find_no_effectvie_date_versions
      elsif params[:status] == "all"
        return @versions
      else
        return find_open_versions
      end
    end
  end

  def find_open_versions
    return @versions.select{|version| version.status == "open"}
  end

  def find_closed_versions
    return @versions.select{|version| version.status == "closed"}
  end

  def find_locked_versions
    return @versions.select{|version| version.status == "locked"}
  end

  def find_no_effectvie_date_versions
    return @project.versions.select{|version| !version.effective_date}
  end

  def find_all_versions
    @versions = @project.shared_versions || []
    @versions = @versions.uniq.sort
    #@versions = @project.versions.select(&:effective_date).sort_by(&:effective_date)
  end

  private
  def find_project
    render_error(l(:parking_lot_chart_project_not_found, :project_id => 'parameter not found.')) and return unless params[:project_id]
    begin
      @project = Project.find(params[:project_id])
    rescue ActiveRecord::NotFound
      render_error(l(:parking_lot_chart_project_not_found, :project_id => params[:project_id])) and return unless @project
    end
  end

  private
  def find_issues_open_status
    @open_statuses = IssueStatus.find_all_by_is_closed(false)
  end
end
