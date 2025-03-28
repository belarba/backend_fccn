require 'rails_helper'

RSpec.describe PexelsService, type: :service do
  let(:mock_video) do
    double(
      id: 1234,
      width: 1920,
      height: 1080,
      duration: 30,
      user: double(name: 'Test User'),
      files: [
        double(link: 'https://example.com/video1.mp4', quality: 'hd', width: 1280, height: 720),
        double(link: 'https://example.com/video2.mp4', quality: 'sd', width: 640, height: 360)
      ],
      pictures: [
        double(picture: 'https://example.com/thumb1.jpg'),
        double(picture: 'https://example.com/thumb2.jpg')
      ]
    )
  end

  describe '#fetch_videos' do
    it 'returns a hash with video details' do
      service = PexelsService.new

      # Criar mock para a resposta do popular
      popular_response = double(
        videos: [ mock_video ]
      )

      allow(PexelsClient.videos).to receive(:popular).and_return(popular_response)

      result = service.fetch_videos

      expect(result).to include(:items, :page, :per_page, :total_pages)
      expect(result[:items].first).to include(
        id: 1234,
        width: 1920,
        height: 1080,
        duration: 30,
        user_name: 'Test User'
      )
      expect(result[:items].first[:video_files]).to all(include(:link, :quality, :width, :height))
      expect(result[:items].first[:video_pictures]).to all(be_a(String))
    end

    it 'applies pagination correctly' do
      service = PexelsService.new

      # Criar mock com 25 vídeos para testar paginação
      video_mocks = Array.new(25) { |i|
        double(
          id: i + 1000,
          width: 1920,
          height: 1080,
          duration: 30,
          user: double(name: "User #{i}"),
          files: [ double(link: "link#{i}", quality: 'hd', width: 1280, height: 720) ],
          pictures: [ double(picture: "pic#{i}") ],
        )
      }

      popular_response = double(
        videos: video_mocks
      )

      allow(PexelsClient.videos).to receive(:popular).and_return(popular_response)

      # Página 1, 10 por página
      page1_result = service.fetch_videos(1, 10)
      expect(page1_result[:items].size).to eq(10)
      expect(page1_result[:items].first[:id]).to eq(1000)
      expect(page1_result[:total_pages]).to eq(3)

      # Página 2, 10 por página
      page2_result = service.fetch_videos(2, 10)
      expect(page2_result[:items].size).to eq(10)
      expect(page2_result[:items].first[:id]).to eq(1010)

      # Última página (parcial)
      page3_result = service.fetch_videos(3, 10)
      expect(page3_result[:items].size).to eq(5)
      expect(page3_result[:items].first[:id]).to eq(1020)
    end

    it 'handles API failure gracefully' do
      service = PexelsService.new

      allow(PexelsClient.videos).to receive(:popular).and_raise(StandardError.new("Some Error"))

      result = service.fetch_videos

      expect(result).to include(:items, :page, :per_page, :total_pages, :error)
      expect(result[:items]).to eq([])
      expect(result[:total_pages]).to eq(0)
      expect(result[:error]).to eq("Unknown error: Some Error")
    end
  end

  describe '#search_videos' do
    it 'returns a hash with video details' do
      service = PexelsService.new

      # Criar um array com o video mock e adicionar métodos necessários
      search_results = [ mock_video ]
      def search_results.total_results
        1
      end

      allow(PexelsClient.videos).to receive(:search).and_return(search_results)

      result = service.search_videos('nature')

      expect(result).to include(:items, :page, :per_page, :total_pages)
      expect(result[:items].size).to eq(1)
      expect(result[:items].first).to include(
        id: 1234,
        width: 1920,
        height: 1080,
        duration: 30,
        user_name: 'Test User'
      )
    end

    it 'supports size parameter' do
      service = PexelsService.new

      # Criar um array com o video mock e adicionar métodos necessários
      search_results = [ mock_video ]
      def search_results.total_results
        1
      end

      # Garantir que chamadas anteriores não interfiram neste teste
      allow(PexelsClient.videos).to receive(:search).and_return(search_results)

      expect(PexelsClient.videos).to receive(:search).with(
        'nature', hash_including(size: :medium)
      ).and_return(search_results)

      result = service.search_videos('nature', 1, 10, { size: 'FullHD' })
      expect(result[:items].size).to eq(1)
    end

    it 'translates size parameters correctly' do
      service = PexelsService.new

      # Criar um array com o video mock e adicionar métodos necessários
      search_results = [ mock_video ]
      def search_results.total_results
        1
      end

      # Mocks para cada chamada específica
      allow(PexelsClient.videos).to receive(:search).and_return(search_results)

      # Teste para 'HD'
      result_hd = service.search_videos('nature', 1, 10, { size: 'HD' })
      expect(result_hd[:items].size).to eq(1)

      # Teste para 'FullHD'
      result_fullhd = service.search_videos('nature', 1, 10, { size: 'FullHD' })
      expect(result_fullhd[:items].size).to eq(1)

      # Teste para '4K'
      result_4k = service.search_videos('nature', 1, 10, { size: '4K' })
      expect(result_4k[:items].size).to eq(1)
    end

    it 'handles empty response' do
      service = PexelsService.new

      # Criar um array vazio e adicionar método total_results
      empty_results = []
      def empty_results.total_results
        0
      end

      allow(PexelsClient.videos).to receive(:search).and_return(empty_results)

      result = service.search_videos('nonexistent')

      expect(result[:items]).to eq([])
      expect(result[:total_pages]).to eq(0)
    end

    it 'handles API failure gracefully' do
      service = PexelsService.new

      allow(PexelsClient.videos).to receive(:search).and_raise(StandardError.new("Some Error"))

      result = service.search_videos('nature')

      expect(result).to include(:items, :page, :per_page, :total_pages, :error)
      expect(result[:items]).to eq([])
      expect(result[:total_pages]).to eq(0)
      expect(result[:error]).to eq("Unknown error: Some Error")
    end
  end
end
