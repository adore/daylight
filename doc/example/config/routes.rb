DaylightExample::Application.routes.draw do

  namespace :api, path: '' do
    namespace :v1 do
      with_options(except: [:new, :edit, :destroy]) do |r|
        r.resources :companies, associated: [:blogs]
        r.resources :blogs, associated: [:posts]
        r.resources :users, associated: [:blogs, :posts, :comments]
        r.resources :comments
        r.resources :posts, associated: [:comments, :commenters, :suppressed_comments], remoted: [:top_comments]
      end
    end
  end

  mount Daylight::Documentation => '/docs'

end
