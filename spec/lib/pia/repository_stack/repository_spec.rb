# frozen_string_literal: true

RSpec.describe Pia::RepositoryStack::Repository do
  include_context 'with files'

  def ls(dir)
    Dir.children(dir).reject { |child| child.start_with? '.' }
  end

  let :ls_dir do
    lambda do
      Dir.children(storedir).reject { |child| child.start_with? '.' }
    end
  end

  let(:repo) { described_class.new stack, **options }
  let(:mimes) { %w[image/jpeg image/tiff] }

  let :options do
    {
      name: 'Image Store',
      media_types: mimes,
      file_processing: {
        'scale' => { width: 1280, height: 1024 },
        'ptiff_conversion' => { tile_width: 64, tile_height: 64 },
        'exif_recovery' => {},
      },
      storage_directory: storedir,
      storage_options: {
        nesting_levels: nil,
        folder_limit: nil,
      },
      service_url: 'http://example.com/iiif',
      iiif_image_api: true
    }
  end

  let :stack do
    instance_double 'Pia::RepositoryStack::RepositoryStack',
                    workdir: workdir,
                    repositories: []
  end

  describe '#attributes' do
    subject { repo.attributes }

    let :have_keys_and_values do
      include name: 'Image Store',
        service_url: 'http://example.com/iiif',
              iiif_image_api: true
    end

    it { is_expected.to have_keys_and_values }
  end

  describe '#iiif_image_api' do
    subject { repo.iiif_image_api }

    it { is_expected.to be_truthy }
  end

  describe '#media_types' do
    subject { repo.media_types }

    it { is_expected.to match_array mimes }
  end

  describe '#name' do
    subject { repo.name }

    it { is_expected.to eq 'Image Store' }
  end

  describe '#processing' do
    subject { repo.processing }

    let(:operations) { contain_exactly scale_op, ptiff_op, exif }

    let :ptiff_op do
      a_kind_of(FilePipeline::FileOperations::PtiffConversion) &
        have_attributes(options: { tile_width: 64, tile_height: 64,
                                   tile: true, pyramid: true })
    end

    let :scale_op do
      a_kind_of(FilePipeline::FileOperations::Scale) &
        have_attributes(options: { width: 1280, height: 1024,
                                   method: :scale_by_bounds })
    end

    let :exif do
      a_kind_of(FilePipeline::FileOperations::ExifRecovery)
    end

    it { is_expected.to be_a FilePipeline::Pipeline }
    it { is_expected.to have_attributes file_operations: operations }
  end

  describe '#service_url' do
    subject { repo.service_url }

    it { is_expected.to eq 'http://example.com/iiif' }
  end

  describe '#storage' do
    subject { repo.storage }

    it { is_expected.to be_a FolderStash::FileUsher }
    it { is_expected.to have_attributes directory: storedir }
  end

  describe '#store' do
    subject(:store_file) { repo.store file }

    it 'stores the file' do
      expect { store_file }.to change { ls storedir }
        .from(be_empty).to include a_randomized_filename
    end

    it 'cleans up the working directory' do
      expect { store_file }.not_to change { ls workdir }
    end

    it 'returns a path' do
      expect(store_file[0]).to be_a_randomized_filename
    end

    it 'returns file metadata' do
      expect(store_file[1])
        .to contain_exactly a_hash_including(setname: 'stored'),
                            a_hash_including(setname: 'dropped'),
                            a_hash_including(setname: 'withheld')
    end

    it 'returns an MD5 checksum' do
      expect(store_file[2]).to be_an_md5_checksum
    end

    after do
      Dir.glob("#{storedir}/*").each { |file| FileUtils.rm_r file }
    end
  end

  describe '#supports?' do
    subject { repo.supports? mime }

    context 'with a supported media type' do
      let(:mime) { 'image/jpeg' }

      it { is_expected.to be_truthy }
    end

    context 'with a media type that is not supported' do
      let(:mime) { 'image/jp2' }

      it { is_expected.to be_falsey }
    end
  end
end
