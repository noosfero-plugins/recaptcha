class RecaptchaVerification

  def hash_error(user_message, status, log_message=nil, javascript_console_message=nil)
    {user_message: user_message, status: status, log_message: log_message, javascript_console_message: javascript_console_message}
  end

  # return true or a hash with the error
  # :user_message, :status, :log_message, :javascript_console_message
  def verify_recaptcha_v1(remote_ip, private_key, api_recaptcha_verify_uri, recaptcha_challenge_field, recaptcha_response_field)
    if recaptcha_challenge_field == nil || recaptcha_response_field == nil
      return hash_error(_('Captcha validation error'), 500, nil, _('Missing captcha data'))
    end

    verify_hash = {
        "privatekey"  => private_key,
        "remoteip"    => remote_ip,
        "challenge"   => recaptcha_challenge_field,
        "response"    => recaptcha_response_field
    }
    uri = URI(api_recaptcha_verify_uri)
    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true
    request = Net::HTTP::Post.new(uri.path)
    request.set_form_data(verify_hash)
    # begin
      result = https.request(request).body.split("\n")
    # rescue Exception => e
      # return hash_error(_('Internal captcha validation error'), 500, nil, "Error validating Googles' recaptcha version 1: #{e.message}")
    # end
    return true if result[0] == "true"
    return hash_error(_("Wrong captcha text, please try again"), 403, nil, "Error validating Googles' recaptcha version 1: #{result[1]}") if result[1] == "incorrect-captcha-sol"
    #Catches all errors at the end
    return hash_error(_("Internal recaptcha validation error"), 500, nil, "Error validating Googles' recaptcha version 1: #{result[1]}")
  end

  # return true or a hash with the error
  # :user_message, :status, :log_message, :javascript_console_message
  def verify_recaptcha_v2(remote_ip, private_key, api_recaptcha_verify_uri, g_recaptcha_response)
    return hash_error(_('Captcha validation error'), 500, nil, _('Missing captcha data')) if g_recaptcha_response == nil
    verify_hash = {
        "secret"    => private_key,
        "remoteip"  => remote_ip,
        "response"  => g_recaptcha_response
    }
    uri = URI(api_recaptcha_verify_uri)
    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true
    request = Net::HTTP::Post.new(uri.path)
    request.set_form_data(verify_hash)
    # begin
      body = https.request(request).body
    # rescue Exception => e
      # return hash_error(_('Internal captcha validation error'), 500, nil, "recaptcha error: #{e.message}")
    # end
    captcha_result = JSON.parse(body)
    return true if captcha_result["success"]
    return hash_error(_("Wrong captcha text, please try again"), 403, body, captcha_result["error-codes"])
  end

  # return true or a hash with the error
  # :user_message, :status, :log_message, :javascript_console_message
  def verify_serpro_captcha(client_id, token, captcha_text, verify_uri)
    msg_icve = _('Internal captcha validation error')
    msg_esca = 'Environment recaptcha_plugin_attributes'
    return hash_error(msg_icve, 500, nil, "#{msg_esca} verify_uri not defined") if verify_uri.nil?
    return hash_error(msg_icve, 500, nil, "#{msg_esca} client_id not defined") if client_id.nil?
    return hash_error(_("Error processing token validation"), 500, nil, _("Missing Serpro's Captcha token")) unless token
    return hash_error(_('Captcha text has not been filled'), 403) unless captcha_text
    uri = URI(verify_uri)
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri.path)
    verify_string = "#{client_id}&#{token}&#{captcha_text}"
    request.body = verify_string
    body = http.request(request).body
    return true if body == '1'
    return hash_error(_("Internal captcha validation error"), 500, body, "Unable to reach Serpro's Captcha validation service") if body == "Activity timed out"
    return hash_error(_("Wrong captcha text, please try again"), 403) if body == '0'
    return hash_error(_("Serpro's captcha token not found"), 500) if body == '2'
    return hash_error(_("No data sent to validation server or other serious problem"), 500) if body == -1
    #Catches all errors at the end
    return hash_error(_("Internal captcha validation error"), 500, nil, "Error validating Serpro's captcha service returned: #{body}")
  end



end
