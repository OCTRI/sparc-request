# Copyright © 2011 MUSC Foundation for Research Development
# All rights reserved.

# Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

# 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

# 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following
# disclaimer in the documentation and/or other materials provided with the distribution.

# 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products
# derived from this software without specific prior written permission.

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING,
# BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
# SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
# TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
require 'rails_helper'

RSpec.describe CatalogsController, type: :controller do
  stub_controller
  let!(:before_filters) { find_before_filters }
  let!(:logged_in_user) { create(:identity) }

  describe '#update_description' do
    it 'should call before_filter #initialize_service_request' do
      expect(before_filters.include?(:initialize_service_request)).to eq(true)
    end

    it 'should call before_filter #authorize_identity' do
      expect(before_filters.include?(:authorize_identity)).to eq(true)
    end

    it 'should call before_filter #find_locked_org_ids' do
      expect(before_filters.include?(:find_locked_org_ids)).to eq(true)
    end

    it 'should assign @organization' do
      protocol  = create(:protocol_without_validations, primary_pi: logged_in_user)
      sr        = create(:service_request_without_validations, protocol: protocol)
      org       = create(:organization)

      session[:service_request_id] = sr.id

      xhr :post, :update_description, {
        id: org.id
      }

      expect(assigns(:organization)).to eq(org)
    end

    it 'should assign @process_ssr_found' do
      protocol  = create(:protocol_without_validations, primary_pi: logged_in_user)
      sr        = create(:service_request_without_validations, protocol: protocol)
      org       = create(:organization)

      session[:service_request_id] = sr.id

      xhr :post, :update_description, {
        id: org.id,
        process_ssr_found: 'true'
      }

      expect(assigns(:process_ssr_found)).to eq(true)
    end

    context '@sub_service_request present' do
      it 'should assign @ssr_org' do
        protocol  = create(:protocol_without_validations, primary_pi: logged_in_user)
        sr        = create(:service_request_without_validations, protocol: protocol)
        org       = create(:organization)
        ssr       = create(:sub_service_request_without_validations, service_request: sr, organization: org)

      session[:service_request_id]     = sr.id
      session[:sub_service_request_id] = ssr.id

      xhr :post, :update_description, {
        id: org.id,
        process_ssr_found: 'true'
      }

      expect(assigns(:ssr_org)).to eq(org)
      end
    end

    it 'should render template' do
      protocol  = create(:protocol_without_validations, primary_pi: logged_in_user)
      sr        = create(:service_request_without_validations, protocol: protocol)
      org       = create(:organization)

      session[:service_request_id] = sr.id

      xhr :post, :update_description, {
        id: org.id
      }

      expect(controller).to render_template(:update_description)
    end

    it 'should respond ok' do
      protocol  = create(:protocol_without_validations, primary_pi: logged_in_user)
      sr        = create(:service_request_without_validations, protocol: protocol)
      org       = create(:organization)

      session[:service_request_id] = sr.id

      xhr :post, :update_description, {
        id: org.id
      }

      expect(controller).to respond_with(:ok)
    end
  end
end