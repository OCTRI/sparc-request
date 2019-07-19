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

$(document).on 'turbolinks:load', ->
  # Tempus Dominus has some annoying bugs caused by DateTimePickers
  # being set to a blank value. This is a workaround.

  ####################
  # Start & End Date #
  ####################

  startDate = $('#protocolStartDatePicker').data().date
  endDate   = $('#protocolEndDatePicker').data().date

  if startDate
    $('#protocolEndDatePicker').datetimepicker('minDate', startDate)
    if !endDate
      $('#protocol_end_date').val('')

  $('#protocolStartDatePicker').on 'change.datetimepicker', ->
    startDate = $('#protocol_start_date').val()
    endDate   = $('#protocol_end_date').val()

    if startDate
      $('#protocolEndDatePicker').datetimepicker('minDate', startDate)
      $('#protocol_end_date').focus()
      if !endDate
        $('#protocol_end_date').val(startDate).blur().focus()
    else
      $('#protocolEndDatePicker').datetimepicker('minDate', false)

  $(document).on 'click', '#protocol_end_date', ->
    if (startDate = $('#protocol_start_date').val()) && !$(this).val()
      $(this).val(startDate).blur().focus()

  ################################
  # Recruitment Start & End Date #
  ################################

  recruitmentStartDate = $('#protocolRecruitmentStartDatePicker').data().date
  recruitmentEndDate   = $('#protocolRecruitmentEndDatePicker').data().date

  if recruitmentStartDate
    $('#protocolRecruitmentEndDatePicker').datetimepicker('minDate', recruitmentStartDate)
    if !recruitmentEndDate
      $('#protocol_recruitment_end_date').val('')

  $('#protocolRecruitmentStartDatePicker').on 'change.datetimepicker', ->
    recruitmentStartDate = $('#protocol_recruitment_start_date').val()
    recruitmentEndDate   = $('#protocol_recruitment_end_date').val()

    if recruitmentStartDate
      $('#protocolRecruitmentEndDatePicker').datetimepicker('minDate', recruitmentStartDate)
      $('#protocol_recruitment_end_date').focus()
      if !recruitmentEndDate
        $('#protocol_recruitment_end_date').val(recruitmentStartDate).blur().focus()
    else
      $('#protocolRecruitmentEndDatePicker').datetimepicker('minDate', false)

  $(document).on 'click', '#protocol_recruitment_end_date', ->
    if (recruitmentStartDate = $('#protocol_recruitment_start_date').val()) && !$(this).val()
      $(this).val(recruitmentStartDate).blur().focus()

  ###################
  # Initial Amounts #
  ###################

  if $('#protocol_initial_budget_sponsor_received_date').val()
    $('#initialAmountClinicalContainer, #initialAmountNonClinicalContainer').removeClass('d-none')

  $('#protocolInitialBudgetSponsorReceivedDatePicker').on 'change.datetimepicker', ->
    if $('#protocol_initial_budget_sponsor_received_date').val()
      $('#initialAmountClinicalContainer, #initialAmountNonClinicalContainer').removeClass('d-none')
    else
      $('#initialAmountClinicalContainer, #initialAmountNonClinicalContainer').addClass('d-none')

  ######################
  # Negotiated Amounts #
  ######################

  if $('#protocol_budget_agreed_upon_date').val()
    $('#negotiatedAmountClinicalContainer, #negotiatedAmountNonClinicalContainer').removeClass('d-none')

  $('#protocolBudgetAgreedUponDatePicker').on 'change.datetimepicker', ->
    if $('#protocol_budget_agreed_upon_date').val()
      $('#negotiatedAmountClinicalContainer, #negotiatedAmountNonClinicalContainer').removeClass('d-none')
    else
      $('#negotiatedAmountClinicalContainer, #negotiatedAmountNonClinicalContainer').addClass('d-none')
