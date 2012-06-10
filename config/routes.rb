if Rails.version < '3.0'
  ActionController::Routing::Routes.draw do |map|
    map.connect 'parking_lot_chart/:action', :controller => 'parking_lot_chart'
  end
else # Rails 3
  RedmineApp::Application.routes.draw do
    match 'parking_lot_chart/:action', :controller => 'parking_lot_chart'
  end
end
