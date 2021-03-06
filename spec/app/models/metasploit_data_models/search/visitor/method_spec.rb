require 'spec_helper'

describe MetasploitDataModels::Search::Visitor::Method do
  subject(:visitor) do
    described_class.new
  end

  it_should_behave_like 'Metasploit::Concern.run'

  context '#visit' do
    subject(:visit) do
      visitor.visit(node)
    end

    let(:node) do
      node_class.new
    end

    context 'with Metasploit::Model::Search::Group::Intersection' do
      let(:node_class) do
        Metasploit::Model::Search::Group::Intersection
      end

      it { should == :and }
    end

    context 'with Metasploit::Model::Search::Operation::Group::Intersection' do
      let(:node_class) do
        Metasploit::Model::Search::Operation::Group::Intersection
      end

      it { should == :and }
    end

    context 'with Metasploit::Model::Search::Group::Union' do
      let(:node_class) do
        Metasploit::Model::Search::Group::Union
      end

      it { should == :or }
    end

    context 'with Metasploit::Model::Search::Operation::Group::Union' do
      let(:node_class) do
        Metasploit::Model::Search::Operation::Group::Union
      end

      it { should == :or }
    end
  end
end