require 'rails_helper'

RSpec.describe VideoProviderFactory, type: :service do
  describe '.create' do
    it 'creates a PexelsVideoProvider by default' do
      provider = VideoProviderFactory.create
      expect(provider).to be_a(PexelsVideoProvider)
    end

    it 'creates a PexelsVideoProvider when specified' do
      provider = VideoProviderFactory.create(:pexels)
      expect(provider).to be_a(PexelsVideoProvider)
    end

    it 'raises an error for unsupported provider types' do
      expect {
        VideoProviderFactory.create(:unsupported)
      }.to raise_error(ArgumentError, /Provedor de vídeo não suportado/)
    end
  end
end
