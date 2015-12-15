require_relative "../../../lib/noosfero/api/helpers"

class ActiveSupport::TestCase

  include Rack::Test::Methods

  def app
    Noosfero::API::API
  end

  def pass_captcha(version)

    if version.to_i == 1
      mocked_url = 'https://www.google.com/recaptcha/api/verify'
    end
    if version.to_i == 2
      mocked_url = 'https://www.google.com/recaptcha/api/siteverify'
      body={ secret: "secret",
            response: "response",
            remoteip: "127.0.0.1"}
    end

    pass_body = '{
                    "success": true
                  }'
    stub_request(:post, mocked_url).
      with(:body => body,
           :headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
      to_return(:status => 200, :body => pass_body, :headers => {'Content-Length' => 1})
  end

  def fail_captcha(version)
    if version.to_i == 1
      mocked_url = 'https://www.google.com/recaptcha/api/verify'
    end
    if version.to_i == 2
      mocked_url = 'https://www.google.com/recaptcha/api/siteverify'
      body={ secret: "secret",
            response: "response",
            remoteip: "127.0.0.1"}
    end

    fail_body = '{
                    "success": false
                  }'
    stub_request(:post, mocked_url).
      with(:body => body,
           :headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
      to_return(:status => 200, :body => fail_body, :headers => {'Content-Length' => 1})
  end

  def login_with_captcha
    json = do_login_captcha_from_api
    @private_token = json["private_token"]
    @params = { "private_token" => @private_token}
    json
  end

  ## Performs a login using the session.rb but mocking the
  ## real HTTP request to validate the captcha.
  def do_login_captcha_from_api
    post "/api/v1/login-captcha"
    json = JSON.parse(last_response.body)
    json
  end

  def login_api
    @environment = Environment.default
    @user = User.create!(:login => 'testapi', :password => 'testapi', :password_confirmation => 'testapi', :email => 'test@test.org', :environment => @environment)
    @user.activate
    @person = @user.person

    post "/api/v1/login?login=testapi&password=testapi"
    json = JSON.parse(last_response.body)
    @private_token = json["private_token"]
    unless @private_token
      @user.generate_private_token!
      @private_token = @user.private_token
    end

    @params = {:private_token => @private_token}
  end
  attr_accessor :private_token, :user, :person, :params, :environment

  private

  def json_response_ids(kind)
    json = JSON.parse(last_response.body)
    json[kind.to_s].map {|c| c['id']}
  end

end
