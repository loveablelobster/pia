# frozen_string_literal: true

RSpec::Matchers.define :a_randomized_filename do
  match do |actual|
    /[0-9a-z]{8}-([0-9a-z]{4}-){3}[0-9a-z]{12}\.\w+$/.match? actual
  end
end

RSpec::Matchers.define :an_md5_checksum do
  match do |actual|
    /[0-9a-z]{32}/.match? actual
  end
end

RSpec::Matchers.define_negated_matcher :a_collection_excluding, :include

RSpec::Matchers.alias_matcher :be_a_randomized_filename, :a_randomized_filename
RSpec::Matchers.alias_matcher :be_an_md5_checksum, :an_md5_checksum
