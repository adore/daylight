Daylight::Documentation.routes.draw do

  with_options controller: 'documentation' do |c|
    c.get '/',          action: :index, as: 'index'
    c.get 'api',        action: :model_index
    c.get 'api/:model', action: :model, as: 'model'
  end

end
