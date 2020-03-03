# frozen_string_literal: true

module Mockable
  def self.file_metadata(setname = nil)
    metadata = Psych.load_file('spec/support/test_files/fixture_data.yaml')
                    .fetch :file_metadata
    return metadata unless setname

    metadata.find { |set| set[:setname].to_sym == setname }
  end

  def file_metadata
    Mockable.file_metadata
  end
end
