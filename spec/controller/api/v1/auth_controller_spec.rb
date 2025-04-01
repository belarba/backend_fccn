require 'rails_helper'

RSpec.describe Api::V1::AuthController, type: :controller do
  # Configuração explícita das rotas para testes
  routes { Rails.application.routes }
  describe 'POST #create' do
    before do
      request.accept = 'application/json'
      # Definir a senha esperada para o ambiente de teste
      allow(ENV).to receive(:[]).with("FRONTEND_ACCESS_PASSWORD").and_return("test_password")
    end

    context 'com senha correta' do
      it 'autentica o usuário e define a sessão' do
        post :create, params: { password: 'test_password' }

        expect(response).to have_http_status(:ok)
        expect(session[:authenticated]).to be true
        json_response = JSON.parse(response.body)
        expect(json_response['status']).to eq('success')
      end
    end

    context 'com senha incorreta' do
      it 'retorna erro não autorizado' do
        post :create, params: { password: 'wrong_password' }

        expect(response).to have_http_status(:unauthorized)
        expect(session[:authenticated]).to be_nil
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Unauthorized')
      end
    end

    context 'sem senha fornecida' do
      it 'retorna erro não autorizado' do
        post :create, params: {}

        expect(response).to have_http_status(:unauthorized)
        expect(session[:authenticated]).to be_nil
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Unauthorized')
      end
    end
  end
end
