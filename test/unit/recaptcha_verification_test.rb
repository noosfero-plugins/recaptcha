require 'webmock'
include WebMock::API
require File.dirname(__FILE__) + '/../../../../test/test_helper'
require_relative '../test_helper'

class RecaptchaVerificationTest < ActiveSupport::TestCase

  def setup
    @environment = Environment.default
    @environment.enabled_plugins = ['RecaptchaPlugin']
  end

  def setup_captcha(version)
    @environment.recaptcha_version=version.to_s
    @remote_ip = "127.0.0.1"
    if version.to_i == 1
      @params[:recaptcha_challenge_field] = "challenge"
      @params[:recaptcha_response_field] = "response"
    end
    if version.to_i == 2
      #wont go to google thanks to webmock
      @environment.recaptcha_private_key = "secret"
      @recaptcha_site_key = "64264643"
      @captcha_text = "44641441"
      @params = {}

      @params[:g_recaptcha_response] = "response"
    end
    @environment.save!
  end

  def login_with_captcha
    store = Noosfero::API::SessionStore.create("captcha")
    ## Initialize the data for the session store
    store.data = []
    ## Put it back in cache
    store.store
    { "private_token" => "#{store.private_token}" }
  end

  def create_article(name)
    person = fast_create(Person, :environment_id => @environment.id)
    fast_create(Article, :profile_id => person.id, :name => name)
  end

  should 'pass recaptcha version 1' do
    pass_captcha(1)
    rp = RecaptchaPlugin.new
    r = rp.test_captcha(@remote_ip, @params, @environment)
    assert r
  end

  should 'pass recaptcha version 2' do
    setup_captcha(2)
    pass_captcha(2)
    rp = RecaptchaPlugin.new
    r = rp.test_captcha(@remote_ip, @params, @environment)
    assert r
  end

  should 'fail recaptcha version 2' do
    setup_captcha(2)
    fail_captcha(2)
    rp = RecaptchaPlugin.new
    r = rp.test_captcha(@remote_ip, @params, @environment)
    assert_equal({"success"=>false}, r)
  end

  should 'register a user when there are no enabled captcha pluging' do
      @environment.enabled_plugins = []
      @environment.save!
      Environment.default.enable('skip_new_user_email_confirmation')
      params = {:login => "newuserapi", :password => "newuserapi", :password_confirmation => "newuserapi", :email => "newuserapi@email.com" }
      post "/api/v1/register?#{params.to_query}"
      assert_equal 201, last_response.status
      json = JSON.parse(last_response.body)
      assert User['newuserapi'].activated?
      assert json['user']['private_token'].present?
  end

  should 'not register a user if captcha fails' do
      fail_captcha(1)
      Environment.default.enable('skip_new_user_email_confirmation')
      params = {:login => "newuserapi", :password => "newuserapi", :password_confirmation => "newuserapi", :email => "newuserapi@email.com", :txtToken_captcha_serpro_gov_br => @captcha_token, :captcha_text => @captcha_text}
      post "/api/v1/register?#{params.to_query}"
      ap last_response
      assert_equal 403, last_response.status
      json = JSON.parse(last_response.body)
      assert_equal json["message"], _("Wrong captcha text, please try again")
  end
  #
  # should 'verify_recaptcha' do
  #   pass_captcha @environment.recaptcha_verify_uri, @captcha_verification_body
  #   rv = RecaptchaVerification.new
  #   assert rv.verify_recaptcha(@environment.recaptcha_verify_uri, @captcha_token, @captcha_text, @environment.recaptcha_verify_uri)
  # end
  #
  # should 'fail captcha if user has not filled Serpro\' captcha text' do
  #   pass_captcha @environment.recaptcha_verify_uri, @captcha_verification_body
  #   scv = RecaptchaVerification.new
  #   hash = scv.verify_recaptcha(@environment.recaptcha_client_id, @captcha_token, nil, @environment.recaptcha_verify_uri)
  #   assert hash[:user_message], _('Captcha text has not been filled')
  # end
  #
  # should 'fail captcha if Serpro\' captcha token has not been sent' do
  #   pass_captcha @environment.recaptcha_verify_uri, @captcha_verification_body
  #   scv = RecaptchaVerification.new
  #   hash = scv.verify_recaptcha(@environment.recaptcha_client_id, nil, @captcha_text, @environment.recaptcha_verify_uri)
  #   assert hash[:javascript_console_message], _("Missing Serpro's Captcha token")
  # end
  #
  # should 'fail captcha text' do
  #   fail_captcha_text @environment.recaptcha_verify_uri, @captcha_verification_body
  #   scv = RecaptchaVerification.new
  #   hash = scv.verify_recaptcha(@environment.recaptcha_client_id, nil, @captcha_text, @environment.recaptcha_verify_uri)
  #   assert hash[:javascript_console_message], _("Wrong captcha text, please try again")
  # end
  #
  # should 'not perform a vote without authentication' do
  #   article = create_article('Article 1')
  #   params = {}
  #   params[:value] = 1
  #
  #   post "/api/v1/articles/#{article.id}/vote?#{params.to_query}"
  #   json = JSON.parse(last_response.body)
  #   assert_equal 401, last_response.status
  # end
  #
  # should 'perform a vote on an article identified by id' do
  #   pass_captcha @environment.recaptcha_verify_uri, @captcha_verification_body
  #   params = {}
  #   params[:txtToken_captcha_serpro_gov_br]= @captcha_token
  #   params[:captcha_text]= @captcha_text
  #   post "/api/v1/login-captcha?#{params.to_query}"
  #   json = JSON.parse(last_response.body)
  #   article = create_article('Article 1')
  #   params = {}
  #   params[:private_token] = json['private_token']
  #   params[:value] = 1
  #   post "/api/v1/articles/#{article.id}/vote?#{params.to_query}"
  #   json = JSON.parse(last_response.body)
  #   assert_not_equal 401, last_response.status
  #   assert_equal true, json['vote']
  # end

end
