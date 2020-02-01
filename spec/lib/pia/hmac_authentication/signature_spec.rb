# frozen_string_literal: true

RSpec.describe Pia::HmacAuthentication::Signature do
  include_context 'with files'

  let :hashed_signature do
    described_class.new elements,
                        file: file_param,
                        hash_function: hash_function,
                        secret: secret,
                        separator: separator
  end

  let(:bare_signature) { described_class.new secret: secret }

  # FIXME: move to from here and with_request to with_auth shared context
  let(:secret) { 'testsecret' }

  let(:elements) { %w[foo bar] }
  let(:file_param) { nil }
  let(:hash_function) { 'SHA256' }
  let(:checksum) { Digest::MD5.file(file).hexdigest }
  let(:separator) { '&' }

  let :digest do
    OpenSSL::HMAC.hexdigest hash_function, secret, %w[foo bar].join(separator)
  end

  describe '.from_params' do
    subject :new_signature do
      Pia::HmacAuthentication::Signature.from_params params, keys, hmac_opts
    end

    let :params do
      { 'element1' => elements[0],
        'element2' => elements[1] }
    end

    let(:keys) { %w[element1 element2] }

    let :hmac_opts do
      { hash_function: hash_function,
        secret: secret,
        separator: separator }
    end

    context 'with matching keys' do
      it do
        expect(new_signature)
          .to have_attributes elements: elements,
                              file_md5: nil,
                              hash_function: hash_function,
                              separator: separator,
                              hexdigest: digest
      end
    end

    context 'with missing keys' do
      before { params.delete 'element2' }

      it do
        expect { new_signature }
          .to raise_error KeyError,
                          start_with('key not found: "element2"')
      end
    end
  end

  describe '#<<' do
    it do
      expect { hashed_signature << 'beer' }
        .to change(hashed_signature, :elements)
        .from(elements).to elements.push('beer')
    end
  end

  describe '#file_md5' do
    subject { hashed_signature.file_md5 }

    context 'without a file' do
      it { is_expected.to be_nil }
    end

    context 'with a file' do
      let(:file_param) { file }

      it { is_expected.to eq checksum }
    end
  end

  describe 'file_md5=' do
    context 'with a file' do
      it do
        expect { bare_signature.file_md5 = file }
          .to change(bare_signature, :file_md5)
          .from(nil).to checksum
      end
    end

    context 'without a file' do
      it do
        expect { hashed_signature.file_md5 = nil }
          .not_to change(bare_signature, :file_md5)
      end
    end
  end

  describe '#hexdigest' do
    subject { hashed_signature.hexdigest }

    it { is_expected.to eq digest }
  end

  describe '#match?(digest)' do
    subject { hashed_signature.match? digest }

    context 'when parameter values match' do
      it { is_expected.to be_truthy }
    end

    context 'when parameter values do not match' do
      let :digest do
        OpenSSL::HMAC.hexdigest hash_function,
                                secret,
                                %w[poo bar].join(separator)
      end

      it { is_expected.to be_falsey }
    end

    context 'when digest to compare with is nil' do
      let(:digest) { nil }

      it { is_expected.to be_falsey }
    end
  end

  describe '#message' do
    subject { hashed_signature.message }

    context 'without a file' do
      it { is_expected.to eq elements.join(separator) }
    end

    context 'with a file' do
      let(:file_param) { file }

      it { is_expected.to eq elements.push(checksum).join(separator) }
    end
  end

  describe '#with_file' do
    subject(:sig_with_file) { bare_signature.with_file file }

    it do
      expect { sig_with_file }
        .to change(bare_signature, :file_md5)
        .from(nil).to checksum
    end

    it 'returns self' do
      expect(sig_with_file).to be bare_signature
    end
  end
end
