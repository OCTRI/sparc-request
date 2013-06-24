require 'spec_helper'

describe Portal::ServiceRequestsController do

  let_there_be_lane
  fake_login_for_each_test
  let_there_be_j
  build_service_request_with_study
  stub_portal_controller

  before(:each) do
    session[:identity_id] = jug2
  end
  
  describe 'GET show' do
    it 'should set instance variables' do
      session[:service_calendar_page] = 1
      get :show, {
        format: :js,
        id: service_request.id,
        arm_id: arm1.id,
      }.with_indifferent_access

      service_request.reload

      assigns(:service_request).should eq service_request

      # Not using assigns() here since it calls with_indifferent_access
      controller.instance_eval { @service_list }.should eq service_request.service_list

      assigns(:protocol).should eq service_request.protocol
      assigns(:pages).should eq({ arm1.id => 1, arm2.id => 1 })
      assigns(:tab).should eq 'pricing'
    end
  end

  describe 'POST add_per_patient_per_visit_visit' do
    it 'should set instance variables' do
      post :add_per_patient_per_visit_visit, {
        format: :js,
        id: service_request.id,
        arm_id: arm1.id,
        service_request_id: service_request.id,
        sub_service_request_id: sub_service_request.id,
        visit_name: 'Test Name',
        visit_day: 20,
        visit_window: 10,
      }.with_indifferent_access

      assigns(:sub_service_request).should eq sub_service_request
      assigns(:subsidy).should eq subsidy
      assigns(:candidate_per_patient_per_visit).should eq [ service2 ]
      assigns(:service_request).should eq service_request
    end

    # TODO: test candidate_per_patient_per_visit

    it 'should add a visit' do
      # Ensure that the LineItemsVisits are created; the fixtures do not
      # create them for us.  Only line_item2 is pppv, so it's the only
      # one that should get a LineItemsVisit.
      LineItemsVisit.for(arm1, line_item2)

      post :add_per_patient_per_visit_visit, {
        format: :js,
        id: service_request.id,
        arm_id: arm1.id,
        service_request_id: service_request.id,
        sub_service_request_id: sub_service_request.id,
        visit_name: 'Test Name',
        visit_day: 20,
        visit_window: 10,
      }.with_indifferent_access

      LineItemsVisit.for(arm1, line_item).visits.count.should eq 0
      LineItemsVisit.for(arm1, line_item2).visits.count.should eq 1
    end

    # TODO: test visit_position

    it 'should call fix_pi_contribution on the subsidy' do
      # TODO
    end

    it 'should create toasts for each of the new visits created' do
      # TODO
    end
  end

  describe 'POST remove_per_patient_per_visit_visit' do
    before(:each) do
      arm1.update_attributes(visit_count: 10)
      add_visits
    end

    it 'should set instance variables' do
      post :remove_per_patient_per_visit_visit, {
        format: :js,
        id: service_request.id,
        arm_id: arm1.id,
        service_request_id: service_request.id,
        sub_service_request_id: sub_service_request.id,
        visit_position: 2,
      }.with_indifferent_access

      assigns(:sub_service_request).should eq sub_service_request
      assigns(:subsidy).should eq subsidy
      assigns(:candidate_per_patient_per_visit).should eq [ service2 ]
      assigns(:service_request).should eq service_request
    end

    it 'should remove the visit at the given position' do
      # Ensure that the LineItemsVisits are created; the fixtures do not
      # create them for us.  Only line_item2 is pppv, so it's the only
      # one that should get a LineItemsVisit.
      LineItemsVisit.for(arm1, line_item2)

      visit_count = arm1.line_items_visits.first.visits.count
      post :remove_per_patient_per_visit_visit, {
        format: :js,
        id: service_request.id,
        arm_id: arm1.id,
        service_request_id: service_request.id,
        sub_service_request_id: sub_service_request.id,
        visit_position: 2,
      }.with_indifferent_access

      LineItemsVisit.for(arm1, line_item).visits.count.should eq(0)
      LineItemsVisit.for(arm1, line_item2).visits.count.should eq(visit_count - 1)
      # TODO: test that the right visit was removed
    end

    it 'should call fix_pi_contribution on the subsidy' do
      # TODO
    end

    it 'should create toasts for each of the new visits created' do
      # TODO
    end
  end

  describe 'POST update_from_fulfillment' do
    # TODO
  end
end

