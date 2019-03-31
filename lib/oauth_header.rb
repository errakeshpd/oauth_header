require "oauth_header/version"
require 'base64'
require 'openssl'
require 'cgi'

module OauthHeader

  class Error < StandardError; end
  def self.get_header(key, secret, method='GET', url='', token='', grant_type='')
    begin
      params = params_format(key)
      signature_string_maker = signature_string_maker(method, url, params)
      signing_key = secret + '&' + token
      params['oauth_signature'] = url_encoding(ssl_digestive_encoded(signing_key, signature_string_maker))
      params['oauth_consumer_key'] = key
      header_string = header(params)
    rescue
      header_string = ''
    end
    return header_string
  end

  def self.params_format(key)
    params = {
      'oauth_consumer_key' => key,
      'oauth_nonce' => generate_token,
      'oauth_signature_method' => 'HMAC-SHA1',
      'oauth_timestamp' => Time.now.getutc.to_i.to_s,
      'oauth_version' => '1.0'
    }
    return params
  end

  def self.generate_token(size=7)
    Base64.encode64(OpenSSL::Random.random_bytes(size)).gsub(/\W/, '')
  end

  def self.signature_string_maker(method, uri, params)
    encoded_params = params.sort.collect{ |k, v| url_encoding("#{k}=#{v}") }.join('%26')
    method + '&' + url_encoding(uri) + '&' + encoded_params
  end

  def self.ssl_digestive_encoded(key, base_string)
    digest = OpenSSL::Digest.new('sha1')
    ssl_digest = OpenSSL::HMAC.digest(digest, key, base_string)
    Base64.encode64(ssl_digest).chomp.gsub(/\n/, '')
  end

  def self.url_encoding(string)
    CGI::escape(string)
  end

  def self.header(params)
    header = "OAuth "
    params.each do |k, v|
      header = header + k +'='+ "'#{v}',"
    end
    header.slice(0..-2)
  end
end
