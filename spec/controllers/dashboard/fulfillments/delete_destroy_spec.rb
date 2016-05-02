require "rails_helper"

RSpec.describe Dashboard::FulfillmentsController do
  describe "DELETE #destroy" do
    before(:each) do
      @fulfillment = findable_stub(Fulfillment) do
        instance_double(Fulfillment, id: 1)
      end
      allow(@fulfillment).to receive(:delete)

      logged_in_user = create(:identity)
      log_in_dashboard_identity(obj: logged_in_user)
      xhr :delete, :destroy, id: 1
    end

    it "should destroy Fulfillment from params[:id]" do
      expect(@fulfillment).to have_received(:delete)
    end

    it { is_expected.to respond_with :ok }
    it { is_expected.to render_template "dashboard/fulfillments/destroy" }
  end
end
