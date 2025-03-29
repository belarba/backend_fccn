require 'rails_helper'

RSpec.describe PexelsService, type: :service do
  let(:mock_video) do
    double(
      id: 1234,
      width: 1920,
      height: 1080,
      duration: 30,
      user: double(name: 'Test User', url: 'https://www.pexels.com/user/test-user/'),
      files: [
        double(link: 'https://example.com/video1.mp4', quality: 'hd', width: 1280, height: 720, file_type: 'video/mp4'),
        double(link: 'https://example.com/video2.mp4', quality: 'sd', width: 640, height: 360, file_type: 'video/mp4'),
        double(link: 'https://example.com/video3.mp4', quality: 'hd', width: 1920, height: 1080, file_type: 'video/mp4')
      ],
      pictures: [
        double(picture: 'https://example.com/thumb1.jpg'),
        double(picture: 'https://example.com/thumb2.jpg')
      ],
      url: 'https://www.pexels.com/video/1234/'
    )
  end

  describe '#fetch_videos' do
    it 'returns a hash with video details' do
      service = PexelsService.new

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

      page1_result = service.fetch_videos(1, 10)
      expect(page1_result[:items].size).to eq(10)
      expect(page1_result[:items].first[:id]).to eq(1000)
      expect(page1_result[:total_pages]).to eq(3)

      page2_result = service.fetch_videos(2, 10)
      expect(page2_result[:items].size).to eq(10)
      expect(page2_result[:items].first[:id]).to eq(1010)

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
    it 'returns successfully formatted results' do
      service = PexelsService.new

      mock_video = instance_double(
        'Video',
        id: 1234,
        width: 1920,
        height: 1080,
        duration: 30,
        user: instance_double('User', name: 'Test User'),
        files: [
          instance_double('VideoFile', link: 'link1', quality: 'hd', width: 1280, height: 720),
          instance_double('VideoFile', link: 'link2', quality: 'sd', width: 640, height: 360)
        ],
        pictures: [
          instance_double('Picture', picture: 'pic1')
        ]
      )

      search_results = [ mock_video ]

      def search_results.total_results
        1
      end

      expect(PexelsClient.videos).to receive(:search).with('test', any_args).and_return(search_results)

      expect(service).to receive(:format_response).with(search_results, 1, 10).and_return({
        items: [ { id: 1234, user_name: 'Test User' } ],
        page: 1,
        per_page: 10,
        total_pages: 1
      })

      result = service.search_videos('test')

      expect(result).to include(:items, :page, :per_page, :total_pages)
      expect(result[:items]).to be_an(Array)
      expect(result[:items].first).to include(id: 1234, user_name: 'Test User')
    end

    it 'handles different size parameters correctly' do
      service = PexelsService.new

      # Mock para o resultado da pesquisa
      mock_response = double(
        "SearchResponse",
        total_results: 1
      )

      mock_video = double(
        id: 1234,
        width: 1920,
        height: 1080,
        duration: 30,
        user: double(name: 'Test User'),
        files: [ double(link: 'link', quality: 'hd', width: 1920, height: 1080) ],
        pictures: [ double(picture: 'pic') ]
      )

      allow(mock_response).to receive(:map).and_yield(mock_video).and_return([ mock_video ])

      expect(PexelsClient.videos).to receive(:search).with('nature', hash_including(size: :large)).and_return(mock_response)
      service.search_videos('nature', 1, 10, { size: 'HD' })

      expect(PexelsClient.videos).to receive(:search).with('nature', hash_including(size: :medium)).and_return(mock_response)
      service.search_videos('nature', 1, 10, { size: 'FullHD' })

      expect(PexelsClient.videos).to receive(:search).with('nature', hash_including(size: :small)).and_return(mock_response)
      service.search_videos('nature', 1, 10, { size: '4K' })
    end

    it 'handles empty response' do
      service = PexelsService.new

      empty_response = double("EmptyResponse", total_results: 0)
      allow(empty_response).to receive(:map).and_return([])

      allow(PexelsClient.videos).to receive(:search).with('nonexistent', anything).and_return(empty_response)

      result = service.search_videos('nonexistent')

      expect(result[:items]).to eq([])
      expect(result[:total_pages]).to eq(0)
    end

    it 'handles API failure gracefully' do
      service = PexelsService.new

      allow(PexelsClient.videos).to receive(:search).and_raise(StandardError.new("API Error"))

      result = service.search_videos('nature')

      expect(result[:error]).to be_present
      expect(result[:items]).to eq([])
    end
  end

  describe '#fetch_video_by_id' do
    let(:mock_hd_video_file) { double(link: 'link_hd', quality: 'hd', width: 1280, height: 720, file_type: 'video/mp4') }
    let(:mock_sd_video_file) { double(link: 'link_sd', quality: 'sd', width: 640, height: 360, file_type: 'video/mp4') }
    let(:mock_full_hd_video_file) { double(link: 'link_full_hd', quality: 'hd', width: 1920, height: 1080, file_type: 'video/mp4') }
    let(:mock_4k_video_file) { double(link: 'link_4k', quality: 'hd', width: 3840, height: 2160, file_type: 'video/mp4') }

    it 'fetches a specific video by id' do
      service = PexelsService.new

      allow(PexelsClient.videos).to receive(:find).with('1234').and_return(mock_video)

      result = service.fetch_video_by_id('1234')

      expect(result).to include(
        id: 1234,
        width: 1920,
        height: 1080,
        duration: 30
      )
      expect(result[:user]).to include(name: 'Test User')
      expect(result[:video_files]).to include(:sd, :hd, :full_hd, :uhd)
      expect(result[:resolution]).to eq('FullHD')
    end

    it 'categorizes video files by quality' do
      service = PexelsService.new

      allow(PexelsClient.videos).to receive(:find).with('1234').and_return(mock_video)

      result = service.fetch_video_by_id('1234')

      expect(result[:video_files][:sd].first[:height]).to eq(360)
      expect(result[:video_files][:hd].first[:height]).to be >= 720
      expect(result[:video_files][:full_hd].first[:height]).to be >= 1080

      if result[:video_files][:hd].size > 1
        expect(result[:video_files][:hd].first[:height]).to be >= result[:video_files][:hd].last[:height]
      end
    end

    it 'determines the correct resolution' do
      service = PexelsService.new

      hd_video = double(
        id: 720,
        width: 1280,
        height: 720,
        duration: 30,
        user: double(name: 'Test User', url: 'https://www.pexels.com/user/test-user/'),
        files: [ mock_hd_video_file ],
        pictures: [ double(picture: 'pic') ],
        url: 'url'
      )
      allow(PexelsClient.videos).to receive(:find).with('720').and_return(hd_video)
      hd_result = service.fetch_video_by_id('720')
      expect(hd_result[:resolution]).to eq('HD')

      fullhd_video = double(
        id: 1080,
        width: 1920,
        height: 1080,
        duration: 30,
        user: double(name: 'Test User', url: 'https://www.pexels.com/user/test-user/'),
        files: [ mock_full_hd_video_file ],
        pictures: [ double(picture: 'pic') ],
        url: 'url'
      )
      allow(PexelsClient.videos).to receive(:find).with('1080').and_return(fullhd_video)
      fullhd_result = service.fetch_video_by_id('1080')
      expect(fullhd_result[:resolution]).to eq('FullHD')

      fourk_video = double(
        id: 2160,
        width: 3840,
        height: 2160,
        duration: 30,
        user: double(name: 'Test User', url: 'https://www.pexels.com/user/test-user/'),
        files: [ mock_4k_video_file ],
        pictures: [ double(picture: 'pic') ],
        url: 'url'
      )
      allow(PexelsClient.videos).to receive(:find).with('2160').and_return(fourk_video)
      fourk_result = service.fetch_video_by_id('2160')
      expect(fourk_result[:resolution]).to eq('4K')
    end

    it 'returns error when video is not found' do
      service = PexelsService.new

      allow(PexelsClient.videos).to receive(:find).with('9999').and_return(nil)

      result = service.fetch_video_by_id('9999')

      expect(result).to include(error: 'Video not found')
    end

    it 'handles API errors gracefully' do
      service = PexelsService.new

      allow(PexelsClient.videos).to receive(:find).and_raise(StandardError.new('API Error'))

      result = service.fetch_video_by_id('1234')

      expect(result).to include(:error)
    end
  end
end
