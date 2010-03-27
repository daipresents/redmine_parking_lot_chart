require 'redmine'

Redmine::Plugin.register :redmine_parking_lot_chart do
  name 'Redmine Parking Lot Chart plugin'
  author 'Dai Fujihara'
  description 'This is a plugin for Redmine'
  author_url 'http://daipresents.com/weblog/fujihalab/'
  url 'http://daipresents.com/weblog/fujihalab/archives/2010/03/redmine-parking-lot-chart-plugin.php'

  requires_redmine :version_or_higher => '0.9.0'
  version '0.0.1'

  project_module :parking_lot_chart do
    permission :parking_lot_chart_view, :parking_lot_chart => :index
  end

  menu :project_menu, :parking_lot_chart, { :controller => 'parking_lot_chart', :action => 'index' },
  :caption => :parking_lot_chart, :after => :roadmap, :param => :project_id
end
