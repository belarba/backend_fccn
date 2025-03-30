require 'rails_helper'

RSpec.describe VideoFormatterService, type: :service do
  let(:service) { VideoFormatterService.new }

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

  describe '#format_videos_response' do
    it 'formats video items correctly' do
      videos = [ mock_video ]
      result = service.format_videos_response(videos, 1, 10)

      expect(result[:items].first[:id]).to eq(1234)
      expect(result[:items].first[:user_name]).to eq('Test User')
      expect(result[:page]).to eq(1)
      expect(result[:per_page]).to eq(10)
      expect(result[:total_pages]).to eq(1)
    end
  end

  describe '#format_video_detail' do
    it 'formats a single video correctly' do
      result = service.format_video_detail(mock_video)

      expect(result[:id]).to eq(1234)
      expect(result[:width]).to eq(1920)
      expect(result[:height]).to eq(1080)
      expect(result[:user][:name]).to eq('Test User')
      expect(result[:video_files]).to include(:sd, :hd, :full_hd, :uhd)
      expect(result[:resolution]).to eq('FullHD')
    end

    it 'categorizes video files by quality' do
      result = service.format_video_detail(mock_video)

      expect(result[:video_files][:sd].first[:height]).to eq(360)
      expect(result[:video_files][:hd].first[:height]).to be >= 720
      expect(result[:video_files][:full_hd].first[:height]).to be >= 1080
    end

    it 'determines the correct resolution' do
      # SD Video
      sd_video = double(
        id: 1,
        width: 640,
        height: 480,
        duration: 30,
        user: double(name: 'Test User', url: 'url'),
        files: [ double(link: 'link', quality: 'sd', width: 640, height: 480, file_type: 'video/mp4') ],
        pictures: [ double(picture: 'pic') ],
        url: 'url'
      )
      sd_result = service.format_video_detail(sd_video)
      expect(sd_result[:resolution]).to eq('SD')

      # HD Video
      hd_video = double(
        id: 2,
        width: 1280,
        height: 720,
        duration: 30,
        user: double(name: 'Test User', url: 'url'),
        files: [ double(link: 'link', quality: 'hd', width: 1280, height: 720, file_type: 'video/mp4') ],
        pictures: [ double(picture: 'pic') ],
        url: 'url'
      )
      hd_result = service.format_video_detail(hd_video)
      expect(hd_result[:resolution]).to eq('HD')

      # 4K Video
      fourk_video = double(
        id: 3,
        width: 3840,
        height: 2160,
        duration: 30,
        user: double(name: 'Test User', url: 'url'),
        files: [ double(link: 'link', quality: 'hd', width: 3840, height: 2160, file_type: 'video/mp4') ],
        pictures: [ double(picture: 'pic') ],
        url: 'url'
      )
      fourk_result = service.format_video_detail(fourk_video)
      expect(fourk_result[:resolution]).to eq('4K')
    end
  end
end
