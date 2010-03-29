require 'parking_lot_chart_data'

class ParkingLotChartController < ApplicationController
  unloadable
  menu_item :parking_lot_chart
  before_filter :find_project, :find_issues_open_status

  def index
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
        if Date.today < version.effective_date
          data.late = false
        else
          data.late = true
        end
      else
        data.late = true
      end
      data.open_issues_pourcent = calc_open_issues_pourcent(version.id, version.estimated_hours)
      data.closed_issues_pourcent = 100 - data.open_issues_pourcent
      @chart_data.push(data)
    end
  end

  def calc_open_issues_pourcent(version_id, total_hours)
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
      elsif params[:status] == "all"
        return find_all_versions
      else
        return find_open_versions
      end
    end
  end

  def find_open_versions
    return @project.versions.find_by_sql([
          "select * from versions where project_id = #{@project.id} and status = 'open' order by effective_date desc"])
  end

  def find_closed_versions
    return @versions = @project.versions.find_by_sql([
          "select * from versions where project_id = #{@project.id} and status = 'closed' order by effective_date desc"])
  end

  def find_locked_versions
    return @versions = @project.versions.find_by_sql([
          "select * from versions where project_id = #{@project.id} and status = 'locked' order by effective_date desc"])
  end

  def find_all_versions
    return @versions = @project.versions.find_by_sql([
          "select * from versions where project_id = #{@project.id} order by effective_date desc"])
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
