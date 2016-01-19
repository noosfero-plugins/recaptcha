class RecaptchaPlugin < Noosfero::Plugin

  def self.plugin_name
    _('Google reCAPTCHA plugin')
  end

  def self.plugin_description
    _("Provides a plugin to Google reCAPTCHA.")
  end

  def test_captcha(*args)
    remote_ip = args[0]
    params = args[1]
    environment = args[2]

    status = 500
    private_key = environment.recaptcha_private_key
    version = environment.recaptcha_version.to_i

    msg_icve = _('Internal captcha validation error')
    msg_erpa = 'Environment recaptcha_plugin_attributes'

    return RecaptchaVerification.hash_error(msg_icve, status, nil, "#{msg_erpa} private_key not defined") if private_key.nil?
    return RecaptchaVerification.hash_error(msg_icve, status, nil, "#{msg_erpa} version not defined") unless version == 1 || version == 2
    rv = RecaptchaVerification.new
    if version  == 1
      verify_uri = 'https://www.google.com/recaptcha/api/verify'
      return rv.verify_recaptcha_v1(remote_ip, private_key, verify_uri, params[:recaptcha_challenge_field], params[:recaptcha_response_field])
    end
    if version == 2
      verify_uri = 'https://www.google.com/recaptcha/api/siteverify'
      return rv.verify_recaptcha_v2(remote_ip, private_key, verify_uri, params[:g_recaptcha_response])
    end
  end

end
