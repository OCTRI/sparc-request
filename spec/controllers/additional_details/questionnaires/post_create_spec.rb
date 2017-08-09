# Copyright © 2011-2016 MUSC Foundation for Research Development~
# All rights reserved.~

# Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:~

# 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.~

# 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following~
# disclaimer in the documentation and/or other materials provided with the distribution.~

# 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products~
# derived from this software without specific prior written permission.~

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING,~
# BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT~
# SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL~
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS~
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR~
# TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.~

require 'rails_helper'

RSpec.describe AdditionalDetails::QuestionnairesController do
  stub_controller
  let!(:logged_in_user) { create(:identity) }

  describe '#create' do
    before :each do
      @service = create(:service)
    end

    it 'should assign @service' do
      post :create, params: {
        questionable_id: @service.id,
        questionable_type: 'Service',
        questionnaire: {
          name: 'string',
          items_attributes: {
            '0' => {
              content: 'test',
              item_type:'text',
              required: '1'
            }
          }
        }
      }, format: :js

      expect(assigns(:questionable)).to eq(@service)
    end

    it 'should assign @questionnaire' do
      post :create, params: {
        questionable_id: @service.id,
        questionable_type: 'Service',
        questionnaire: {
          name: 'string',
          items_attributes: {
            '0' => {
              content: 'test',
              item_type:'text',
              required: '1'
            }
          }
        }
      }, format: :js

      expect(assigns(:questionnaire)).to be_a(Questionnaire)
    end

    context 'successful' do
      before :each do
        post :create, params: {
          questionable_id: @service.id,
          questionable_type: 'Service',
          questionnaire: {
            name: 'string',
            items_attributes: { 
              '0' => { 
                content: 'test',
                item_type:'text',
                required: '1'
              }
            }
          }
        }, format: :js
      end

      it 'should create a questionnaire' do
        expect(Questionnaire.count).to eq(1)
      end

      it 'should create items' do
        expect(Item.count).to eq(1)
      end

      it { is_expected.to redirect_to(action: :index, questionable_id: @service.id, questionable_type: 'Service') }

      it { is_expected.to respond_with(302) }
    end

    context 'unsuccessful' do
      before :each do
        post :create, params: {
          questionable_id: @service.id,
          questionable_type: 'Service',
          questionnaire: {
            items_attributes: { 
              '0' => { 
                content: 'test'
              }
            }
          }
        }, format: :js
      end

      it 'should not create a questionnaire' do
        expect(Questionnaire.count).to eq(0)
      end

      it 'should not create items' do
        expect(Item.count).to eq(0)
      end

      it { is_expected.to render_template(:new) }

      it { is_expected.to respond_with(:ok) }
    end
  end
end
