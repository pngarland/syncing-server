module SyncEngine
  module V20200115
    class UserManager < SyncEngine::V20190520::UserManager
      def change_pw(user, password, params)
        current_protocol_version = user.version.to_i
        new_protocol_version = params[:version].to_i || current_protocol_version
        upgrading_protocol_version = new_protocol_version > current_protocol_version

        user.encrypted_password = hash_password(password)
        user.update!(registration_params(params))

        if upgrading_protocol_version && new_protocol_version == @user_class::SESSIONS_PROTOCOL_VERSION
          create_session(user, params)
        else
          { user: user }
        end
      end

      private

      def handle_successful_authentication(user, params)
        unless user.supports_sessions?
          return super(user, params)
        end

        create_session(user, params)
      end

      def create_session(user, params)
        session = user.sessions.new(api_version: params[:api], user_agent: params[:user_agent])

        unless session.save
          return {
            error: {
              message: 'Could not create a session.',
              status: 400,
            },
          }
        end

        {
          session: session.as_client_payload,
          token: session.access_token,
          user: user,
        }
      end

      deprecate :update
    end
  end
end
