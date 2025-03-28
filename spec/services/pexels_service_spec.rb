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

  before do
    videos_client = double('Pexels::Client::Videos')

    mock_response = [ mock_video ]
    def mock_response.total_results
      25
    end

    allow(videos_client).to receive(:popular).and_return(mock_response)
    allow(videos_client).to receive(:search).and_return(mock_response)

    pexels_client = double('Pexels::Client')
    allow(pexels_client).to receive(:videos).and_return(videos_client)

    stub_const('PexelsClient', pexels_client)
  end

  describe '#fetch_videos' do
    it 'returns a hash with video details' do
      service = PexelsService.new
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

    it 'calculates total pages correctly' do
      service = PexelsService.new
      result = service.fetch_videos(1, 10)

      expect(result[:total_pages]).to eq(3)
    end

    it 'allows custom page and per_page parameters' do
      service = PexelsService.new
      result = service.fetch_videos(2, 15)

      expect(result[:page]).to eq(2)
      expect(result[:per_page]).to eq(15)
      expect(result[:total_pages]).to eq(2)
    end

    it 'supports locale parameter' do
      service = PexelsService.new

      expect(PexelsClient.videos).to receive(:popular).with(hash_including(locale: 'pt-BR')).and_return([])

      service.fetch_videos(1, 10, { locale: 'pt-BR' })
    end

    it 'supports size parameter' do
      service = PexelsService.new

      expect(PexelsClient.videos).to receive(:popular).with(hash_including(size: 'large')).and_return([])

      service.fetch_videos(1, 10, { size: 'HD' })
    end

    it 'handles empty response from API gracefully' do
      service = PexelsService.new

      empty_response = []
      def empty_response.total_results
        0
      end

      allow(PexelsClient.videos).to receive(:popular).and_return(empty_response)

      result = service.fetch_videos

      expect(result).to include(:items, :page, :per_page, :total_pages)
      expect(result[:items]).to eq([])
      expect(result[:total_pages]).to eq(0)
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
      result = service.search_videos('nature')

      expect(result).to include(:items, :page, :per_page, :total_pages)
      expect(result[:items].first).to include(
        id: 1234,
        user_name: 'Test User'
      )
    end

    it 'sends the query parameter to the API' do
      service = PexelsService.new

      expect(PexelsClient.videos).to receive(:search).with(hash_including(query: 'nature')).and_return([])

      service.search_videos('nature')
    end

    it 'supports locale parameter' do
      service = PexelsService.new

      expect(PexelsClient.videos).to receive(:search).with(hash_including(locale: 'pt-BR')).and_return([])

      service.search_videos('nature', 1, 10, { locale: 'pt-BR' })
    end

    it 'supports size parameter' do
      service = PexelsService.new

      expect(PexelsClient.videos).to receive(:search).with(hash_including(size: 'medium')).and_return([])

      service.search_videos('nature', 1, 10, { size: 'FullHD' })
    end

    it 'translates size parameters correctly' do
      service = PexelsService.new

      expect(PexelsClient.videos).to receive(:search).with(hash_including(size: 'large')).and_return([])
      service.search_videos('nature', 1, 10, { size: 'HD' })

      expect(PexelsClient.videos).to receive(:search).with(hash_including(size: 'medium')).and_return([])
      service.search_videos('nature', 1, 10, { size: 'FullHD' })

      expect(PexelsClient.videos).to receive(:search).with(hash_including(size: 'small')).and_return([])
      service.search_videos('nature', 1, 10, { size: '4K' })
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
