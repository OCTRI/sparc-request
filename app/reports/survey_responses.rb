class SurveyResponseReport < ReportingModule
  $canned_reports << name unless $canned_reports.include? name # update global variable so that we can populate the list, report won't show in the list without this, unless is necessary so we don't add on refresh in dev. mode

  ################## BEGIN REPORT SETUP #####################

  def self.title
    "Survey Responses"
  end

  # see app/reports/test_report.rb for all options
  def default_options
    {
      "Date Range" => {:field_type => :date_range, :for => "completed_at", :from => "2012-03-01".to_date, :to => Date.today},
      Survey => {:field_type => :select_tag, :custom_name_method => :title, :required => true}
    }
  end

  # see app/reports/test_report.rb for all options
  def column_attrs
    attrs = {}
    attrs["User ID"] = :user_id
    attrs["User Name"] = "identity.try(:full_name)"
    attrs["Submitted Date"] = "completed_at.try(:strftime, \"%D\")"

    if params[:survey_id]
      survey = Survey.find(params[:survey_id])
      survey.sections.each do |section|
        section.questions.each do |question|
          question.answers.each do |answer|
            if answer.response_class == "text"
              attrs[ActionView::Base.full_sanitizer.sanitize(question.text)] = "responses.select{|response| response.question_id == #{question.id}}.first.try(:text_value)"
            else
              attrs[ActionView::Base.full_sanitizer.sanitize(question.text)] = "responses.select{|response| response.question_id == #{question.id}}.first.try(:answer).try(:text)"
            end
          end
        end
      end
    end

    attrs
  end

  ################## END REPORT SETUP  #####################

  ################## BEGIN QUERY SETUP #####################
  # def table => primary table to query
  # includes, where, uniq, order, and group get passed to AR methods, http://apidock.com/rails/v3.2.13/ActiveRecord/QueryMethods
  # def includes => other tables to include
  # def where => conditions for query
  # def uniq => return distinct records
  # def group => group by this attribute (including table name is always a safe bet, ex. identities.id)
  # def order => order by these attributes (include table name is always a safe bet, ex. identities.id DESC, protocols.title ASC)
  # Primary table to query
  def table
    ResponseSet
  end

  # Other tables to include
  def includes
    return :survey
  end

  # Conditions
  def where args={}
    if args[:completed_at_from] and args[:completed_at_to]
      completed_at = args[:completed_at_from].to_time.strftime("%Y-%m-%d 00:00:00")..args[:completed_at_to].to_time.strftime("%Y-%m-%d 23:59:59")
    end

    completed_at ||= self.default_options["Date Range"][:from]..self.default_options["Date Range"][:to]

    return :response_sets => {:completed_at => completed_at}
  end

  # Return only uniq records for
  def uniq
  end

  def group
  end

  def order
    "response_sets.completed_at ASC"
  end

  ##################  END QUERY SETUP   #####################
end
