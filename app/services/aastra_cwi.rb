# -*- coding: utf-8 -*-
class AastraCWI

  CLIENT_SETTINGS = {
    pretty_print_xml: Rails.env.development?,
    # open_timeout: 1,
    # read_timeout: 1,
    log_level: Rails.configuration.log_level,
    logger: Rails.logger,
    log: !Rails.env.development? # turns of HTTPI logging if false
  }

  # Search for an employee by the LDAP id.
  # Return the employees ID in CMG or nil
  def self.get_cmg_id(user)
    search_client = client(APP_CONFIG['aastra_cwi']['user_service'])

    return 0 if user.phone.blank?
    cmg_phone = user.phone.gsub(/\s/, "")[-5, 5]
    return 0 if cmg_phone == "41000" # switchboard number

    users = search_client.call(:get_user_information,
      message: {
        "theSearchRequest" => {
          "SearchKeys" => {
            # "string" => "MISC8=#{user.username}",
            # "string" => "MSGID=#{user.email}",
            "string" => "TELNO=#{cmg_phone}"
          },
          "GetFieldNames" => 1
        }
      }
    )
    user = users.to_array(:get_user_information_response, :get_user_information_result, :subscribers, :subscriber)
    if user.present?
      user.first[:cmg_id]
    else
      0
    end
  end

  # Get the record for a known employee by CMG id, except activities
  def self.find(cmg_id)
    search_client = client(APP_CONFIG['aastra_cwi']['user_service'])
    user = search_client.call(:get_user_information_by_id,
      message: {
        "theSearchRequest" => {
          "RecordId" => cmg_id,
          "ShowInfoActivity" => true,
          "Lang" => "SVE"
        }
      }
    )
  end

  # Get activities for a known employee by CML id
  def self.activities(cmg_id)
    acitvities_client = client(APP_CONFIG['aastra_cwi']['activity_service'])
    user = acitvities_client.call(:get_activity_information_by_user_id,
      message: {
        "theSearchRequest" => {
          "SearchKey" => "CMGId",
          "KeyValue" => cmg_id,
          "Lang" => "SVE"
        }
      }
    )
    user.to_array(:get_activity_information_by_user_id_response, :get_activity_information_by_user_id_result, :activities, :activity)
  end

  private
    # There are serveral wsdl endpoints, each one needs its own savon client
    def self.client(wsdl)
      client = Savon.client({
        wsdl: wsdl,
        soap_header: { "urn:CommonHeader" => {
            "urn:AnAToken!" => "<![CDATA[#{auth_token}]]>"
          }
        },
        namespace_identifier: "urn",
        convert_request_keys_to: :none
      }.merge(CLIENT_SETTINGS))
    end

    # Fetch and cache the auth token required to 
    def self.auth_token
      Rails.cache.fetch('aastra_auth_token', expires_in: 1.day) do
        auth_client = Savon.client({ wsdl: APP_CONFIG['aastra_cwi']["auth_service"] }.merge(CLIENT_SETTINGS))

        auth = auth_client.call(:get_sso_token,
          message: {
            "username" => APP_CONFIG['aastra_cwi']["username"],
            "password" => APP_CONFIG['aastra_cwi']["password"]
          }
        )
        auth.to_array(:get_sso_token_response).first[:get_sso_token_result]
      end
    end
end
