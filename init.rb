require 'redmine'

Redmine::Plugin.register :redmine_parking_lot_chart do
  name 'Redmine Parking Lot Chart plugin'
  author 'Dai Fujihara'
  description 'Parking lot chart appears in the Agile estimating and planning. This chart makes the theme and the story visible. I try to create redmine plugin for agile development tool.'
  author_url 'http://daipresents.com/'
  url 'http://daipresents.com/2010/redmine_parking_lot_chart_plugin/'

  requires_redmine :version_or_higher => '1.1.3'
  version '0.0.7'

  project_module :parking_lot_chart do
    permission :parking_lot_chart_view, :parking_lot_chart => :index
  end

  menu :project_menu, :parking_lot_chart, { :controller => 'parking_lot_chart', :action => 'index' },
  :caption => :parking_lot_chart, :after => :roadmap, :param => :project_id
end
