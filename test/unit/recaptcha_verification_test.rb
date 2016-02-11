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
    @environment.recaptcha_private_key = "secret"
    @remoteip = "127.0.0.1"
    @params = {}
    @params[:remoteip] = @remoteip
    if version.to_i == 1
      # won't go to google thanks to webmock
      @verify_uri = 'https://www.google.com/recaptcha/api/verify'
      @params[:privatekey] = @environment.recaptcha_private_key
      @params[:challenge] = "challenge"
      @params[:response] = "response"
      @params[:recaptcha_challenge_field] = @params[:challenge]
      @params[:recaptcha_response_field] = @params[:response]
    end
    if version.to_i == 2
      # won't go to google thanks to webmock
      @verify_uri = 'https://www.google.com/recaptcha/api/siteverify'
      @params[:secret] = @environment.recaptcha_private_key
      @params[:response]  = "response"
      @params[:g_recaptcha_response] = @params[:response]
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
    version = 1
    setup_captcha(version)
    validate_captcha(version)
    r = RecaptchaPlugin.new.verify_captcha(@remoteip, @params, @environment)
    assert_not_kind_of Hash, r
    assert_equal true, r
  end

  should 'fail recaptcha version 1' do
    version = 1
    setup_captcha(version)
    validate_captcha(version, false)
    r = RecaptchaPlugin.new.verify_captcha(@remoteip, @params, @environment)
    assert_kind_of Hash, r
  end

  should 'pass recaptcha version 2' do
    version = 2
    setup_captcha(version)
    validate_captcha(version)
    r = RecaptchaPlugin.new.verify_captcha(@remoteip, @params, @environment)
    assert_not_kind_of Hash, r
    assert_equal true, r
  end

  should 'fail recaptcha version 2' do
    version = 2
    setup_captcha(version)
    validate_captcha(version, false)
    r = RecaptchaPlugin.new.verify_captcha(@remoteip, @params, @environment)
    assert_kind_of Hash, r
    assert_equal r[:user_message], _("Wrong captcha text, please try again")
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

  should 'not register a user if captcha fails recaptcha v2' do
      version = 2
      setup_captcha(version)
      validate_captcha(version, false)
      Environment.default.enable('skip_new_user_email_confirmation')
      params = {:login => "newuserapi", :password => "newuserapi",
                :password_confirmation => "newuserapi", :email => "newuserapi@email.com",
                :g_recaptcha_response => @params[:response]}
      post "/api/v1/register?#{params.to_query}"
      assert_equal 403, last_response.status
      json = JSON.parse(last_response.body)
      assert_equal json["message"], _("Wrong captcha text, please try again")
  end

  should 'fail captcha if user has not filled recaptcha_verify_uri v1 text' do
    version = 1
    setup_captcha(version)
    validate_captcha(version, false)
    rv = RecaptchaVerification.new
    @params[:recaptcha_response_field] = nil
    hash = RecaptchaPlugin.new.verify_captcha(@remoteip, @params, @environment)
    assert hash[:user_message], _('Captcha text has not been filled')
  end

  should 'not perform a vote without authentication' do
    article = create_article('Article 1')
    params = {}
    params[:value] = 1
    post "/api/v1/articles/#{article.id}/vote?#{params.to_query}"
    json = JSON.parse(last_response.body)
    assert_equal 401, last_response.status
  end

  should 'not perform a vote if recaptcha 1 fails' do
    version = 1
    setup_captcha(version)
    validate_captcha(version, false)
    post "/api/v1/login-captcha?#{@params.to_query}"
    json = JSON.parse(last_response.body)
    article = create_article('Article 1')
    params = {}
    params[:private_token] = json['private_token']
    params[:value] = 1
    post "/api/v1/articles/#{article.id}/vote?#{params.to_query}"
    json = JSON.parse(last_response.body)
    assert_equal 401, last_response.status
  end

  should 'perform a vote on an article identified by id using recaptcha 1' do
    version = 1
    setup_captcha(version)
    validate_captcha(version)
    post "/api/v1/login-captcha?#{@params.to_query}"
    json = JSON.parse(last_response.body)
    article = create_article('Article 1')
    params = {}
    params[:private_token] = json['private_token']
    params[:value] = 1
    post "/api/v1/articles/#{article.id}/vote?#{params.to_query}"
    json = JSON.parse(last_response.body)
    assert_not_equal 401, last_response.status
    assert_equal true, json['vote']
  end

  should 'perform a vote on an article identified by id using recaptcha 2' do
    version = 2
    setup_captcha(version)
    validate_captcha(version)
    post "/api/v1/login-captcha?#{@params.to_query}"
    json = JSON.parse(last_response.body)
    article = create_article('Article 1')
    params = {}
    params[:private_token] = json['private_token']
    params[:value] = 1
    post "/api/v1/articles/#{article.id}/vote?#{params.to_query}"
    json = JSON.parse(last_response.body)
    assert_not_equal 401, last_response.status
    assert_equal true, json['vote']
  end

  should 'not perform a vote if recaptcha 2 fails' do
    version = 2
    setup_captcha(version)
    validate_captcha(version, false)
    post "/api/v1/login-captcha?#{@params.to_query}"
    json = JSON.parse(last_response.body)
    article = create_article('Article 1')
    params = {}
    params[:private_token] = json['private_token']
    params[:value] = 1
    post "/api/v1/articles/#{article.id}/vote?#{params.to_query}"
    json = JSON.parse(last_response.body)
    assert_equal 401, last_response.status
  end

end
