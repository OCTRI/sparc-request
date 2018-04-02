# Copyright © 2011-2017 MUSC Foundation for Research Development
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

RSpec.describe Surveyor::SurveysController, type: :controller do
  stub_controller
  let!(:before_filters) { find_before_filters }

  describe '#search_surveyables' do
    it 'should call before_filter #authenticate_identity!' do
      expect(before_filters.include?(:authenticate_identity!)).to eq(true)
    end

    it 'should call before_filter #authorize_survey_builder_access' do
      expect(before_filters.include?(:authorize_survey_builder_access)).to eq(true)
    end

    context 'organizations' do
      context 'organization is split/notify' do
        context 'user does not have super user or service provider rights' do
          it 'should not return the organization' do
            logged_in_user    = create(:identity)
            process_ssrs_org  = create(:core, name: 'Test Organization', abbreviation: 'test.orgz', process_ssrs: true)
                                create(:super_user, identity: logged_in_user, organization: create(:organization))

            session[:identity_id] = logged_in_user.id

            get :search_surveyables, params: { term: 'test' }, xhr: true

            results = JSON.parse(response.body)
            
            expect(results.count).to eq(0)
          end
        end

        context 'user has catalog overlord rights' do
          it 'should return the organization' do
            logged_in_user    = create(:identity, catalog_overlord: true)
            process_ssrs_org  = create(:core, name: 'Test Organization', abbreviation: 'test.orgz', process_ssrs: true)

            session[:identity_id] = logged_in_user.id

            get :search_surveyables, params: { term: 'test' }, xhr: true

            results = JSON.parse(response.body)
            
            expect(results.count).to eq(1)
            expect(results[0]['value']).to eq(process_ssrs_org.id)
          end
        end

        context 'user has super user rights' do
          context 'organization is available' do
            it 'should return the organization' do
              logged_in_user    = create(:identity)
              process_ssrs_org  = create(:core, name: 'Test Organization', abbreviation: 'test.orgz', process_ssrs: true)
                                  create(:super_user, organization: process_ssrs_org, identity: logged_in_user)

              session[:identity_id] = logged_in_user.id

              get :search_surveyables, params: { term: 'test' }, xhr: true

              results = JSON.parse(response.body)
              
              expect(results.count).to eq(1)
              expect(results[0]['value']).to eq(process_ssrs_org.id)
            end
          end

          context 'organization is not available' do
            it 'should not return the organization' do
              logged_in_user    = create(:identity)
              process_ssrs_org  = create(:core, name: 'Test Organization', abbreviation: 'test.orgz', process_ssrs: true, is_available: false)
                                  create(:super_user, organization: process_ssrs_org, identity: logged_in_user)

              session[:identity_id] = logged_in_user.id

              get :search_surveyables, params: { term: 'test' }, xhr: true

              results = JSON.parse(response.body)
              
              expect(results.count).to eq(0)
            end
          end
        end

        context 'user has service provider rights' do
          context 'organization is available' do
            it 'should return the organization' do
              logged_in_user    = create(:identity)
              process_ssrs_org  = create(:core, name: 'Test Organization', abbreviation: 'test.orgz', process_ssrs: true)
                                  create(:service_provider, organization: process_ssrs_org, identity: logged_in_user)

              session[:identity_id] = logged_in_user.id

              get :search_surveyables, params: { term: 'test' }, xhr: true

              results = JSON.parse(response.body)
              
              expect(results.count).to eq(1)
              expect(results[0]['value']).to eq(process_ssrs_org.id)
            end
          end

          context 'organization is not available' do
            it 'should not return the organization' do
              logged_in_user    = create(:identity)
              process_ssrs_org  = create(:core, name: 'Test Organization', abbreviation: 'test.orgz', process_ssrs: true, is_available: false)
                                  create(:service_provider, organization: process_ssrs_org, identity: logged_in_user)

              session[:identity_id] = logged_in_user.id

              get :search_surveyables, params: { term: 'test' }, xhr: true

              results = JSON.parse(response.body)
              
              expect(results.count).to eq(0)
            end
          end
        end
      end

      context 'organization is not split/notify' do
        it 'should not return the organization' do
          logged_in_user  = create(:identity)
          bad_org         = create(:core, name: 'Testing Organization', abbreviation: 'test.org', process_ssrs: false)
                            create(:super_user, organization: bad_org, identity: logged_in_user)

          session[:identity_id] = logged_in_user.id

          get :search_surveyables, params: { term: 'test' }, xhr: true

          results = JSON.parse(response.body)
          
          expect(results.count).to eq(0)
        end
      end
    end

    context 'services' do
      context 'user does not have super user or service provider rights' do
        it 'should not return the service' do
          logged_in_user  = create(:identity)
          org             = create(:core, name: 'Testing Organization', abbreviation: 'test.org', process_ssrs: false)
          service         = create(:service, name: 'Testing Service', abbreviation: 'test.serv', organization: org)
                            create(:super_user, identity: logged_in_user, organization: create(:organization))

          session[:identity_id] = logged_in_user.id

          get :search_surveyables, params: { term: 'test' }, xhr: true

          results = JSON.parse(response.body)
          
          expect(results.count).to eq(0)
        end
      end

      context 'user has catalog overlord rights' do
        it 'should return the service' do
          logged_in_user  = create(:identity, catalog_overlord: true)
          org             = create(:core, name: 'Testing Organization', abbreviation: 'test.org', process_ssrs: false)
          service         = create(:service, name: 'Testing Service', abbreviation: 'test.serv', organization: org)

          session[:identity_id] = logged_in_user.id

          get :search_surveyables, params: { term: 'test' }, xhr: true

          results = JSON.parse(response.body)
          
          expect(results.count).to eq(1)
          expect(results[0]['value']).to eq(service.id)
        end
      end

      context 'user has super user rights' do
        context 'service is available' do
          it 'should return the service' do
            logged_in_user  = create(:identity)
            org             = create(:core, name: 'Testing Organization', abbreviation: 'test.org', process_ssrs: false)
            service         = create(:service, name: 'Testing Service', abbreviation: 'test.serv', organization: org)
                              create(:super_user, organization: org, identity: logged_in_user)

            session[:identity_id] = logged_in_user.id

            get :search_surveyables, params: { term: 'test' }, xhr: true

            results = JSON.parse(response.body)
            
            expect(results.count).to eq(1)
            expect(results[0]['value']).to eq(service.id)
          end
        end

        context 'service is not available' do
          it 'should not return the service' do
            logged_in_user  = create(:identity)
            org             = create(:core, name: 'Testing Organization', abbreviation: 'test.org', process_ssrs: false)
            service         = create(:service, name: 'Testing Service', abbreviation: 'test.serv', organization: org, is_available: false)
                              create(:super_user, organization: org, identity: logged_in_user)

            session[:identity_id] = logged_in_user.id

            get :search_surveyables, params: { term: 'test' }, xhr: true

            results = JSON.parse(response.body)
            
            expect(results.count).to eq(0)
          end
        end
      end

      context 'user has service provider rights' do
        context 'service is available' do
          it 'should return the service' do
            logged_in_user  = create(:identity)
            org             = create(:core, name: 'Testing Organization', abbreviation: 'test.org', process_ssrs: false)
            service         = create(:service, name: 'Testing Service', abbreviation: 'test.serv', organization: org)
                              create(:service_provider, organization: org, identity: logged_in_user)

            session[:identity_id] = logged_in_user.id

            get :search_surveyables, params: { term: 'test' }, xhr: true

            results = JSON.parse(response.body)
            
            expect(results.count).to eq(1)
            expect(results[0]['value']).to eq(service.id)
          end
        end

        context 'service is not available' do
          it 'should not return the service' do
            logged_in_user  = create(:identity)
            org             = create(:core, name: 'Testing Organization', abbreviation: 'test.org', process_ssrs: false)
            service         = create(:service, name: 'Testing Service', abbreviation: 'test.serv', organization: org, is_available: false)
                              create(:service_provider, organization: org, identity: logged_in_user)

            session[:identity_id] = logged_in_user.id

            get :search_surveyables, params: { term: 'test' }, xhr: true

            results = JSON.parse(response.body)
            
            expect(results.count).to eq(0)
          end
        end
      end
    end
  end
end
