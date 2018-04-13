require 'sqlite3'

module Profile

    def open_connection()
        connection = SQLite3::Database.new('db/database.db')
        connection.results_as_hash = true
        return connection
    end

    def open_connection_if_nil(db)
        if db == nil
            return open_connection()
        end

        return db
    end

    def get_genders()
        db = open_connection()
        return db.execute("SELECT * FROM genders")
    end
end