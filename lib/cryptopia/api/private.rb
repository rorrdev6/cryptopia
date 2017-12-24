require 'cgi'
require 'json'
require 'base64'
require 'openssl'

module Cryptopia
  module Api
    module Private
      ENDPOINT = 'https://www.cryptopia.co.nz/Api'

      AVAILABLE_PARAMS = {
        balance: [:Currency, :CurrencyId],
      }

      def initialize(api_key = nil, api_secret = nil)
        @api_key = api_key
        @api_secret = api_secret
      end

      def balance(options = {})
        for_uri(Private::ENDPOINT) do
          if invalid_params?(:balance, options)
            raise ArgumentError, "Arguments must be #{params(:balance)}"
          end

          handle_response(auth_post('/GetBalance', options))
        end
      end

      private

      attr_reader :api_key, :api_secret, :url, :options

      def auth_post(endpoint, options = {})
        if keys_is_not_present?
          raise ArgumentError, "The api key and/or api secret must be informed"
        end

        @url = self.class.base_uri + endpoint
        @options = options.to_json

        self.class.post(
          endpoint,
          body: @options,
          headers: {
            'Authorization' => "amx #{authorization_formatted_value}",
            'Content-Type' => 'application/json'
          })
      end

      def keys_is_not_present?
        (api_key.nil? || (!api_key.nil? && api_key == '')) ||
         (api_secret.nil? || (!api_secret.nil? && api_secret == ''))
      end

      def authorization_formatted_value
        [
          api_key,
          hmacsignature,
          nonce
        ].join(':')
      end

      def hmacsignature
        hmac = OpenSSL::HMAC.digest(
          OpenSSL::Digest.new('sha256'),
          Base64.decode64(api_secret),
          signature
        )

        Base64.encode64(hmac).strip
      end

      def signature
        [
          api_key,
          'POST',
          CGI::escape(url).downcase,
          nonce,
          hashed_post_params
        ].join.strip
      end

      def hashed_post_params
        md5 = Digest::MD5.new.digest(options.to_s)

        Base64.encode64(md5)
      end

      def nonce
        @nonce ||= Time.now.to_i.to_s
      end

      def invalid_params?(endpoint, options = {})
        return false if options.keys.length.zero?

        (options.keys - AVAILABLE_PARAMS[endpoint]).length == 1
      end

      def params(endpoint)
        AVAILABLE_PARAMS[endpoint].join(' or ')
      end
    end
  end
end
