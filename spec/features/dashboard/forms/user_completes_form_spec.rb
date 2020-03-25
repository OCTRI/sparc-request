# Copyright © 2011-2019 MUSC Foundation for Research Development
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

RSpec.describe 'User completes a form', js: true do
  let_there_be_lane
  fake_login_for_each_test

  before :each do
    org       = create(:organization, name: "Program", process_ssrs: true)
    @service  = create(:service, name: "My Service", abbreviation: "My Service", organization: org)
    @protocol = create(:protocol_federally_funded, type: 'Study', primary_pi: jug2)
    @sr       = create(:service_request_without_validations, protocol: @protocol)
    ssr       = create(:sub_service_request_without_validations, protocol: @protocol, service_request: @sr, organization: org)
                create(:line_item, service_request: @sr, sub_service_request: ssr, service: @service)
    @form     = create(:form, :with_question, surveyable: @service, active: true)

    visit dashboard_protocol_path(@protocol)
    wait_for_javascript_to_finish
  end

  it 'should complete the form' do
    find('.complete-forms').click
    find('.complete-forms + .dropdown-menu .dropdown-item', text: @form.title).click
    wait_for_javascript_to_finish

    fill_in 'response_question_responses_attributes_0_content', with: 'My answer is no'

    click_button I18n.t('actions.submit')
    wait_for_javascript_to_finish

    expect(jug2.reload.responses.count).to eq(1)
    expect(jug2.responses.first.question_responses.first.content).to eq('My answer is no')
    expect(page).to have_selector('#formsTable tbody tr td', text: @form.title)
    expect(page).to have_no_selector('.complete-forms')
  end
end
