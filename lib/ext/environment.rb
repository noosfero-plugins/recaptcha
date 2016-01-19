require_dependency 'environment'

class Environment

  #reCAPTCHA settings
  settings_items :recaptcha_plugin, :type => Hash, :default => {}
  attr_accessible :recaptcha_plugin_attributes, :recaptcha_version, :recaptcha_private_key, :recaptcha_site_key, :recaptcha_verify_uri

  def recaptcha_plugin_attributes
    self.recaptcha_plugin || {}
  end

  def recaptcha_version= recaptcha_version
    self.recaptcha_plugin = {} if self.recaptcha_plugin.blank?
    self.recaptcha_plugin['recaptcha_version'] = recaptcha_version
  end

  def recaptcha_version
    self.recaptcha_plugin['recaptcha_version']
  end

  def recaptcha_private_key= recaptcha_private_key
    self.recaptcha_plugin = {} if self.recaptcha_plugin.blank?
    self.recaptcha_plugin['recaptcha_private_key'] = recaptcha_private_key
  end

  def recaptcha_private_key
    self.recaptcha_plugin['recaptcha_private_key']
  end

  def recaptcha_verify_uri= recaptcha_verify_uri
    self.recaptcha_plugin = {} if self.recaptcha_plugin.blank?
    self.recaptcha_plugin['recaptcha_verify_uri'] = recaptcha_verify_uri
  end

  def recaptcha_verify_uri
    self.recaptcha_plugin['recaptcha_verify_uri']
  end

  def recaptcha_site_key= recaptcha_site_key
    self.recaptcha_plugin = {} if self.recaptcha_plugin.blank?
    self.recaptcha_plugin['recaptcha_site_key'] = recaptcha_site_key
  end

  def recaptcha_site_key
    self.recaptcha_plugin['recaptcha_site_key']
  end

end
