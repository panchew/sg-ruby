class API

  attr_accessor :access_token

  def initialize
    oauth_client = SurveyGizmo::OAuthClient.new(Settings[Rails.env]['survey_gizmo']['consumer_key'], Settings[Rails.env]['survey_gizmo']['consumer_secret'])
    @access_token = oauth_client.use_access_token(Settings[Rails.env]['survey_gizmo']['access_token'], Settings[Rails.env]['survey_gizmo']['access_secret'])
  end

  def make_api_call( options = {} )
    format = options.delete(:format) || 'json'
    url = URI.encode(build_api_call_params(options))
    Rails.logger.info "SurveyGizmo API call to: #{url}"
    full_result = @access_token.get(url)
    return full_result if options[:return_full_result]
    result = full_result.body
    return JSON.parse(result) if format == 'json'
    return JSON.parse(result).to_xml if format == 'xml'
    result
  end

  def getlist_survey( options = {} )
    options[:uri] = 'survey'
    options.reverse_merge!({ :api_version => 'head'})
    make_api_call options
  end

  def get_survey(survey_id, options = {})
    options[:uri] = "survey/#{survey_id}"
    options.reverse_merge!({ :api_version => 'head'})
    make_api_call options
  end

  def getlist_survey_question(survey_id, options = {})
    options[:uri] = "survey/#{survey_id}/surveyquestion"
    options.reverse_merge!({ :api_version => 'head'})
    make_api_call options
  end

  def get_survey_question(survey_id, question_id, options = {})
    options[:uri] = "survey/#{survey_id}/surveyquestion/#{question_id}"
    options.reverse_merge!({ :api_version => 'head'})
    make_api_call options
  end

  def getlist_response(survey_id, options = {})
    options[:uri] = "survey/#{survey_id}/surveyresponse"
    options.reverse_merge!({ :api_version => 'head'})
    make_api_call options
  end

  def get_response(survey_id, response_id, options = {})
    options[:uri] = "survey/#{survey_id}/surveyresponse/#{response_id}"
    options.reverse_merge!({ :api_version => 'head'})
    make_api_call options
  end

  def getlist_campaign(survey_id, options = {})
    options[:uri] = "survey/#{survey_id}/surveycampaign"
    options.reverse_merge!({ :api_version => 'head'})
    make_api_call options
  end

  def get_campaign(survey_id, campaign_id, options = {})
    options[:uri] = "survey/#{survey_id}/surveycampaign/#{campaign_id}"
    options.reverse_merge!({ :api_version => 'head'})
    make_api_call options
  end

  def get_email_campaign(survey_id)
    #TODO: move this out of the API client
    campaign_list = getlist_campaign(survey_id)
    campaign_id = nil
    return nil unless campaign_list['result_ok']
    campaign_list['data'].each do |campaign|
      campaign_id = campaign.try(:[], 'id') if campaign.try(:[], '_subtype') == 'email' and campaign.try(:[], 'status') == 'Active'
    end

    campaign_id
  end

  def getlist_campaign_contact(survey_id, campaign_id, options = {})
    options[:uri] = "survey/#{survey_id}/surveycampaign/#{campaign_id}/contact"
    options.reverse_merge!({ :api_version => 'head'})
    make_api_call options
  end

  def get_campaign_contact(survey_id, campaign_id, contact_id, options = {})
    options[:uri] = "survey/#{survey_id}/surveycampaign/#{campaign_id}/contact/#{contact_id}"
    options.reverse_merge!({ :api_version => 'head'})
    make_api_call options
  end

  def create_contact(survey_id, campaign_id, options = {})
    #TODO: break this in two methods: the actual API client call and the RT create method
    begin
      return false unless options[:contact_data].has_key?(:semailaddress)
      options[:uri] = "survey/#{survey_id}/surveycampaign/#{campaign_id}/contact"
      options.reverse_merge!({ :api_version => 'head'})
      options[:params] = '_method=PUT'
      sg_params = ''
      options[:contact_data].merge!( { :scustomfield10 => Time.zone.now.to_i } )
      options[:contact_data].each do |key, value|
        sg_params << "&#{key.to_s}=#{value}"
      end
      options.delete(:contact_data)
      options[:params] << sg_params

      make_api_call(options)
    rescue => e
      Rails.logger.info "[lib/survey_gizmo.rb #create_contact] Survey ID=#{survey_id}, Campaign ID=#{campaign_id}, Contact Params=#{sg_params}"
      Rails.logger.info "[lib/survey_gizmo.rb #create_contact] #{e}"
      nil
    end
  end

  def edit_contact(survey_id, campaign_id, contact_id, options = {})
    #TODO: break this in two methods: the actual API client call and the RT create method
    begin
      options[:uri] = "survey/#{survey_id}/surveycampaign/#{campaign_id}/contact/#{contact_id}"
      options.reverse_merge!({ :api_version => 'head'})
      options[:params] = '_method=POST'
      sg_params = ''
      options[:contact_data].each do |key, value|
        sg_params << "&#{key.to_s}=#{value}"
      end
      options.delete(:contact_data)
      options[:params] << sg_params

      result = make_api_call(options)

      if result['result_ok']
        result['data']['id']
      else
        result.to_s
      end
    rescue => e
      puts e
      puts "Survey ID=#{survey_id}, Campaign ID=#{campaign_id}, Contact ID=#{contact_id}, Params=#{sg_params}"
      nil
    end
  end

  def lookup_contact(survey_id, campaign_id, semailaddress, params = {})
    contacts_list = getlist_campaign_contact(survey_id, campaign_id, params)
    total_pages = contacts_list['total_pages']
    (1..total_pages).each do |page|
      params.merge!(:page => page)
      contacts_list = getlist_campaign_contact(survey_id, campaign_id, params) unless page == 1
      contacts_list['data'].each do |contact|
        return contact if semailaddress.try(:downcase) == contact['semailaddress'].downcase
      end
    end
  end

  def delete_contact(survey_id, campaign_id, contact_id, options = {})
    options[:uri] = "survey/#{survey_id}/surveycampaign/#{campaign_id}/contact/#{contact_id}"
    options.reverse_merge!({ :api_version => 'head'})
    options[:params] = '_method=DELETE'
    make_api_call options
  end

  def copy_survey(survey_id, title = survey_id.to_s, options = {})
    edit_survey survey_id, options.merge!(:copy => true, :title => title)
  end

  def edit_survey(survey_id, options = {})
    options[:uri] = "survey/#{survey_id}"
    options.reverse_merge!({ :api_version => 'head'})
    options[:params] = "_method=POST"
    options[:params] << "&title=#{options.delete(:title)}" if options[:title]
    options[:params] << "&status=#{options.delete(:status)}" if options[:status]
    options[:params] << "&theme=#{options.delete(:theme)}" if options[:theme]
    options[:params] << "&team=#{options.delete(:team)}" if options[:team]
    options[:params] << "&options[internal_title]=#{options.delete(:internal_title)}" if options[:internal_title]
    options[:params] << "&blockby=#{options.delete(:block_by)}" if options[:block_by]
    options[:params] << "&copy=true" if options.delete(:copy)
    make_api_call options
  end

  def delete_survey(survey_id, options = {})
    options[:uri] = "survey/#{survey_id}"
    options.reverse_merge!({ :api_version => 'head'})
    options[:params] = "_method=DELETE"
    make_api_call options
  end

  def activate_survey(survey_id)
    edit_survey survey_id, :status => 'Launched'
  end

  def change_question(survey_id, question_id, page = 1, options = {})
    options[:uri] = "survey/#{survey_id}/surveypage/#{page}/surveyquestion/#{question_id}"
    options.reverse_merge!({ :api_version => 'head'})
    options[:params] = '_method=POST'
    options[:question_data].each do |key, value|
      if value.is_a?(Hash)
        value.each do |p, v|
          if v.is_a?(Hash)
            v.each do |k1, v1|
              options[:params] << "&#{key}[#{p}][#{k1}]=#{v1}"
            end
          else
            options[:params] << "&#{key}[#{p}]=#{v}"
          end
        end
      else
        options[:params] << "&#{key}=#{value}"
      end
    end
    make_api_call options
  end

  def create_from_template(account, options = {} )
    is_enabled = Settings['general']['survey_gizmo']['enabled']
    if is_enabled
      survey_id = Settings['general']['survey_gizmo']['template_survey_id']
      company_name = account.company_name
      survey_title = "Customer Feedback - #{company_name}"
      new_survey = copy_survey(survey_id, survey_title)
      if new_survey['result_ok']
        new_survey_id = new_survey['data']['id']
        edit_survey(new_survey_id, options.merge!(:title => survey_title))
        params = {:question_data => {:title => {"English" => account.industry}}}
        change_question(new_survey_id, 475, 1, params)
        params = {:question_data => {:title => {"English" => company_name}}}
        change_question(new_survey_id, 476, 1, params)
        params = {:question_data => {:title => {"English" => account.website}}}
        change_question(new_survey_id, 478, 1, params)

        options[:links].each do |question_id, link|
          Rails.logger.info "question id: #{question_id} - link: #{link}"
          params = {:question_data => {:title => {"English" => link}}}
          change_question(new_survey_id, question_id.to_i, 1, params)
        end

        #activate_survey(new_survey_id)
        Rails.logger.info "Survey created from template; new survey ID is #{new_survey_id} - AccountID: #{account.id}"
        result = {:result => :ok, :survey_id => new_survey_id}

        Rails.logger.info 'Creating contact survey...'
        contact_survey_result = create_contact_survey_from_template(account)

        if contact_survey_result[:result] == :ok
          Rails.logger.info "Contact Survey created from template; contact survey ID is #{contact_survey_result[:contact_survey_id]} - AccountID: #{account.id}"
          return result.merge(contact_survey_result)
        end
        result
      else
        Rails.logger.info new_survey['message']
        {:result => :error}.merge({:message => new_survey['message']})
      end
    else
      sleep 5
      {:result => :ok, :survey_id => '0000000', :contact_survey_id => '1111111'}
    end
  rescue => e
    Rails.logger.info e
    nil
  end

  def create_contact_survey_from_template(account = nil, options = {})
    is_enabled = Settings['general']['survey_gizmo']['enabled']
    if is_enabled
      company_name ||= account.company_name
      survey_id = Settings['general']['survey_gizmo']['template_contact_survey_id']
      survey_title = "Mobile Survey - #{company_name}"
      contact_survey = copy_survey(survey_id, survey_title)
      if contact_survey['result_ok']
        contact_survey_id = contact_survey['data']['id']
        edit_survey(contact_survey_id, options.merge!(:title => survey_title))
        {:result => :ok, :contact_survey_id => contact_survey_id}
      else
        Rails.logger.info contact_survey["message"]
        {:result => :error, :message => contact_survey["message"]}
      end
    else
      sleep 5
      {:result => :ok, :contact_survey_id => '0000000'}
    end
  rescue => e
    Rails.logger.info e
    nil
  end

  def update_survey_urls(survey_id, options = {})
    options[:links].each do |question_id, link|
      Rails.logger.info "question id: #{question_id} - link: #{link}"
      params = {:question_data => {:title => {"English" => link}}}
      change_question(survey_id, question_id.to_i, 1, params)
    end
  end

  def deactivate_contacts(survey)
    return unless survey.survey_identifier.present? && survey.campaign_identifier.present?

    survey_identifier = survey.survey_identifier
    campaign_identifier = survey.campaign_identifier

    params = "filter[field][0]=estatus&filter[operator][0]=="
    params << "&filter[value][0]=active&filter[field][1]=esubscriberstatus"
    params << "&filter[operator][1]==&filter[value][1]=Unsent"

    page = 1

    puts "....getting contacts, page 1. Survey Identifier = #{survey_identifier}, Campaign Identifier = #{campaign_identifier}"
    list = getlist_campaign_contact(survey_identifier, campaign_identifier, :page => page, :results_per_page => 300, :filters => params)
    puts "....total number of contacts - #{list['total_count'].to_i}"

    while list['data'].count > 0
      puts "....editing contacts"
      list['data'].each do |contact|
        if contact['estatus'] != 'Inactive' && contact['esubscriberstatus'] == 'Unsent'
          edit_contact(survey_identifier, campaign_identifier, contact['id'], :contact_data => {:estatus => 'Inactive'})
        end
      end

      puts "....getting contacts, page #{page}"
      list = getlist_campaign_contact(survey_identifier, campaign_identifier, :page => page += 1, :results_per_page => 300, :filters => params)
    end

  end

  private

  def build_api_call_params( options = {} )
    api_version  = options[:api_version]
    uri          = options[:uri]
    query_params = options[:params] || ''
    common_params = {
        :page => options[:page],
        :results_per_page => options[:results_per_page],
        :filters => options[:filters],
        :metaonly => options[:metaonly]
    }
    query_params << build_common_query_params(common_params)

    url = "/#{api_version}/#{uri}"
    url << "?#{query_params}" if query_params.present?
    url
  end

  def build_common_query_params( options = {} )
    query_params = []
    query_params << "page=#{options[:page]}" if options[:page].present?
    query_params << "resultsperpage=#{options[:results_per_page]}" if options[:results_per_page].present?
    query_params << "altfilter=#{URI.encode_www_form_component(options[:filters])}" if options[:filters].present?
    query_params << "metaonly=true" if options[:metaonly]
    query_params.compact!
    query_params.present? ? query_params.join('&') : ''
  end

end