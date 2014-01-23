# -*- coding: utf-8 -*-
class SessionsController < ApplicationController
  before_filter { add_body_class('login') }

  def new
    # Establish a user session if the user_agent cookie satisfy the remember me criterias
    @user_agent = cookies.signed[:user_agent].present? ? UserAgent.where(id: cookies.signed[:user_agent][:id]).first : false

    if @user_agent && @user_agent.authenticate(cookies.signed[:user_agent][:token])
      session[:user_id] = @user_agent.user_id
      current_user.update_attribute("last_login", Time.now)

      set_profile_cookie
      redirect_after_login

    elsif APP_CONFIG['auth_method'] == "saml"
      # SAML Auth has its own controller
      redirect_to saml_new_path
    else
      # Render the standard login form
      render :new
    end
  end

  def create
    # Stubbed authentication
    if APP_CONFIG['stub_auth']
      stub_auth(params[:username])

    # Authenticate with LDAP
    else
      ldap = Ldap.new
      if ldap.authenticate(params[:username], params[:password])
        # Update user attributes from LDAP. Create user if it not exist.
        @user = ldap.update_user_profile(params[:username])
        @user.update_attribute("last_login", Time.now)

        # Set user cookies
        session[:user_id] = @user.id
        set_profile_cookie
        track_user_agent

        redirect_after_login
      else
        @login_failed = "Fel användarnamn eller lösenord. Vänligen försök igen."
        render "new"
      end
    end
  end

  def destroy
    begin
      @user_agent = UserAgent.find(cookies.signed[:user_agent][:id])
      @user_agent.update_attributes( remember_me: false )
    rescue
      logger.warn { "'Remember me' for user #{current_user.id} couldn't be reset on logout" }
    end
    session[:user_id] = nil
    redirect_to root_url, notice: "Nu är du utloggad"
  end

  private

  def stub_auth(username)
    @user = User.where(username: username).first
    if @user
      session[:user_id] = @user.id
      redirect_to root_url
    else
      render "new"
    end
  end
end
