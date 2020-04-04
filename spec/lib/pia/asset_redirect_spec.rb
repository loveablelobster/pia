# frozen_string_literal: true

RSpec.describe Pia::AssetRedirect do
  include_context 'with mocks'
  include_context 'with request'

  let(:redirect) { described_class.new asset_object }
  let(:base) { 'http://example.org' }

  describe '#build_uri' do
    context 'with base_uri arg' do
      subject(:uri) { redirect.build_uri 'http://example.com/service' }

      it 'returns a full URI' do
        expect(uri).to eq "http://example.com/service/#{store_path}"
      end
    end

    context 'with params' do
      subject :uri do
        redirect.build_uri scheme: 'http',
                           host: 'example.com',
                           prefix: 'iiif',
                           identifier: store_path,
                           region: :full,
                           size: :max,
                           rotation: 0,
                           quality: :default,
                           format: :jpg
      end

      it 'returns a full iiif URI' do
        expect(uri)
          .to eq "http://example.com/iiif/#{store_path}/full/max/0/default.jpg"
      end
    end
  end

  describe '#default_media_type'do
    subject(:default_media_type) { redirect.default_media_type }

    it 'returns the default output format extension for the repository' do
      expect(default_media_type).to eq 'jpg'
    end
  end

  describe '#fullsize' do
    subject(:fullsize) { redirect.fullsize(**opts) }

    context 'without params' do
      let(:opts) { {} }

      it 'returns a URI for the fullsize image with dfault output format' do
        expect(fullsize)
          .to eq "#{base}/iiif/#{store_path}/full/max/0/default.jpg"
      end
    end

    context 'with params' do
      let(:opts) { { format: 'png' } }

      it 'returns a URI for the fullsize image' do
        expect(fullsize)
          .to eq "#{base}/iiif/#{store_path}/full/max/0/default.png"
      end
    end
  end

  describe '#fullsize_params' do
    subject(:fullsize_params) { redirect.fullsize_params(**opts) }

    context 'without params' do
      let(:opts) { {} }

      it 'returns the a hash with default parameter values for a'\
         ' iiif URI for the fullsize image' do
        expect(fullsize_params)
          .to include identifier: store_path,
                      region: :full,
                      size: :max,
                      rotation: 0,
                      quality: :default,
                      format: 'jpg'
      end
    end

    context 'with params' do
      let(:opts) { { quality: :bitonal, format: :tif } }

      it 'returns a hash with specified values and defaults' do
        expect(fullsize_params)
          .to include identifier: store_path,
                      region: :full,
                      size: :max,
                      rotation: 0,
                      quality: :bitonal,
                      format: :tif
      end
    end
  end

  describe '#iiif' do
    subject(:iiif) { redirect.iiif(*args) }

    context 'with arguments' do
      let :args do
        [:square, '640,480', 45, :gray, :png]
      end

      it 'returns a URI for the iiif resource for the asset with params'\
         ' as specified by the arguments' do
        expect(iiif).to eq "#{base}/iiif/#{store_path}"\
                           '/square/640,480/45/gray.png'
      end
    end

    context 'without arguments' do
      let(:args) { [] }

      it 'returns a URI for the iiif resource for the asset' do
        expect(iiif).to eq "#{base}/iiif/#{store_path}/full/max/0/default.jpg"
      end
    end
  end

  describe '#iiif_image_api?' do
    subject { redirect.iiif_image_api? }

    context 'with a iiif repository' do
      it { is_expected.to be_truthy }
    end
  end

  describe '#iiif_params' do
    subject(:iiif_params) { redirect.iiif_params(**opts) }

    context 'with params' do
      let :opts do
        { region: :square,
          size: '640,480',
          rotation: 45,
          quality: :gray,
          format: :png }
      end

      it 'returns a hash with specified values and defaults' do
        expect(iiif_params).to include(**opts)
      end

      it 'returns a hash including the asset identifier' do
        expect(iiif_params).to include identifier: store_path
      end
    end

    context 'without params' do
      let(:opts) { {} }

      it 'returns a hash with default parameter values for a iiif URI' do
        expect(iiif_params)
          .to include identifier: store_path,
                      region: :full,
                      size: :max,
                      rotation: 0,
                      quality: :default,
                      format: 'jpg'
      end
    end
  end

  describe '#service_url' do
    subject(:service_url) { redirect.service_url }

    it 'returns the base url (scheme and host) for the service'\
       ' where the asset is available for requests' do
      expect(service_url).to eq "#{base}/iiif"
    end
  end

  describe '#thumbnail' do
    subject(:thumbnail) { redirect.thumbnail(**opts) }

    context 'with params' do
      let(:opts) { { size: 256 } }

      it 'returns a URI for a thumbnail' do
        expect(thumbnail)
          .to eq "#{base}/iiif/#{store_path}/full/256,/0/default.jpg"
      end
    end

    context 'without params' do
      let(:opts) { {} }

      it 'returns a URI for a thumbnail with default size' do
        expect(thumbnail)
          .to eq "#{base}/iiif/#{store_path}/full/128,/0/default.jpg"
      end
    end

  end

  describe '#thumbnail_params' do
    subject(:thumbnail_params) { redirect.thumbnail_params(**opts) }

    context 'with params' do
      let(:opts) { { size: 256 } }
 
      it 'returns a hash with specified values and defaults' do
        expect(thumbnail_params)
          .to include identifier: store_path,
                      region: :full,
                      size: '256,',
                      rotation: 0,
                      quality: :default,
                      format: 'jpg'
      end
    end

    context 'without params' do
      let(:opts) { {} }
 
      it 'returns the a hash with default parameter values for a'\
         ' thumbnail iiif URI' do
        expect(thumbnail_params)
          .to include identifier: store_path,
                      region: :full,
                      size: '128,',
                      rotation: 0,
                      quality: :default,
                      format: 'jpg'
      end
    end
  end
end
