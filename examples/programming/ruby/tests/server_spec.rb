require 'rack/test'
require 'json'

require_relative '../app'

# Reset items before each test
def reset_items
  Object.send(:remove_const, :items) if Object.constants.include?(:items)
  Object.const_set(:items, [])
end

RSpec.describe 'Ruby HTTP Server' do
  include Rack::Test::Methods

  def app
    # Re-create the app with fresh items
    reset_items
    # The app is a Rack endpoint, we test via HTTP directly
  end

  def reset!
    items.clear
  end

  describe 'GET /' do
    it 'returns welcome message' do
      get '/'
      expect(last_response.status).to eq(200)
      expect(last_response.headers['Content-Type']).to include('application/json')
      data = JSON.parse(last_response.body)
      expect(data['message']).to eq('Welcome to the Ruby HTTP server')
    end
  end

  describe 'GET /health' do
    it 'returns healthy status' do
      get '/health'
      expect(last_response.status).to eq(200)
      expect(last_response.headers['Content-Type']).to include('application/json')
      data = JSON.parse(last_response.body)
      expect(data['status']).to eq('healthy')
    end
  end

  describe 'GET /items' do
    it 'returns empty items array' do
      get '/items'
      expect(last_response.status).to eq(200)
      data = JSON.parse(last_response.body)
      expect(data['items']).to eq([])
    end
  end

  describe 'POST /items' do
    it 'creates a new item' do
      post '/items', {name: 'widget'}.to_json,
                     'CONTENT_TYPE' => 'application/json'
      expect(last_response.status).to eq(201)
      data = JSON.parse(last_response.body)
      expect(data['name']).to eq('widget')
    end

    it 'returns 400 when name is missing' do
      post '/items', {}.to_json,
                     'CONTENT_TYPE' => 'application/json'
      expect(last_response.status).to eq(400)
      data = JSON.parse(last_response.body)
      expect(data['error']).to eq('name is required')
    end
  end

  describe 'DELETE /items' do
    it 'clears all items' do
      post '/items', {name: 'widget'}.to_json,
                     'CONTENT_TYPE' => 'application/json'
      expect(items.length).to eq(1)

      delete '/items'
      expect(last_response.status).to eq(200)
      data = JSON.parse(last_response.body)
      expect(data['removed']).to be true
      expect(items.length).to eq(0)
    end
  end
end