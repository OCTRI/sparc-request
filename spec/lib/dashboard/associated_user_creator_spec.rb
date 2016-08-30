require "rails_helper"

RSpec.describe Dashboard::AssociatedUserCreator do

  context "params[:project_role] describes a valid ProjectRole" do
    before(:each) do
      @identity = create(:identity)
      @user          = create(:identity)
      @protocol      = create(:protocol_without_validations, selected_for_epic: false, funding_status: 'funded', funding_source: 'federal', type: 'Study')
      create(:project_role, protocol: @protocol, identity: @user, project_rights: 'approve', role: 'primary-pi')
      @ssr = create(:sub_service_request, status: 'not_draft', organization: create(:organization), service_request: create(:service_request_without_validations, protocol: @protocol))

      @project_role_attrs = { protocol_id: @protocol.id,
        identity_id: @identity.id,
        role: "important",
        project_rights: "to-party" }

    end

    it "#successful? should return true" do
      creator = Dashboard::AssociatedUserCreator.new(@project_role_attrs)
      expect(creator.successful?).to eq(true)
    end

    it "should create a new ProjectRole for Protocol from params[:project_role][:protocol_id]" do
      expect { Dashboard::AssociatedUserCreator.new(@project_role_attrs) }.to change { ProjectRole.count }.by(1)
    end

    it "should return new ProjectRole with #protocol_role" do
      creator = Dashboard::AssociatedUserCreator.new(@project_role_attrs)
      expect(creator.protocol_role).to eq(ProjectRole.last)
    end

    context "SEND_AUTHORIZED_USER_EMAILS: true && protocol has non-draft status" do
      it "should send authorized user changed emails" do
        stub_const("SEND_AUTHORIZED_USER_EMAILS", true)
        expect(UserMailer).to receive(:authorized_user_changed).twice do
          mailer = double("mailer")
          expect(mailer).to receive(:deliver)
          mailer
        end
        Dashboard::AssociatedUserCreator.new(@project_role_attrs)
      end
    end

    context "SEND_AUTHORIZED_USER_EMAILS: true && protocol has draft status" do
      it "should NOT send authorized user changed emails" do
        stub_const("SEND_AUTHORIZED_USER_EMAILS", true)
        @ssr.update_attribute(:status, 'draft')
        allow(UserMailer).to receive(:authorized_user_changed)
        Dashboard::AssociatedUserCreator.new(@project_role_attrs)
        expect(UserMailer).not_to have_received(:authorized_user_changed)
      end
    end

    context "SEND_AUTHORIZED_USER_EMAILS false" do
      it "should not send authorized user changed emails" do
        stub_const("SEND_AUTHORIZED_USER_EMAILS", false)
        @ssr.update_attribute(:status, 'complete')
        allow(UserMailer).to receive(:authorized_user_changed)
        Dashboard::AssociatedUserCreator.new(@project_role_attrs)
        expect(UserMailer).not_to have_received(:authorized_user_changed)
      end
    end

    context "USE_EPIC == true && Protocol selected for epic && protocol.selected_for_epic: true && QUEUE_EPIC == false" do
      it "should notify for epic user approval" do
        @protocol.update_attribute(:selected_for_epic, true)
        stub_const("USE_EPIC", true)
        stub_const("QUEUE_EPIC", false)
        allow(Notifier).to receive(:notify_for_epic_user_approval) do
          mailer = double("mailer")
          expect(mailer).to receive(:deliver)
          mailer
        end

        Dashboard::AssociatedUserCreator.new(@project_role_attrs)

        expect(Notifier).to have_received(:notify_for_epic_user_approval)
      end
    end
  end

  context "params[:project_role] does not describe a valid ProjectRole" do
    before(:each) do
      protocol = create(:study_without_validations,
        primary_pi: create(:identity),
        selected_for_epic: true)
      identity = create(:identity)
      # missing :role
      @project_role_attrs = { protocol_id: protocol.id,
        identity_id: identity.id,
        project_rights: "to-party" }
    end

    it "#successful? should return false" do
      creator = Dashboard::AssociatedUserCreator.new(@project_role_attrs)
      expect(creator.successful?).to eq(false)
    end

    it "should not create a new ProjectRole" do
      expect { Dashboard::AssociatedUserCreator.new(@project_role_attrs) }.not_to change { ProjectRole.count }
    end

    context "SEND_AUTHORIZED_USER_EMAILS true" do
      it "should not send authorized user changed emails" do
        stub_const("SEND_AUTHORIZED_USER_EMAILS", true)
        allow(UserMailer).to receive(:authorized_user_changed)

        Dashboard::AssociatedUserCreator.new(@project_role_attrs)

        expect(UserMailer).not_to have_received(:authorized_user_changed)
      end
    end

    context "USE_EPIC == true && Protocol selected for epic && QUEUE_EPIC == false" do
      it "should not notify for epic user approval" do
        stub_const("USE_EPIC", true)
        stub_const("QUEUE_EPIC", false)
        allow(Notifier).to receive(:notify_for_epic_user_approval)

        Dashboard::AssociatedUserCreator.new(@project_role_attrs)

        expect(Notifier).not_to have_received(:notify_for_epic_user_approval)
      end
    end
  end
end