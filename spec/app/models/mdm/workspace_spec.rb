require 'spec_helper'

describe Mdm::Workspace do
  subject(:workspace) do
    FactoryGirl.build(:mdm_workspace)
  end

  let(:default) do
    'default'
  end

  context 'factory' do
    it 'should be valid' do
      workspace = FactoryGirl.build(:mdm_workspace)
      workspace.should be_valid
    end
  end

  context '#destroy' do
    it 'should successfully destroy the object and dependent objects' do
      workspace = FactoryGirl.create(:mdm_workspace)
      listener = FactoryGirl.create(:mdm_listener, :workspace => workspace)
      report_template = FactoryGirl.create(:mdm_report_template, :workspace => workspace)
      report = FactoryGirl.create(:mdm_report, :workspace => workspace)
      task = FactoryGirl.create(:mdm_task, :workspace => workspace)

      expect {
        workspace.destroy
      }.to_not raise_error
      expect {
        workspace.reload
      }.to raise_error(ActiveRecord::RecordNotFound)
      expect {
        listener.reload
      }.to raise_error(ActiveRecord::RecordNotFound)
      expect {
        report_template.reload
      }.to raise_error(ActiveRecord::RecordNotFound)
      expect {
        report.reload
      }.to raise_error(ActiveRecord::RecordNotFound)
      expect {
        task.reload
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context 'associations' do
    it { should have_many(:clients).class_name('Mdm::Client').through(:hosts) }
    it { should have_many(:creds).class_name('Mdm::Cred').through(:services) }
    it { should have_many(:events).class_name('Mdm::Event') }
    it { should have_many(:exploited_hosts).class_name('Mdm::ExploitedHost').through(:hosts) }
    it { should have_many(:hosts).class_name('Mdm::Host') }
    it { should have_many(:listeners).class_name('Mdm::Listener').dependent(:destroy) }
    it { should have_many(:loots).class_name('Mdm::Loot').through(:hosts) }
    it { should have_many(:notes).class_name('Mdm::Note') }
    it { should belong_to(:owner).class_name('Mdm::User').with_foreign_key('owner_id') }
    it { should have_many(:report_templates).class_name('Mdm::ReportTemplate').dependent(:destroy) }
    it { should have_many(:reports).class_name('Mdm::Report').dependent(:destroy) }
    it { should have_many(:services).class_name('Mdm::Service').through(:hosts).with_foreign_key('service_id') }
    it { should have_many(:sessions).class_name('Mdm::Session').through(:hosts) }
    it { should have_many(:tasks).class_name('Mdm::Task').dependent(:destroy).order('created_at DESC') }
    it { should have_and_belong_to_many(:users).class_name('Mdm::User') }
    it { should have_many(:vulns).class_name('Mdm::Vuln').through(:hosts) }
  end

  context 'callbacks' do
    context 'before_save' do
      context '#normalize' do
        it 'should be called' do
          workspace.should_receive(:normalize)
          workspace.run_callbacks(:save, false)
        end
      end
    end
  end

  context 'columns' do
    it { should have_db_column(:boundary).of_type(:string).with_options(:limit => 4 * (2 ** 10)) }
    it { should have_db_column(:description).of_type(:string).with_options(:limit => 4 * (2 ** 10)) }
    it { should have_db_column(:limit_to_network).of_type(:boolean).with_options(:default => false, :null => false) }
    it { should have_db_column(:name).of_type(:string) }
    it { should have_db_column(:owner_id).of_type(:integer) }

    context 'timestamps' do
      it { should have_db_column(:created_at).of_type(:datetime).with_options(:null => false) }
      it { should have_db_column(:updated_at).of_type(:datetime).with_options(:null => false) }
    end
  end

  context 'CONSTANTS' do
    it 'should define the DEFAULT name' do
      described_class::DEFAULT.should == default
    end
  end

  context 'validations' do
    context 'boundary' do
      let(:boundary) do
        nil
      end

      let(:error) do
        'must be a valid IP range'
      end

      before(:each) do
        workspace.boundary = boundary
        workspace.valid?
      end

      it 'should validate using #valid_ip_or_range?', :pending => 'https://www.pivotaltracker.com/story/show/43244445'  do
        workspace.should_receive(:valid_ip_or_range?).with(boundary).and_return(false)

        workspace.valid?
      end

      context 'with valid IP' do
        let(:boundary) do
          '192.168.0.1'
        end

        it 'should not record an error' do
          workspace.errors[:boundary].should_not include(error)
        end
      end

      context 'with valid range' do
        let(:boundary) do
          '192.168.0.1/24'
        end

        it 'should not record an error' do
          workspace.errors[:boundary].should_not include(error)
        end
      end

      context 'with invalid IP or range' do
        let(:boundary) do
          '192.168'
        end

        it 'should record error that boundary must be a valid IP range', :pending => 'https://www.pivotaltracker.com/story/show/43171927' do
          workspace.should_not be_valid
          workkspace.errors[:boundary].should include(error)
        end
      end
    end

    context 'description' do
      it { should ensure_length_of(:description).is_at_most(4 * (2 ** 10)) }
    end

    context 'name' do
      it { should ensure_length_of(:name).is_at_most(2**8 - 1) }
      it { should validate_presence_of :name }
      it { should validate_uniqueness_of :name }
    end
  end

  context 'methods' do
    let(:hosts) do
      FactoryGirl.create_list(:mdm_host, 2, :workspace => workspace)
    end

    let(:other_hosts) do
      FactoryGirl.create_list(:mdm_host, 2, :workspace => other_workspace)
    end

    let(:other_services) do
      other_hosts.collect do |host|
        FactoryGirl.create(:mdm_service, :host => host)
      end
    end

    let(:other_web_sites) do
      other_services.collect { |service|
        FactoryGirl.create(:mdm_web_site, :service => service)
      }
    end

    let(:other_workspace) do
      FactoryGirl.create(:mdm_workspace)
    end

    let(:services) do
      hosts.collect do |host|
        FactoryGirl.create(:mdm_service, :host => host)
      end
    end

    let(:web_sites) do
      services.collect { |service|
        FactoryGirl.create(:mdm_web_site, :service => service)
      }
    end

    context 'default' do
      context 'with default workspace' do
        before(:each) do
          FactoryGirl.create(
              :mdm_workspace,
              :name => default
          )
        end

        it 'should not create workspace' do
          workspace = nil

          expect {
            workspace = described_class.default
          }.to change(Mdm::Workspace, :count).by(0)

          workspace.should be_default
        end
      end

      context 'without default workspace' do
        it 'should create workspace' do
          workspace = nil

          expect {
            workspace = described_class.default
          }.to change(Mdm::Workspace, :count).by(1)

          workspace.should be_default
        end
      end
    end

    context '#default?' do
      subject do
        workspace.default?
      end

      context 'with DEFAULT name' do
        before(:each) do
          workspace.name = default
        end

        it {
          should be_true
        }
      end

      context 'without DEFAULT name' do
        it { should be_false }
      end
    end

    context '#normalize' do
      let(:normalize) do
        workspace.send(:normalize)
      end

      before(:each) do
        workspace.boundary = boundary
      end

      context 'with boundary' do
        let(:boundary) do
          " #{stripped_boundary} "
        end

        let(:stripped_boundary) do
          '192.168.0.1'
        end

        it "should remove spaces" do
          normalize

          workspace.boundary.should == stripped_boundary
        end
      end

      context 'without boundary' do
        let(:boundary) do
          nil
        end

        it 'should not raise error' do
          expect {
            normalize
          }.to_not raise_error
        end
      end
    end

    context '#web_forms' do

      subject do
        workspace.web_forms
      end

      #
      # Let!s (let + before(:each))
      #

      let!(:other_web_forms) do
        other_web_sites.collect { |web_site|
          FactoryGirl.create(:web_form, :web_site => web_site)
        }
      end

      let!(:web_forms) do
        web_sites.collect { |web_site|
          FactoryGirl.create(:web_form, :web_site => web_site)
        }
      end

      it 'should return an ActiveRecord:Relation',
         :pending => 'https://www.pivotaltracker.com/story/show/43219917' do
        should be_a ActiveRecord::Relation
      end

      it 'should return only Mdm::WebPages from hosts in the workspace' do
        found_web_forms = workspace.web_forms

        found_web_forms.length.should == web_forms.length

        found_web_forms.all? { |web_form|
          web_form.web_site.service.host.workspace == workspace
        }.should be_true
      end
    end

    context '#web_sites' do
      subject do
        workspace.web_sites
      end

      #
      # Let!s (let + before(:each))
      #

      before(:each) do
        other_web_sites
        web_sites
      end

      it 'should return an ActiveRecord:Relation',
         :pending => 'https://www.pivotaltracker.com/story/show/43219917' do
        should be_a ActiveRecord::Relation
      end

      it 'should return only Mdm::WebVulns from hosts in the workspace' do
        # there are more web sites than those in the workspace
        Mdm::WebSite.count.should > web_sites.count

        found_web_sites = workspace.web_sites

        found_web_sites.length.should == web_sites.count

        found_web_sites.all? { |web_site|
          web_site.service.host.workspace == workspace
        }.should be_true
      end
    end

    context '#web_vulns' do
      subject do
        workspace.web_vulns
      end

      #
      # Let!s (let + before(:each))
      #

      let!(:other_web_vulns) do
        other_web_sites.collect { |web_site|
          FactoryGirl.create(:mdm_web_vuln, :web_site => web_site)
        }
      end

      let!(:web_vulns) do
        web_sites.collect { |web_site|
          FactoryGirl.create(:mdm_web_vuln, :web_site => web_site)
        }
      end

      it 'should return an ActiveRecord:Relation',
         :pending => 'https://www.pivotaltracker.com/story/show/43219917' do
        should be_a ActiveRecord::Relation
      end

      it 'should return only Mdm::WebVulns from hosts in the workspace' do
        Mdm::WebVuln.count.should > web_vulns.length

        found_web_vulns = workspace.web_vulns

        found_web_vulns.length.should == web_vulns.length

        found_web_vulns.all? { |web_vuln|
          web_vuln.web_site.service.host.workspace == workspace
        }.should be_true

      end
    end

    context '#web_unique_forms' do
      let(:rejected_address) do
        hosts[1].address
      end

      let(:selected_address) do
        hosts[0].address
      end

      it 'should return an ActiveRecord:Relation',
         :pending => 'https://www.pivotaltracker.com/story/show/43219917' do
        should be_a ActiveRecord::Relation
      end

      it "should reject #unique_web_forms from host addresses that aren't in addresses" do
        web_forms = workspace.web_unique_forms([selected_address])

        web_forms.all? { |web_form|
          web_form.web_site.service.host.address.should == selected_address
        }.should be_true
      end
    end
  end

end