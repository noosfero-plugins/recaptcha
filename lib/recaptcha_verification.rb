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
    body = https.request(request).body
    captcha_result = JSON.parse(body)
    return true if captcha_result["success"]
    return hash_error(_("Wrong captcha text, please try again"), 403, nil, "Error validating Googles' recaptcha version 1: #{captcha_result["error-codes"]}") if captcha_result["error-codes"] == "incorrect-captcha-sol"
    #Catches all errors at the end
    return hash_error(_("Internal recaptcha validation error"), 500, nil, "Error validating Googles' recaptcha version 1: #{captcha_result["error-codes"]}")
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
    body = https.request(request).body
    captcha_result = JSON.parse(body)
    return true if captcha_result["success"]
    return hash_error(_("Wrong captcha text, please try again"), 403, body, captcha_result["error-codes"])
  end

end
