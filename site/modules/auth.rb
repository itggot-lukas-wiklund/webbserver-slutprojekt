require 'sqlite3'
require 'bcrypt'

module Auth

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

    def is_authenticated(session)
        return get_logged_in_user_id(session) != nil
    end

    def get_logged_in_user_id(session)
        return session[:user_id]
    end

    def get_user_by_id(account_id, db)
        db = open_connection_if_nil(db)
        accounts = db.execute("SELECT * FROM accounts WHERE id = ?", [account_id])
        if accounts.size() == 0
            return nil
        end
        return accounts[0]
    end

    def get_logged_in_user(session)
        account_id = get_logged_in_user_id(session)
        if account_id == nil
            return nil
        end
        return get_user_by_id(account_id, nil)
    end

    # Return codes:
    # [account] = Success
    # 1 = Email is already in use
    # 2 = Username is already in use
    # 3 = Forbidden characters in username
    def register(email, username, password, session)
        db = open_connection()
        if !username.match(/^[\w\d_-]+$/)
            puts "Username contains forbidden characters!"
            return 3
        end
        account = get_user(email, db)
        if account != nil
            print "Email is already in use!"
            return 1
        end
        account = get_user(username, db)
        if account != nil
            print "Username is already in use!"
            return 2
        end

        password_hash = BCrypt::Password.create(password)
        db.execute("INSERT INTO accounts(email, username, password) VALUES(?, ?, ?)", [email, username, password_hash])

        account = get_user_email(email, db)
        session[:user_id] = account['id']

        db.execute("INSERT INTO profiles(account_id, avatar) VALUES(?,?)", [account['id'], 'default.png'])

        return account
    end

    def login(login_name, password, session)
        db = open_connection()
        account = get_user(login_name, db)

        if account == nil
            puts "User does not exist!"
            return nil
        end

        if BCrypt::Password.new(account['password']) == password
            session[:user_id] = account['id']
            puts "Successfully logged in user '#{account['username']}' with ID '#{account['id']}'!"
            return account
        end

        puts "Wrong password!"
        return nil
    end

    def logout(session)
        session[:user_id] = nil
    end

    def get_user_email(email, db)
        db = open_connection_if_nil(db)
        accounts = db.execute("SELECT * FROM accounts WHERE LOWER(email) = ?", [email.downcase])
        if accounts.size() > 0 then return accounts[0] end
        return nil
    end

    def get_user_username(username, db)
        db = open_connection_if_nil(db)
        accounts = db.execute("SELECT * FROM accounts WHERE LOWER(username) = ?", [username.downcase])
        if accounts.size() > 0 then return accounts[0] end
        return nil
    end

    def get_user(login_name, db)
        db = open_connection_if_nil(db)
        account = get_user_email(login_name, db)
        if account == nil
            account = get_user_username(login_name, db)
            if account == nil
                return nil
            end
        end

        return account
    end

    # Return codes:
    # 0 = Success
    # 1 = User not found
    # 2 = Old password is incorrect
    def change_password(account_id, old_password, new_password, db)
        db = open_connection_if_nil(db)
        account = get_user_by_id(account_id, db)
        if account == nil
            return 1
        end

        if BCrypt::Password.new(account["password"]) != old_password
            return 2
        end

        db.execute("UPDATE accounts SET password = ? WHERE id = ?", [BCrypt::Password.create(new_password), account_id])

        return 0
    end
end