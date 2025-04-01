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

  let(:mock_video_provider) { instance_double('VideoProviderInterface') }

  before do
    ENV['BACKEND_API_KEY'] = valid_api_key

    allow(VideoProviderFactory).to receive(:create).and_return(mock_video_provider)
  end

  context 'with valid authorization' do
    before do
      request.headers['Authorization'] = valid_api_key
      # Especificar o formato JSON para todos os testes
      request.accept = 'application/json'
    end

    describe 'GET #index' do
      it 'returns popular videos when no query is provided' do
        allow(mock_video_provider).to receive(:fetch_videos).and_return(mock_videos)

        get :index

        expect(response).to have_http_status(:success)
        expect(assigns(:videos)).to eq(mock_videos[:items])
        expect(assigns(:page)).to eq(1)
        expect(assigns(:per_page)).to eq(10)
        expect(assigns(:total_pages)).to eq(mock_videos[:total_pages])
        # Verifica se o template correto está sendo renderizado
        expect(response).to render_template(:index)
      end

      it 'returns search results when query is provided' do
        allow(mock_video_provider).to receive(:search_videos).and_return(mock_search_videos)

        get :index, params: { query: 'nature' }

        expect(response).to have_http_status(:success)
        expect(assigns(:videos)).to eq(mock_search_videos[:items])
        # Verifica se o template correto está sendo renderizado
        expect(response).to render_template(:index)
      end

      it 'ignores empty query and returns popular videos' do
        allow(mock_video_provider).to receive(:fetch_videos).and_return(mock_videos)

        get :index, params: { query: '' }

        expect(response).to have_http_status(:success)
        expect(assigns(:videos)).to eq(mock_videos[:items])
        expect(response).to render_template(:index)
      end

      it 'supports custom pagination params' do
        allow(mock_video_provider).to receive(:fetch_videos).and_return(mock_videos_2)

        get :index, params: { page: 2, per_page: 15 }

        expect(response).to have_http_status(:success)
        expect(assigns(:page)).to eq(2)
        expect(assigns(:per_page)).to eq(15)
        expect(assigns(:videos)).to eq(mock_videos_2[:items])
        expect(response).to render_template(:index)
      end

      it 'supports size parameter for popular videos' do
        expect(mock_video_provider).to receive(:fetch_videos).with(1, 10, { size: 'HD' }).and_return(mock_videos)

        get :index, params: { size: 'HD' }

        expect(response).to have_http_status(:success)
        expect(assigns(:videos)).to eq(mock_videos[:items])
        expect(response).to render_template(:index)
      end

      it 'handles API errors gracefully' do
        error_response = { error: 'API Error', items: [], page: 1, per_page: 10, total_pages: 0 }
        allow(mock_video_provider).to receive(:fetch_videos).and_return(error_response)

        get :index

        expect(response).to have_http_status(:internal_server_error)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('API Error')
      end
    end

    describe 'GET #show' do
      it 'returns a specific video by id' do
        allow(mock_video_provider).to receive(:fetch_video_by_id).with('1234').and_return(mock_video_detail)

        get :show, params: { id: '1234' }

        expect(response).to have_http_status(:success)
        expect(assigns(:video)).to eq(mock_video_detail)
        expect(assigns(:video_files)).to eq(mock_video_detail[:video_files])
        expect(response).to render_template(:show)
      end

      it 'returns not found when video does not exist' do
        allow(mock_video_provider).to receive(:fetch_video_by_id).with('9999').and_return({ error: 'Video not found' })

        get :show, params: { id: '9999' }

        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Video not found')
      end

      it 'handles API errors gracefully' do
        allow(mock_video_provider).to receive(:fetch_video_by_id).with('1234').and_raise(StandardError.new('API Error'))

        get :show, params: { id: '1234' }

        expect(response).to have_http_status(:internal_server_error)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to include('API Error')
      end
    end
  end

  context 'with invalid authorization' do
    it 'returns unauthorized status' do
      request.headers['Authorization'] = invalid_api_key
      request.accept = 'application/json'

      get :index

      expect(response).to have_http_status(:unauthorized)
      json_response = JSON.parse(response.body)
      expect(json_response['error']).to eq('Unauthorized')
    end

    it 'returns unauthorized when no token is provided' do
      request.accept = 'application/json'

      get :index

      expect(response).to have_http_status(:unauthorized)
      json_response = JSON.parse(response.body)
      expect(json_response['error']).to eq('Unauthorized')
    end

    it 'returns unauthorized for show action' do
      request.headers['Authorization'] = invalid_api_key
      request.accept = 'application/json'

      get :show, params: { id: '1234' }

      expect(response).to have_http_status(:unauthorized)
      json_response = JSON.parse(response.body)
      expect(json_response['error']).to eq('Unauthorized')
    end
  end
end
