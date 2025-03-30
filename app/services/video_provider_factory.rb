class VideoProviderFactory
  def self.create(provider_type = :pexels)
    case provider_type
    when :pexels
      PexelsVideoProvider.new
    # Pode adicionar mais provedores aqui no futuro
    # when :youtube
    #   YouTubeVideoProvider.new
    else
      raise ArgumentError, "Provedor de vídeo não suportado: #{provider_type}"
    end
  end
end
