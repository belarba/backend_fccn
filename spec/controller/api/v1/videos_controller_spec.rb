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

  let(:mock_search_videos) do
    {
      items: [ { id: 3, user_name: 'Search User' } ],
      page: 1,
      per_page: 10,
      total_pages: 1
    }
  end

  let(:mock_video_detail) do
    {
      id: 1234,
      width: 1920,
      height: 1080,
      duration: 30,
      user: {
        name: 'Test User',
        url: 'https://www.pexels.com/user/test-user/'
      },
      video_files: {
        sd: [ { link: 'https://example.com/video_sd.mp4', quality: 'sd', width: 640, height: 360, file_type: 'video/mp4' } ],
        hd: [ { link: 'https://example.com/video_hd.mp4', quality: 'hd', width: 1280, height: 720, file_type: 'video/mp4' } ],
        full_hd: [ { link: 'https://example.com/video_full_hd.mp4', quality: 'hd', width: 1920, height: 1080, file_type: 'video/mp4' } ],
        uhd: []
      },
      video_pictures: [ 'https://example.com/thumb1.jpg' ],
      resolution: 'FullHD',
      url: 'https://www.pexels.com/video/1234/'
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

    describe 'GET #index' do
      it 'returns popular videos when no query is provided' do
        allow(pexels_service).to receive(:fetch_videos).and_return(mock_videos)

        get :index

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['items']).to be_present
        expect(json_response['page']).to eq(1)
        expect(json_response['per_page']).to eq(10)
      end

      it 'returns search results when query is provided' do
        allow(pexels_service).to receive(:search_videos).and_return(mock_search_videos)

        get :index, params: { query: 'nature' }

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['items'].first['user_name']).to eq('Search User')
      end

      it 'ignores empty query and returns popular videos' do
        allow(pexels_service).to receive(:fetch_videos).and_return(mock_videos)

        get :index, params: { query: '' }

        expect(response).to have_http_status(:success)
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

      it 'supports size parameter for popular videos' do
        expect(pexels_service).to receive(:fetch_videos).with(1, 10, { size: 'HD' }).and_return(mock_videos)

        get :index, params: { size: 'HD' }

        expect(response).to have_http_status(:success)
      end

      it 'supports combination of parameters for search' do
        expect(pexels_service).to receive(:search_videos).with(
          'nature', 2, 15, { size: 'FullHD' }
        ).and_return(mock_videos_2)

        get :index, params: {
          query: 'nature',
          page: 2,
          per_page: 15,
          size: 'FullHD'
        }

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['page']).to eq(2)
        expect(json_response['per_page']).to eq(15)
      end
    end

    describe 'GET #show' do
      it 'returns a specific video by id' do
        allow(pexels_service).to receive(:fetch_video_by_id).with('1234').and_return(mock_video_detail)

        get :show, params: { id: '1234' }

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['id']).to eq(1234)
        expect(json_response['resolution']).to eq('FullHD')
        expect(json_response['user']['name']).to eq('Test User')
        expect(json_response['video_files']['hd']).to be_present
      end

      it 'returns not found when video does not exist' do
        allow(pexels_service).to receive(:fetch_video_by_id).with('9999').and_return({ error: 'Video not found' })

        get :show, params: { id: '9999' }

        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Video not found')
      end

      it 'handles API errors gracefully' do
        allow(pexels_service).to receive(:fetch_video_by_id).with('1234').and_raise(StandardError.new('API Error'))

        get :show, params: { id: '1234' }

        expect(response).to have_http_status(:internal_server_error)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to be_present
      end
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

    it 'returns unauthorized for show action' do
      request.headers['Authorization'] = invalid_api_key

      get :show, params: { id: '1234' }

      expect(response).to have_http_status(:unauthorized)
      json_response = JSON.parse(response.body)
      expect(json_response['error']).to eq('Unauthorized')
    end
  end
end
