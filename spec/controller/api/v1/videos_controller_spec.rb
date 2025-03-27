require 'rails_helper'

RSpec.describe Api::V1::VideosController, type: :controller do
  let(:valid_api_key) { 'test_api_key' }
  let(:invalid_api_key) { 'wrong_key' }

  let(:mock_videos) do
    {
      items: [ { id: 1, user_name: 'Test User' } ],
      page: 1,
      per_page: 10,
      total_pages: 1
    }
  end

  let(:mock_videos_2) do
    {
      items: [ { id: 2, user_name: 'Another User' } ],
      page: 2,
      per_page: 15,
      total_pages: 3
    }
  end

  let(:pexels_service) { instance_double(PexelsService) }

  before do
    ENV['BACKEND_API_KEY'] = valid_api_key

    allow(PexelsService).to receive(:new).and_return(pexels_service)
  end

  context 'with valid authorization' do
    before do
      request.headers['Authorization'] = valid_api_key
    end

    it 'returns videos successfully' do
      allow(pexels_service).to receive(:fetch_videos).and_return(mock_videos)

      get :index

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      expect(json_response['items']).to be_present
      expect(json_response['page']).to eq(1)
      expect(json_response['per_page']).to eq(10)
    end

    it 'supports custom pagination params' do
      allow(pexels_service).to receive(:fetch_videos).and_return(mock_videos_2)

      get :index, params: { page: 2, per_page: 15 }

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      expect(json_response['page']).to eq(2)
      expect(json_response['per_page']).to eq(15)
      expect(json_response['items'].first['user_name']).to eq('Another User')
    end
  end

  context 'with invalid authorization' do
    it 'returns unauthorized status' do
      request.headers['Authorization'] = invalid_api_key

      get :index

      expect(response).to have_http_status(:unauthorized)
      json_response = JSON.parse(response.body)
      expect(json_response['error']).to eq('Unauthorized')
    end

    it 'returns unauthorized when no token is provided' do
      get :index

      expect(response).to have_http_status(:unauthorized)
      json_response = JSON.parse(response.body)
      expect(json_response['error']).to eq('Unauthorized')
    end
  end
end
