module Api
  module V1
    class AuthController < ApplicationController
      def create
        if params[:password] == ENV["FRONTEND_ACCESS_PASSWORD"]
          session[:authenticated] = true
          render json: { status: "success" }, status: :ok
        else
          render json: { error: "Unauthorized" }, status: :unauthorized
        end
      end
    end
  end
end
