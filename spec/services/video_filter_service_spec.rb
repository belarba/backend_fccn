require 'rails_helper'

RSpec.describe VideoFilterService, type: :service do
  let(:service) { VideoFilterService.new }

  describe '#filter_by_size' do
    let(:sd_video) { double(height: 480, width: 640) }
    let(:hd_video) { double(height: 720, width: 1280) }
    let(:fullhd_video) { double(height: 1080, width: 1920) }
    let(:fourk_video) { double(height: 2160, width: 3840) }

    let(:videos) { [ sd_video, hd_video, fullhd_video, fourk_video ] }

    it 'returns all videos when no size is specified' do
      result = service.filter_by_size(videos, nil)
      expect(result.size).to eq(4)
    end

    it 'filters videos by HD size' do
      result = service.filter_by_size(videos, 'HD')
      expect(result).to include(hd_video)
      expect(result).not_to include(fullhd_video, fourk_video)
    end

    it 'filters videos by FullHD size' do
      result = service.filter_by_size(videos, 'FullHD')
      expect(result).to include(fullhd_video)
      expect(result).not_to include(fourk_video)
    end

    it 'filters videos by 4K size' do
      result = service.filter_by_size(videos, '4K')
      expect(result).to include(fourk_video)
    end
  end

  describe '#paginate_items' do
    let(:items) { (1..25).to_a }

    it 'returns the correct page of items' do
      result = service.paginate_items(items, 1, 10)
      expect(result).to eq((1..10).to_a)

      result = service.paginate_items(items, 2, 10)
      expect(result).to eq((11..20).to_a)

      result = service.paginate_items(items, 3, 10)
      expect(result).to eq((21..25).to_a)
    end

    it 'returns empty array for pages beyond the end' do
      result = service.paginate_items(items, 4, 10)
      expect(result).to eq([])
    end
  end

  describe '#translate_size' do
    it 'translates size strings to symbols' do
      expect(service.translate_size('HD')).to eq(:large)
      expect(service.translate_size('FullHD')).to eq(:medium)
      expect(service.translate_size('4K')).to eq(:small)
      expect(service.translate_size('unknown')).to be_nil
    end

    it 'handles case-insensitive input' do
      expect(service.translate_size('hd')).to eq(:large)
      expect(service.translate_size('fullhd')).to eq(:medium)
      expect(service.translate_size('4k')).to eq(:small)
    end
  end
end
