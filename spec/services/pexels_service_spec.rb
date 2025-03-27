require 'rails_helper'

RSpec.describe PexelsService, type: :service do
  describe '#fetch_videos' do
    let(:mock_video) do
      double(
        id: 1234,
        width: 1920,
        height: 1080,
        duration: 30,
        user: double(name: 'Test User'),
        files: [
          double(link: 'https://example.com/video1.mp4', quality: 'hd'),
          double(link: 'https://example.com/video2.mp4', quality: 'sd')
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

      allow(videos_client).to receive(:popular)
        .with(page: 1, per_page: 10)
        .and_return(mock_response)

      allow(videos_client).to receive(:popular)
        .with(page: 2, per_page: 15)
        .and_return(mock_response)

      pexels_client = double('Pexels::Client')
      allow(pexels_client).to receive(:videos).and_return(videos_client)

      stub_const('PexelsClient', pexels_client)
    end

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
      expect(result[:items].first[:video_files]).to all(include(:link, :quality))
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
  end
end
