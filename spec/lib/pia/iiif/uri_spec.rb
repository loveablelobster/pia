# frozen_string_literal: true

RSpec.describe Pia::IIIF::URI do
  let :iiif_uri do
    described_class.new(base_url) do |uri|
      uri.identifier = identifier
      uri.region = :full
      uri.size = :max
      uri.rotation = 0
      uri.quality = :default
      uri.format = :jpg
    end
  end

  let(:attributes) { { scheme: scheme, host: host, prefix: prefix } }
  let(:base_url) { "#{scheme}://#{host}/#{path_str}" }
  let(:host) { 'example.com' }
  let(:identifier) { 'image_identifer' }
  let(:scheme) { 'http' }
  let(:path_str) { 'path/to/iiif' }
  let(:prefix) { path_str.split '/' }

  let :fullpath do
    '/path/to/iiif/image_identifer/full/max/0/default.jpg'
  end

  context 'when initialized with URI string' do
    subject { described_class.new base_url }
    
    it { is_expected.to have_attributes attributes }
  end

  context 'when initialized with a hash' do
    subject { described_class.new(**opts) }

    context 'with valid keys' do
      let(:opts) { attributes.merge identifier: identifier }

      it { is_expected.to have_attributes opts }
    end

    context 'with invalid keys' do
      let(:opts) { attributes.merge foo: 'bar' }

      it { is_expected.to have_attributes attributes }
    end
  end

  describe '.parse_uri' do
    subject(:components) { described_class.parse_uri base_url }

    it do
      expect(components).to include 'scheme' => scheme,
                                    'host' => host,
                                    'prefix' => path_str
    end
  end

  describe '#path' do
    subject { iiif_uri.path }

    it { is_expected.to eq fullpath }
  end

  describe '#prefix=' do
    subject(:set_path) { iiif_uri.prefix = value }

    let :new_prefix do
      contain_exactly 'here', 'there', 'be', 'a', 'service'
    end

    context 'with an array' do
      let(:value) { %w[here there be a service] }

      it do
        expect { set_path }
          .to change(iiif_uri, :prefix).from(prefix)
          .to new_prefix
      end
    end

    context 'with a string' do
      let(:value) { 'here/there/be/a/service' }

      it do
        expect { set_path }
          .to change(iiif_uri, :prefix).from(prefix)
          .to new_prefix
      end
    end
  end

  describe '#quality=' do
    subject(:set_quality) { iiif_uri.quality = value }

    context 'with a valid value' do
      let(:value) { :gray }

      it do
        expect { set_quality }
          .to change(iiif_uri, :quality).from(:default).to :gray
      end
    end

    context 'with an invalid value' do
      let(:value) { :awesome }

      it do
        expect { set_quality }.to raise_error ArgumentError
      end
    end
  end

  describe '#resource' do
    subject { iiif_uri.resource }

    it { is_expected.to eq 'default.jpg' }
  end

  describe '#to_uri' do
    subject(:uri) { iiif_uri.to_uri }


    it do
      expect(uri)
        .to have_attributes request_uri: fullpath,
                            path: fullpath
    end

    it do
      expect(uri.to_s).to eq ["#{scheme}://#{host}", fullpath].join
    end

    context 'with http scheme' do
      it { is_expected.to be_a URI::HTTP }
    end

    context 'with https scheme' do
      let(:scheme) { 'https' }

      it { is_expected.to be_a URI::HTTPS }
    end
  end
end
