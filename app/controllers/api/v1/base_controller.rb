module Api
  module V1
    class BaseController < ApplicationController
      before_action :verify_authenticated

      private

      def verify_authenticated
        unless session[:authenticated]
          render json: { error: "Unauthorized" }, status: :unauthorized
        end
      end
    end
  end
end
