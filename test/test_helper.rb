require_relative "../../../lib/noosfero/api/helpers"

class ActiveSupport::TestCase

  include Rack::Test::Methods

  def app
    Noosfero::API::API
  end

  def validate_captcha(version, pass = true)

    if pass
      status = 200
    else
      status = 403
    end

    if version.to_i == 1
      body = {
          "challenge"   => "challenge",
          "privatekey"  => "secret",
          "remoteip"    => "127.0.0.1",
          "response"    => "response"
      }
    end
    if version.to_i == 2
      body={ secret: "secret",
            response: "response",
            remoteip: "127.0.0.1"}
    end

    return_body = "{\"success\": #{pass} }"

    stub_request(:post, @verify_uri).
      with(:body => body,
           :headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
        to_return(:status => status, :body => return_body, :headers => {'Content-Length' => 1})
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
