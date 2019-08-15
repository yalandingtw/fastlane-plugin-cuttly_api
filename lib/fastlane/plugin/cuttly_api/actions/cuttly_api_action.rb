require 'fastlane/action'
require_relative '../helper/cuttly_api_helper'

module Fastlane
  module Actions

    module SharedValues
      CUTTLY_RESPONSE_TITLE = :CUTTLY_RESPONSE_TITLE
      CUTTLY_RESPONSE_LINK = :CUTTLY_RESPONSE_LINK
      CUTTLY_RESPONSE_DATE = :CUTTLY_RESPONSE_DATE
    end

    class CuttlyApiAction < Action
      def self.run(params)
        unless params[:api_key]
          UI.error("Without cuttly api key. Please provide :api_key")
          return
        end
        unless params[:shorten_url]
          UI.error("Without shorten url you want. Please provide :shorten_url")
          return
        end

        http_method = 'GET'
        api_url = 'https://cutt.ly/api/api.php'
        if params[:custom_url_alias] and params[:custom_url_alias] != ""
          ps = {:key => params[:api_key],
                :short => params[:shorten_url],
                :name => params[:custom_url_alias]}
        else
          ps = {:key => params[:api_key],
                :short => params[:shorten_url]}
        end
        UI.message("Start call the cuttly api.")
        response = call_endpoint(
            api_url,
            http_method,
            ps
        )
        status_code = response[:status]

        if status_code.between?(200, 299)
          json = JSON.parse(response.body)
          status = json['url']['status']
          case status
          when 1..6
            UI.error("Response error code:#{status}, Please get more info on the cuttly document website: https://cutt.ly/cuttly-api.")
          when 7
            title = json['url']['title']
            short_link = json['url']['shortLink']
            date = json['url']['date']
            Actions.lane_context[SharedValues::CUTTLY_RESPONSE_TITLE] = title
            Actions.lane_context[SharedValues::CUTTLY_RESPONSE_LINK] = short_link
            Actions.lane_context[SharedValues::CUTTLY_RESPONSE_DATE] = date
          end
        else
          handled_error = error_handlers[status_code] || error_handlers['*']
          if handled_error
            handled_error.call(result)
          else
            UI.error("---")
            UI.error("Request failed:\n#{http_method}: #{url}")
            UI.error("Response:")
            UI.error(response.body)
            UI.error("Cuttly responded with #{status_code}\n---\n#{response.body}")
          end
        end

      end

      def self.description
        "fastlane plugin for cuttly."
      end

      def self.authors
        ["Yalan"]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.details
        # Optional:
        ""
      end

      def self.available_options
        [
            FastlaneCore::ConfigItem.new(key: :api_key,
                                         env_name: "CUTTLY_API_KEY",
                                         description: "Your cuttly's api key",
                                         optional: true,
                                         type: String),
            FastlaneCore::ConfigItem.new(key: :shorten_url,
                                         env_name: "SHORTEN_URL",
                                         description: "Url You want shorten",
                                         optional: true,
                                         type: String),
            FastlaneCore::ConfigItem.new(key: :custom_url_alias,
                                         env_name: "CUSTOM_URL_ALIAS",
                                         description: "Custom url alias",
                                         optional: true,
                                         type: String)
        ]
      end

      def self.is_supported?(platform)
        # Adjust this if your plugin only works for a particular platform (iOS vs. Android, for example)
        # See: https://docs.fastlane.tools/advanced/#control-configuration-by-lane-and-by-platform
        #
        # [:ios, :mac, :android].include?(platform)
        true
      end

      def self.call_endpoint(url, http_method, params)
        Actions.verify_gem!('excon')
        require 'excon'
        connection = Excon.new(url, :header => {'Content-Type' => 'text/html; charset=UTF-8'}, :query => params)
        connection.request(
            method: http_method
        )
      end
    end
  end
end
