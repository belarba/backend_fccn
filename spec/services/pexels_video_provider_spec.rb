require 'rails_helper'

RSpec.describe PexelsVideoProvider, type: :service do
  let(:provider) { PexelsVideoProvider.new }

  describe '#fetch_videos', vcr: { cassette_name: 'pexels/popular_videos' } do
    it 'fetches popular videos' do
      result = provider.fetch_videos

      expect(result).to be_a(Hash)
      expect(result[:items]).to be_an(Array)
      expect(result[:page]).to eq(1)
      expect(result[:per_page]).to eq(10)
      expect(result[:total_pages]).to be_a(Integer)
    end

    it 'handles pagination correctly', vcr: { cassette_name: 'pexels/popular_videos_page_2' } do
      result = provider.fetch_videos(2, 5)

      expect(result[:page]).to eq(2)
      expect(result[:per_page]).to eq(5)
      expect(result[:items].length).to be <= 5
    end

    it 'filters videos by size', vcr: { cassette_name: 'pexels/popular_videos_hd' } do
      result = provider.fetch_videos(1, 10, { size: 'HD' })

      expect(result[:items]).to be_an(Array)
      # Verifica se os vídeos filtrados têm resolução apropriada quando disponíveis
      if result[:items].any?
        result[:items].each do |video|
          expect(video).to include(:height)
        end
      end
    end
  end

  describe '#search_videos', vcr: { cassette_name: 'pexels/search_videos_nature' } do
    it 'searches for videos by query' do
      result = provider.search_videos('nature')

      expect(result).to be_a(Hash)
      expect(result[:items]).to be_an(Array)
      expect(result[:page]).to eq(1)
      expect(result[:per_page]).to eq(10)
      expect(result[:total_pages]).to be_a(Integer)
    end

    it 'handles search with pagination', vcr: { cassette_name: 'pexels/search_videos_nature_page_2' } do
      result = provider.search_videos('nature', 2, 5)

      expect(result[:page]).to eq(2)
      expect(result[:per_page]).to eq(5)
      expect(result[:items].length).to be <= 5
    end

    it 'returns empty results for nonsense queries', vcr: { cassette_name: 'pexels/search_videos_nonsense' } do
      result = provider.search_videos('ajskdhaskjdhkajshdkjashdkjahsdkjahskdjhaksjdhakjshd')

      expect(result[:items]).to be_an(Array)
      # O total de páginas pode ser 0 ou baixo para uma consulta sem sentido
      expect(result[:total_pages]).to be >= 0
    end

    it 'searches with size filter', vcr: { cassette_name: 'pexels/search_videos_nature_hd' } do
      result = provider.search_videos('nature', 1, 10, { size: 'HD' })

      expect(result[:items]).to be_an(Array)
    end
  end

  describe '#fetch_video_by_id', vcr: { cassette_name: 'pexels/video_2499611' } do
    it 'fetches a single video by id' do
      # Use um ID válido existente na Pexels para evitar falhas
      # Este ID pode precisar ser alterado se o vídeo for removido
      result = provider.fetch_video_by_id('2499611')

      expect(result).to be_a(Hash)
      expect(result[:id]).to be_a(Integer)
      expect(result[:width]).to be_a(Integer)
      expect(result[:height]).to be_a(Integer)
      expect(result[:user]).to include(:name)
      expect(result[:video_files]).to include(:sd, :hd, :full_hd, :uhd)
    end

    it 'returns error for non-existent video', vcr: { cassette_name: 'pexels/video_nonexistent' } do
      result = provider.fetch_video_by_id('999999999999')

      expect(result).to include(:error)
      expect(result[:error]).to eq('Video not found')
    end
  end

  # Este teste simula um erro de conexão
  describe 'error handling' do
    it 'handles connection errors' do
      VCRHelper.mock_connection_error do
        result = provider.fetch_videos

        expect(result).to include(:error)
        expect(result[:items]).to eq([])
      end
    end
  end
end
