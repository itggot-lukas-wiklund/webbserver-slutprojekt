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

    def get_profile(account_id, db)
        db = open_connection_if_nil(db)
        profiles = db.execute("SELECT * FROM profiles WHERE account_id = ?", [account_id])
        if profiles.size() == 0
            return nil
        end
        return profiles[0]
    end

    def update_profile(account_id, name, gender_id, location)
        db = open_connection()
        profile = get_profile(account_id, db)
        if profile == nil
            puts "Failed to save profile with account ID: #{account_id}!"
            return
        end

        db.execute("UPDATE profiles SET name = ?, gender_id = ?, location = ? WHERE account_id = ?", [name, gender_id, location, account_id])
    end
end