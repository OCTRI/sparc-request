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

<% if @errors %>
$("#modalContainer #modal_errors").html("<%= escape_javascript(render( '/layouts/modal_errors', errors: @errors )) %>")
<% else %>
$("#flashContainer").replaceWith("<%= escape_javascript(render( '/layouts/flash' )) %>")
$("#org-form-container").html("<%= j render 'form', organization: @organization, user_rights: @user_rights, fulfillment_rights: @fulfillment_rights, path: @path %>")
$('#cm-accordion').replaceWith("<%= j render '/catalog_manager/catalog/accordion', institutions: @institutions, show_available_only: false %>")
$('#availability_toggle_container').html("<%= j render '/catalog_manager/catalog/availability_toggle', show_available_only: false %>")

$("[data-toggle='toggle']").bootstrapToggle();
$('.selectpicker').selectpicker();

$("#modalContainer").modal('hide');

initialize_user_rights_search();
initialize_fulfillment_rights_search();
<% end %>
