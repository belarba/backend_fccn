require 'rails_helper'

RSpec.describe PexelsVideoProvider, type: :service do
  let(:formatter) { instance_double(VideoFormatterService) }
  let(:filter) { instance_double(VideoFilterService) }
  let(:provider) { PexelsVideoProvider.new(formatter: formatter, filter: filter) }

  let(:mock_video) do
    double(
      id: 1234,
      width: 1920,
      height: 1080,
      duration: 30,
      user: double(name: 'Test User', url: 'https://www.pexels.com/user/test-user/'),
      files: [
        double(link: 'link1', quality: 'hd', width: 1280, height: 720, file_type: 'video/mp4'),
        double(link: 'link2', quality: 'sd', width: 640, height: 360, file_type: 'video/mp4')
      ],
      pictures: [
        double(picture: 'pic1')
      ],
      url: 'url'
    )
  end

  let(:formatted_response) do
    {
      items: [ { id: 1234, user_name: 'Test User' } ],
      page: 1,
      per_page: 10,
      total_pages: 1
    }
  end

  let(:formatted_detail) do
    {
      id: 1234,
      width: 1920,
      height: 1080,
      user: { name: 'Test User' },
      video_files: { sd: [], hd: [] },
      resolution: 'FullHD'
    }
  end

  describe '#fetch_videos' do
    it 'fetches, filters, and formats popular videos' do
      popular_response = double(videos: [ mock_video ])

      allow(PexelsClient.videos).to receive(:popular).and_return(popular_response)
      allow(filter).to receive(:filter_by_size).with([ mock_video ], nil).and_return([ mock_video ])
      allow(filter).to receive(:paginate_items).with([ mock_video ], 1, 10).and_return([ mock_video ])
      allow(formatter).to receive(:format_videos_response).with([ mock_video ], 1, 10).and_return(formatted_response)

      result = provider.fetch_videos

      expect(result).to eq(formatted_response)
    end

    it 'handles API errors gracefully' do
      allow(PexelsClient.videos).to receive(:popular).and_raise(StandardError.new('API Error'))

      result = provider.fetch_videos

      expect(result[:error]).to include('Unknown error')
      expect(result[:items]).to eq([])
    end
  end

  describe '#search_videos' do
    it 'searches and formats videos properly' do
      search_results = [ mock_video ]
      def search_results.total_results; 1; end

      allow(PexelsClient.videos).to receive(:search).with('test', anything).and_return(search_results)
      allow(formatter).to receive(:format_search_response).with(search_results, 1, 10).and_return(formatted_response)

      result = provider.search_videos('test')

      expect(result).to eq(formatted_response)
    end

    it 'translates size parameters correctly' do
      search_results = [ mock_video ]
      def search_results.total_results; 1; end

      allow(filter).to receive(:translate_size).with('HD').and_return(:large)
      allow(PexelsClient.videos).to receive(:search).with('nature', hash_including(size: :large)).and_return(search_results)
      allow(formatter).to receive(:format_search_response).with(search_results, 1, 10).and_return(formatted_response)

      provider.search_videos('nature', 1, 10, { size: 'HD' })
    end

    it 'handles API errors gracefully' do
      allow(PexelsClient.videos).to receive(:search).and_raise(StandardError.new('API Error'))

      result = provider.search_videos('test')

      expect(result[:error]).to include('Unknown error')
      expect(result[:items]).to eq([])
    end
  end

  describe '#fetch_video_by_id' do
    it 'fetches and formats a single video correctly' do
      allow(PexelsClient.videos).to receive(:find).with('1234').and_return(mock_video)
      allow(formatter).to receive(:format_video_detail).with(mock_video).and_return(formatted_detail)

      result = provider.fetch_video_by_id('1234')

      expect(result).to eq(formatted_detail)
    end

    it 'returns error when video is not found' do
      allow(PexelsClient.videos).to receive(:find).with('9999').and_return(nil)

      result = provider.fetch_video_by_id('9999')

      expect(result).to include(error: 'Video not found')
    end

    it 'handles Pexels API errors' do
      allow(PexelsClient.videos).to receive(:find).and_raise(Pexels::APIError.new('Not found'))

      result = provider.fetch_video_by_id('1234')

      expect(result).to include(error: 'Video not found')
    end

    it 'handles general errors gracefully' do
      allow(PexelsClient.videos).to receive(:find).and_raise(StandardError.new('Network error'))

      result = provider.fetch_video_by_id('1234')

      expect(result).to include(error: 'Unknown error: Network error')
    end
  end
end
