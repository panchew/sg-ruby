class OAuthClient

  def initialize(consumer_key, consumer_secret)
    @consumer_key = consumer_key
    @consumer_secret = consumer_secret

    @consumer = OAuth::Consumer.new(consumer_key, consumer_secret,
                                    {:site => "https://restapi.surveygizmo.com",
                                     :request_token_path => "/head/oauth/request_token",
                                     :authorize_path => "/head/oauth/authenticate",
                                     :access_token_path => "/head/oauth/access_token"
                                    })
  end

  def authorize_app(callback_url)
    @request_token = @consumer.get_request_token(:oauth_callback => callback_url)

    p "Please go to #{@request_token.authorize_url} and authorize your App to retrieve your surveys data"
  end

  def get_access_token(oauth_token, oauth_verifier) # oauth_token and oauth_secret are returned as params in callback url
    @access_token = @request_token.get_access_token(:oauth_consumer_key => @consumer_key,
                                                    :oauth_token => oauth_token,
                                                    :oauth_verifier => oauth_verifier)
  end

  def use_access_token(token, secret)
    @access_token = OAuth::AccessToken.new(@consumer, token, secret)
  end
end