# -*- coding: utf-8 -*-
require "spec_helper"

describe "GroupContactsAPI" do
  let(:api_app) { ApiApp.create(name: "x", contact: "x", ip_address: "127.0.0.1") }
  let(:group_contact) { create(:group_contact) }

  it "should require authentication" do
    get "/api/v1/group_contacts/123"
    expect(response.status).to eq(401)
    get "/api/v1/group_contacts/search"
    expect(response.status).to eq(401)
  end

  it "should have an unauthorized message" do
    get "/api/v1/group_contacts/123"
    expect(json["message"]).to match("401 Unauthorized")
  end

  it "should require valid app_token" do
    get "/api/v1/group_contacts/#{group_contact.id}?app_token=x&app_secret=#{api_app.app_secret}"
    expect(response.status).to eq(401)
  end

  it "should require valid app_token" do
    get "/api/v1/group_contacts/#{group_contact.id}?&app_secret=#{api_app.app_secret}"
    expect(response.status).to eq(401)
  end

  it "should require valid app_secret" do
    get "/api/v1/group_contacts/#{group_contact.id}?app_token=#{api_app.app_token}&app_secret=x"
    expect(response.status).to eq(401)
  end

  it "should require valid app_secret" do
    get "/api/v1/group_contacts/#{group_contact.id}?app_token=#{api_app.app_token}"
    expect(response.status).to eq(401)
  end

  it "should require valid ip address" do
    a = ApiApp.create(name: "x", contact: "x", ip_address: "127.0.0.2")
    get "/api/v1/group_contacts/#{group_contact.id}?app_token=#{a.app_token}&app_secret=#{a.app_secret}"
    expect(response.status).to eq(401)
  end

  describe "search response" do
    it "should be a success" do
      get "/api/v1/group_contacts/search?term=#{group_contact.name}&app_token=#{api_app.app_token}&app_secret=#{api_app.app_secret}"
      expect(response).to be_success
    end

    it "should contain one group_contact" do
      get "/api/v1/group_contacts/search?term=#{group_contact.name}&app_token=#{api_app.app_token}&app_secret=#{api_app.app_secret}"
      expect(json.size).to eq(1)
    end

    it "should not contain any group_contact" do
      get "/api/v1/group_contacts/search?term=foo&app_token=#{api_app.app_token}&app_secret=#{api_app.app_secret}"
      expect(json.size).to eq(0)
    end

    it "should contain two group_contacts" do
      create(:group_contact, name: "foo-1")
      create(:group_contact, name: "foo-2")
      get "/api/v1/group_contacts/search?term=foo-&app_token=#{api_app.app_token}&app_secret=#{api_app.app_secret}"
      expect(json.size).to eq(2)
    end

    describe "first matching group_contact" do
      before(:each) do
        get "/api/v1/group_contacts/search?term=#{group_contact.name}&app_token=#{api_app.app_token}&app_secret=#{api_app.app_secret}"
      end

      it "should have an id" do
        expect(json.first["id"]).to eq(group_contact.id)
      end

      it "should have a name" do
        expect(json.first["name"]).to eq(group_contact.name)
      end

      it "should not give away all attributes" do
        %w(
          address
          cell_phone
          email
          fax
          homepage
          phone
          phone_hours
          postal_town
          visiting_hours
          visitors_address
          visitors_address_geo_position_x
          visitors_address_geo_position_y
          visitors_address_postal_town
          visitors_address_zip_code
          visitors_district
          zip_code
          created_at
          updated_at
        ).each do |attribute|
          expect(json.first[attribute]).to eq(nil)
        end
      end
    end
  end

  describe "response" do
    before(:each) do
      get "/api/v1/group_contacts/#{group_contact.id}?app_token=#{api_app.app_token}&app_secret=#{api_app.app_secret}"
    end

    it "should be a success" do
      expect(response).to be_success
    end

    it "should return the id" do
      expect(json["id"]).to eq(group_contact.id)
    end

    it "should return the name" do
      expect(json["name"]).to eq(group_contact.name)
    end

    it "should return email" do
      expect(json["email"]).to eq(group_contact.email)
    end

    it "should return phone" do
      expect(json["phone"]).to eq(group_contact.phone)
    end

    it "should return phone_hours" do
      expect(json["phone_hours"]).to eq(group_contact.phone_hours)
    end

    it "should return cell_phone" do
      expect(json["cell_phone"]).to eq(group_contact.cell_phone)
    end

    it "should return fax" do
      expect(json["fax"]).to eq(group_contact.fax)
    end

    it "should return address" do
      expect(json["address"]).to eq(group_contact.address)
    end

    it "should return zip_code" do
      expect(json["zip_code"]).to eq(group_contact.zip_code)
    end

    it "should return postal_town" do
      expect(json["postal_town"]).to eq(group_contact.postal_town)
    end

    it "should return visitors_address" do
      expect(json["visiting"]["address"]).to eq(group_contact.visitors_address)
    end

    it "should return visitors_address_zip_code" do
      expect(json["visiting"]["zip_code"]).to eq(group_contact.visitors_address_zip_code)
    end

    it "should return visitors_address_postal_town" do
      expect(json["visiting"]["postal_town"]).to eq(group_contact.visitors_address_postal_town)
    end

    it "should return visitors_district" do
      expect(json["visiting"]["district"]).to eq(group_contact.visitors_district)
    end

    it "should return visitors_address_geo_position_x" do
      expect(json["visiting"]["geo_position"]["x"]).to eq(group_contact.visitors_address_geo_position_x)
    end

    it "should return visitors_address_geo_position_x" do
      expect(json["visiting"]["geo_position"]["y"]).to eq(group_contact.visitors_address_geo_position_y)
    end

    it "should return visiting_hours" do
      expect(json["visiting"]["hours"]).to eq(group_contact.visiting_hours)
    end

    it "should return homepage" do
      expect(json["homepage"]).to eq(group_contact.homepage)
    end
  end
end
