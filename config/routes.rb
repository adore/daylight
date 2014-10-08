Daylight::Documentation.routes.draw do

  with_options controller: 'documentation' do |c|
    c.get '/',                  action: :index,  as: 'index'
    c.get ':model',             action: :model,  as: 'model'
    c.get 'schema/:model.json', action: :schema, as: 'schema'
  end

end
