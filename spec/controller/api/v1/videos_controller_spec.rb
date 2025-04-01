require 'rails_helper'

RSpec.describe Api::V1::VideosController, type: :controller do
  describe 'GET #index' do
    context 'with valid authentication', vcr: { cassette_name: 'controllers/videos/index' } do
      before do
        request.headers['Authorization'] = ENV['BACKEND_API_KEY']
        request.accept = 'application/json'
      end

      it 'returns popular videos when no query is provided' do
        get :index

        expect(response).to have_http_status(:success)
        expect(assigns(:videos)).not_to be_nil
        expect(assigns(:page)).to eq(1)
        expect(assigns(:per_page)).to eq(10)
        expect(assigns(:total_pages)).to be_a(Integer)
        expect(response).to render_template(:index)
      end

      it 'returns search results when query is provided', vcr: { cassette_name: 'controllers/videos/search_nature' } do
        get :index, params: { query: 'nature' }

        expect(response).to have_http_status(:success)
        expect(assigns(:videos)).not_to be_nil
        expect(response).to render_template(:index)
      end

      it 'ignores empty query and returns popular videos', vcr: { cassette_name: 'controllers/videos/empty_query' } do
        get :index, params: { query: '' }

        expect(response).to have_http_status(:success)
        expect(assigns(:videos)).not_to be_nil
        expect(response).to render_template(:index)
      end

      it 'supports custom pagination params', vcr: { cassette_name: 'controllers/videos/custom_pagination' } do
        get :index, params: { page: 2, per_page: 5 }

        expect(response).to have_http_status(:success)
        expect(assigns(:page)).to eq(2)
        expect(assigns(:per_page)).to eq(5)
        expect(assigns(:videos)).not_to be_nil
        expect(response).to render_template(:index)
      end

      it 'supports size parameter for popular videos', vcr: { cassette_name: 'controllers/videos/size_filter' } do
        get :index, params: { size: 'HD' }

        expect(response).to have_http_status(:success)
        expect(assigns(:videos)).not_to be_nil
        expect(response).to render_template(:index)
      end
    end

    context 'with invalid authentication' do
      it 'returns unauthorized status' do
        request.headers['Authorization'] = 'invalid_key'
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
    end
  end

  describe 'GET #show' do
    context 'with valid authentication', vcr: { cassette_name: 'controllers/videos/show' } do
      before do
        request.headers['Authorization'] = ENV['BACKEND_API_KEY']
        request.accept = 'application/json'
      end

      it 'returns a specific video by id' do
        # Use um ID válido existente na Pexels
        get :show, params: { id: '2499611' }

        expect(response).to have_http_status(:success)
        expect(assigns(:video)).not_to be_nil
        expect(assigns(:video_files)).not_to be_nil
        expect(response).to render_template(:show)
      end

      it 'returns not found when video does not exist', vcr: { cassette_name: 'controllers/videos/nonexistent' } do
        get :show, params: { id: '999999999999' }

        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Video not found')
      end
    end

    context 'with invalid authentication' do
      it 'returns unauthorized for show action' do
        request.headers['Authorization'] = 'invalid_key'
        request.accept = 'application/json'

        get :show, params: { id: '2499611' }

        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Unauthorized')
      end
    end
  end

  # Teste de erro simulado
  describe 'error handling' do
    before do
      request.headers['Authorization'] = ENV['BACKEND_API_KEY']
      request.accept = 'application/json'

      # Simular erro na API
      allow_any_instance_of(PexelsVideoProvider).to receive(:fetch_videos).and_raise(StandardError.new("API Error"))
    end

    it 'handles API errors gracefully' do
      get :index

      expect(response).to have_http_status(:internal_server_error)
      json_response = JSON.parse(response.body)
      expect(json_response['error']).to include('Error fetching videos')
    end
  end
end
