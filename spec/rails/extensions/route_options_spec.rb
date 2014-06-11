require 'spec_helper'

class TestAssociatedRouteController < ActionController::Base
  def associated
    render text: [params[:controller], params[:id], params[:associated]].join('/')
  end
end

class TestAssociatedRoutesController < TestAssociatedRouteController
  def associated
    render text: [params[:controller], params[:associated]].join('/')
  end
end

class TestMethodRoute < ActiveRecord::Base
  include Daylight::Refiners
end

class TestMethodRouteController < ActionController::Base
  def remoted
    render text: [params[:controller], params[:id], params[:remoted]].join('/')
  end
end

class TestAltModel < ActiveRecord::Base
  include Daylight::Refiners
end

class TestMethodRouteAltModelController < ActionController::Base
  def self.model
    TestAltModel
  end

  def remoted
    render text: [params[:controller], params[:id], params[:remoted]].join('/')
  end
end

describe RouteOptions, type: [:controller, :routing] do

  after :all do
    Rails.application.reload_routes!
  end

  describe 'associated on resources' do
    # rspec's controller temporarily wipes out routes and recreates
    # routes for the anonymnous controller, we don't want to do that
    def self.controller_class
      TestAssociatedRouteController
    end

    describe 'with one route' do

      before do
        @routes.draw do
          resources :test_associated_route, associated: %w[bars]
        end
      end

      it 'adds associated route' do
        expect(get: '/test_associated_route/1/bars').to route_to(

          controller: 'test_associated_route',
          action: 'associated',
          id: '1',
          associated: 'bars'
        )
      end

      it 'respsonds to associated with expected params' do
        get :associated, id: 1, associated: 'bars'

        assert_response :success

        response.body.should == 'test_associated_route/1/bars'
      end

      it 'sets up named link helpers' do
        bars_test_associated_route_path(10).should == '/test_associated_route/10/bars'
      end
    end

    describe 'with multiple routes' do

      before do
        @routes.draw do
          resources :test_associated_route, associated: %w[bars wibbles]
        end
      end

      it 'adds first associated route' do
        expect(get: '/test_associated_route/1/bars').to route_to(

          controller: 'test_associated_route',
          action: 'associated',
          id: '1',
          associated: 'bars'
        )
      end

      it 'respsonds to first associated with expected params' do
        get :associated, id: 1, associated: 'bars'

        assert_response :success
        response.body.should == 'test_associated_route/1/bars'
      end

      it 'sets up first named link helpers' do
        bars_test_associated_route_path(11).should == '/test_associated_route/11/bars'
      end


      it 'adds last associated route' do
        expect(get: '/test_associated_route/1/wibbles').to route_to(

          controller: 'test_associated_route',
          action: 'associated',
          id: '1',
          associated: 'wibbles'
        )
      end

      it 'respsonds to last associated with expected params' do
        get :associated, id: 1, associated: 'wibbles'

        assert_response :success
        response.body.should == 'test_associated_route/1/wibbles'
      end

      it 'sets up last named link helpers' do
        wibbles_test_associated_route_path(11).should == '/test_associated_route/11/wibbles'
      end
    end
  end

  describe 'associated on resource' do
    # rspec's controller temporarily wipes out routes and recreates
    # routes for the anonymnous controller, we don't want to do that
    def self.controller_class
      TestAssociatedRoutesController
    end


    describe 'with one route' do

      before do
        @routes.draw do
          resource :test_associated_route, associated: %w[bars]
        end
      end

      it 'adds associated route' do
        expect(get: '/test_associated_route/bars').to route_to(

          controller: 'test_associated_routes',
          action: 'associated',
          associated: 'bars'
        )
      end

      it 'respsonds to associated with expected params' do
        get :associated, associated: 'bars'

        assert_response :success

        response.body.should == 'test_associated_routes/bars'
      end

      it 'sets up named link helpers' do
        bars_test_associated_route_path.should == '/test_associated_route/bars'
      end
    end

    describe 'with multiple routes' do

      before do
        @routes.draw do
          resource :test_associated_route, associated: %w[bars wibbles]
        end
      end

      it 'adds first associated route' do
        expect(get: '/test_associated_route/bars').to route_to(

          controller: 'test_associated_routes',
          action: 'associated',
          associated: 'bars'
        )
      end

      it 'respsonds to first associated with expected params' do
        get :associated, associated: 'bars'

        assert_response :success
        response.body.should == 'test_associated_routes/bars'
      end

      it 'sets up first named link helpers' do
        bars_test_associated_route_path.should == '/test_associated_route/bars'
      end


      it 'adds last associated route' do
        expect(get: '/test_associated_route/wibbles').to route_to(

          controller: 'test_associated_routes',
          action: 'associated',
          associated: 'wibbles'
        )
      end

      it 'respsonds to last associated with expected params' do
        get :associated, associated: 'wibbles'

        assert_response :success
        response.body.should == 'test_associated_routes/wibbles'
      end

      it 'sets up last named link helpers' do
        wibbles_test_associated_route_path.should == '/test_associated_route/wibbles'
      end
    end
  end

  describe "remoted resource" do
    # rspec's controller temporarily wipes out routes and recreates
    # routes for the anonymnous controller, we don't want to do that
    def self.controller_class
      TestMethodRouteController
    end

    before do
      @routes.draw do
        resources :test_method_route, remoted: %w[foo]
      end
    end

    it 'adds associated route' do
      expect(get: '/test_method_route/1/foo').to route_to(
        controller: 'test_method_route',
        action: 'remoted',
        id: '1',
        remoted: 'foo'
      )
    end

    it 'respsonds to method with expected params' do
      get :remoted, id: 1, remoted: 'foo'

      assert_response :success

      response.body.should == 'test_method_route/1/foo'
    end

    it 'sets up named link helpers' do
      foo_test_method_route_path(10).should == '/test_method_route/10/foo'
    end

    it 'keeps track for remoted methods on the controller' do
      TestMethodRoute.remoted?(:foo).should be_true
    end
  end

  describe "remoted resource with alternate model" do
    # rspec's controller temporarily wipes out routes and recreates
    # routes for the anonymnous controller, we don't want to do that
    def self.controller_class
      TestMethodRouteAltModelController
    end

    before do
      @routes.draw do
        resources :test_method_route_alt_model, remoted: %w[bar]
      end
    end

    it 'adds associated route' do
      expect(get: '/test_method_route_alt_model/1/bar').to route_to(
        controller: 'test_method_route_alt_model',
        action: 'remoted',
        id: '1',
        remoted: 'bar'
      )
    end

    it 'respsonds to method with expected params' do
      get :remoted, id: 1, remoted: 'bar'

      assert_response :success

      response.body.should == 'test_method_route_alt_model/1/bar'
    end

    it 'sets up named link helpers' do
      bar_test_method_route_alt_model_path(10).should == '/test_method_route_alt_model/10/bar'
    end

    it 'keeps track for remoted methods on the controller' do
      TestAltModel.remoted?(:bar).should be_true
    end
  end

end
