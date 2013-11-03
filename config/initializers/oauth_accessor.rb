class OAuthAccessor

  def self.access_token
    consumer_key = 'xZWLznCTCMN60ql-d_IeSg'
    consumer_secret = '33_BnupYIyLWwX5idCNrdz7bJic'
    token = 'ewtiuavfpNHjdazF0H-pPSGhUqeTwBM-'
    token_secret = '1FdhMTqe72pvoGCXLqN8rXyBNLk'

    consumer = OAuth::Consumer.new(consumer_key, consumer_secret, {site: "http://api.yelp.com"})
    access_token = OAuth::AccessToken.new(consumer, token, token_secret)
  end
end
