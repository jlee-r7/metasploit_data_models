require 'spec_helper'

describe MetasploitDataModels::IPAddress::Range do
  subject(:range) {
    range_class.new
  }

  #
  # Shared examples
  #

  shared_examples_for 'extreme' do |extreme|
    context "##{extreme}" do
      subject("range_#{extreme}") {
        range.send(extreme)
      }

      before(:each) do
        allow(range).to receive(:value).and_return(value)
      end

      context 'with #value' do
        context 'with Range' do
          let(:value) {
            Range.new(0, 1)
          }

          it "is Range##{extreme} of #value" do
            expect(send("range_#{extreme}")).to eq(value.send(extreme))
          end
        end

        context 'without Range' do
          let(:value) {
            'invalid_value'
          }

          it { should be_nil }
        end
      end

      context 'without #value' do
        let(:value) {
          nil
        }

        it { should be_nil }
      end
    end
  end

  #
  # lets
  #

  let(:range_class) {
    described_class = self.described_class

    Class.new do
      include described_class
    end
  }

  context 'CONSTANTS' do
    context 'EXTREMES' do
      subject(:extremes) {
        described_class::EXTREMES
      }

      it { should include :begin }
      it { should include :end }
    end

    context 'SEPARATOR' do
      subject(:separator) {
        described_class::SEPARATOR
      }

      it { should == '-' }
    end
  end

  it_should_behave_like 'extreme', :begin
  it_should_behave_like 'extreme', :end

end