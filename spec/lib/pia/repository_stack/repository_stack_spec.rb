# frozen_string_literal: true

RSpec.describe Pia::RepositoryStack::RepositoryStack do
  include_context 'with files'

  let(:stack) { described_class.new repoconfig }

  context 'when initiazlized' do
    subject(:create_stack) { stack }

    before do
      module ::FilePipeline
        @src_directories = [FilePipeline.source_directories.last]
      end
    end

    it 'loads all sources for the FilePipeline' do
      expect { create_stack }
        .to change { FilePipeline.source_directories }
        .from(a_collection_excluding(a_string_ending_with(libdir)))
        .to include a_string_ending_with(libdir)
    end
  end

  describe '.default_config_path' do
    subject { described_class.default_config_path }

    let(:config) { File.join Dir.pwd, Pia::RepositoryStack::REPOSITORY_CONFIG }

    it { is_expected.to eq config }
  end

  describe '.load' do
    subject(:load_config) { described_class.load config }

    context 'without a file and default does not exist' do
      let(:config) { nil }

      it { is_expected.to be_nil }
    end

    context 'with a file that does not exist' do
      let(:config) { 'foo' }

      it 'raises an error' do
        expect { load_config }
          .to raise_error 'No such file or directory @ rb_sysopen - foo'
      end
    end
  end

  describe '#<<' do
    subject(:add_repo) { stack << custom_repo }

    let(:custom_repo) { double 'Custom Repository' }

    it do
      expect { add_repo }.to change(stack, :repositories)
        .from(a_collection_excluding(custom_repo)).to include custom_repo
    end
  end

  describe '#libs' do
    subject { stack.libs }

    it { is_expected.to include libdir }
  end

  describe '#repositories' do
    subject(:stack_repositories) { stack.repositories }

    it do
      expect(stack_repositories)
        .to contain_exactly an_instance_of(Pia::RepositoryStack::Repository),
                            an_instance_of(Pia::RepositoryStack::Repository),
                            an_instance_of(CustomStore)
    end
  end

  describe '#workdir' do
    subject { stack.workdir }

    it { is_expected.to eq workdir }
  end
end
