# frozen_string_literal: true

require_relative '../helpers/mockable'

RSpec.shared_context 'with mocks', shared_context: :metadata do
  let(:original_filename) { 'watching_the_sea.jpg' }

  let :asset_object do
    instance_double 'Asset', 'Old Pic',
                    asset_id: store_id,
                    identifier: store_path,
                    public: true,
                    filename: original_filename,
                    media_type: mime,
                    capture_device: capture_device,
                    create_date: create_date,
                    date_imaged: date_imaged,
                    copyright: copyright,
                    md5sum: checksum,
                    repository: store_repo
  end

  let :store_repo do
    instance_double 'Repository', 'Test Store',
                    name: 'Test Store',
                    iiif_image_api: true,
                    service_url: 'http://example.org/iiif',
                    fullsize: 'http://exapmle.org/iiif',
                    default_output_format: 'jpg'
  end

  let(:backup_repo) { instance_double 'Repository', 'Test Backup' }
end
