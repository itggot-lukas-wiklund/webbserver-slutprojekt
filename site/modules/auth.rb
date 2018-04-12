require 'SQLite3'

module Auth

    def open_connection()
        connection = SQLite3::Database.new('db/database.db')
        connection.results_as_hash = true
        return connection
    end

    def is_authenticated(session)
        return get_logged_in_user_id(session) != nil
    end

    def get_logged_in_user_id(session)
        return session[:user_id]
    end
end