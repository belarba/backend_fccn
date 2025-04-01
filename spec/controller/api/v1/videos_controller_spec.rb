require 'rails_helper'

# Garantir que as rotas estejam disponíveis para os testes
describe Api::V1::VideosController, type: :controller do
  # Configuração explícita das rotas para testes
  routes { Rails.application.routes }
  # Helper para simular autenticação via sessão
  def authenticate_session
    session[:authenticated] = true
  end

  describe 'GET #index' do
    context 'com sessão autenticada', vcr: { cassette_name: 'controllers/videos/index' } do
      before do
        authenticate_session
        request.accept = 'application/json'
      end

      it 'retorna vídeos populares quando não é fornecida uma query' do
        get :index

        expect(response).to have_http_status(:success)
        expect(assigns(:videos)).not_to be_nil
        expect(assigns(:page)).to eq(1)
        expect(assigns(:per_page)).to eq(10)
        expect(assigns(:total_pages)).to be_a(Integer)
        expect(response).to render_template(:index)
      end

      it 'retorna resultados de busca quando é fornecida uma query', vcr: { cassette_name: 'controllers/videos/search_nature' } do
        get :index, params: { query: 'nature' }

        expect(response).to have_http_status(:success)
        expect(assigns(:videos)).not_to be_nil
        expect(response).to render_template(:index)
      end

      it 'ignora query vazia e retorna vídeos populares', vcr: { cassette_name: 'controllers/videos/empty_query' } do
        get :index, params: { query: '' }

        expect(response).to have_http_status(:success)
        expect(assigns(:videos)).not_to be_nil
        expect(response).to render_template(:index)
      end

      it 'suporta parâmetros de paginação personalizados', vcr: { cassette_name: 'controllers/videos/custom_pagination' } do
        get :index, params: { page: 2, per_page: 5 }

        expect(response).to have_http_status(:success)
        expect(assigns(:page)).to eq(2)
        expect(assigns(:per_page)).to eq(5)
        expect(assigns(:videos)).not_to be_nil
        expect(response).to render_template(:index)
      end

      it 'suporta o parâmetro de tamanho para vídeos populares', vcr: { cassette_name: 'controllers/videos/size_filter' } do
        get :index, params: { size: 'HD' }

        expect(response).to have_http_status(:success)
        expect(assigns(:videos)).not_to be_nil
        expect(response).to render_template(:index)
      end
    end

    context 'sem autenticação' do
      it 'retorna status não autorizado' do
        request.accept = 'application/json'
        get :index

        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Unauthorized')
      end
    end
  end

  describe 'GET #show' do
    context 'com sessão autenticada', vcr: { cassette_name: 'controllers/videos/show' } do
      before do
        authenticate_session
        request.accept = 'application/json'
      end

      it 'retorna um vídeo específico pelo id' do
        # Use um ID válido existente na Pexels
        get :show, params: { id: '2499611' }

        expect(response).to have_http_status(:success)
        expect(assigns(:video)).not_to be_nil
        expect(assigns(:video_files)).not_to be_nil
        expect(response).to render_template(:show)
      end

      it 'retorna not found quando o vídeo não existe', vcr: { cassette_name: 'controllers/videos/nonexistent' } do
        get :show, params: { id: '999999999999' }

        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Video not found')
      end
    end

    context 'sem autenticação' do
      it 'retorna status não autorizado para a ação show' do
        request.accept = 'application/json'
        get :show, params: { id: '2499611' }

        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Unauthorized')
      end
    end
  end

  # Teste de erro simulado
  describe 'tratamento de erros' do
    before do
      authenticate_session
      request.accept = 'application/json'

      # Simular erro na API
      allow_any_instance_of(PexelsVideoProvider).to receive(:fetch_videos).and_raise(StandardError.new("API Error"))
    end

    it 'trata erros de API de forma elegante' do
      get :index

      expect(response).to have_http_status(:internal_server_error)
      json_response = JSON.parse(response.body)
      expect(json_response['error']).to include('Error fetching videos')
    end
  end
end
