# Copyright © 2011-2020 MUSC Foundation for Research Development
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

RSpec.describe 'User manages Catalog Managers', js: true do
  let_there_be_lane
  fake_login_for_each_test

  before :each do
    @institution = create(:institution)
    @provider = create(:provider, :with_subsidy_map, parent_id: @institution.id)
    @identity    = create(:identity)
    create(:catalog_manager, organization_id: @institution.id, identity_id: Identity.where(ldap_uid: 'jug2').first.id)
  end

  context 'on a Provider' do
    context 'and the identity is already a Catalog Manager' do
      context 'with edit historic data access' do
        before :each do
          create(:catalog_manager, identity: @identity, organization: @provider, edit_historic_data: true)

          visit catalog_manager_catalog_index_path
          wait_for_javascript_to_finish
          find("#institution-#{@institution.id}").click
          wait_for_javascript_to_finish
          click_link @provider.name
          wait_for_javascript_to_finish

          click_link 'User Rights'
          wait_for_javascript_to_finish
        end

        it 'should delete the Catalog Manager for the identity' do
          find('#catalog_manager').click
          wait_for_javascript_to_finish

          expect(CatalogManager.where(identity_id: @identity.id, organization_id: @provider.id).count).to eq(0)
        end

        it 'should remove edit historic data access' do
          find("#cm-edit-historic-data-#{@identity.id}").click
          wait_for_javascript_to_finish

          expect(CatalogManager.where(identity_id: @identity.id, organization_id: @provider.id).first.edit_historic_data).to eq(false)
        end
      end

      context 'without edit historic data access' do
        before :each do
          create(:catalog_manager, identity: @identity, organization: @provider, edit_historic_data: false)

          visit catalog_manager_catalog_index_path
          wait_for_javascript_to_finish
          find("#institution-#{@institution.id}").click
          wait_for_javascript_to_finish
          click_link @provider.name
          wait_for_javascript_to_finish

          click_link 'User Rights'
          wait_for_javascript_to_finish
        end

        it 'should delete the Catalog Manager for the identity' do
          find('#catalog_manager').click
          wait_for_javascript_to_finish

          expect(CatalogManager.where(identity_id: @identity.id, organization_id: @provider.id).count).to eq(0)
        end

        it 'should add edit historic data access' do
          find("#cm-edit-historic-data-#{@identity.id}").click
          wait_for_javascript_to_finish

          expect(CatalogManager.where(identity_id: @identity.id, organization_id: @provider.id).first.edit_historic_data).to eq(true)
        end
      end
    end

    context 'and the identity is not already a Catalog Manager' do
      before :each do
        allow_any_instance_of(Organization).to receive(:all_user_rights).and_return( [@identity] )

        visit catalog_manager_catalog_index_path
        wait_for_javascript_to_finish
        find("#institution-#{@institution.id}").click
        wait_for_javascript_to_finish
        click_link @provider.name
        wait_for_javascript_to_finish

        click_link 'User Rights'
        wait_for_javascript_to_finish
      end

      it 'should create a Catalog Manager for the identity' do
        find('#catalog_manager').click
        wait_for_javascript_to_finish

        expect(CatalogManager.where(identity_id: @identity.id, organization_id: @provider.id, edit_historic_data: nil).count).to eq(1)
          expect(page).to have_selector('.cm-edit-historic-data:not(:checked)')
          expect(page).to have_selector('.cm-edit-historic-data:not(:disabled)')
      end
    end
  end

end
