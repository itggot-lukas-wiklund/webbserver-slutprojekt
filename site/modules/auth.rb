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

    def register(email, username, password, session)
        db = open_connection()
        account = get_user(email, db)
        if account != nil
            print "Email is already in use!"
            return nil
        end
        account = get_user(username, db)
        if account != nil
            print "Username is already in use!"
            return nil
        end

        password_hash = BCrypt::Password.create(password)
        db.execute("INSERT INTO accounts(email, username, password) VALUES(?, ?, ?)", [email, username, password_hash])

        account = get_user_email(email, db)
        session[:user_id] = account['id']

        db.execute("INSERT INTO profiles(account_id) VALUES(?)", [account['id']])

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
        accounts = db.execute("SELECT * FROM accounts WHERE email = ?", [email])
        if accounts.size() > 0 then return accounts[0] end
        return nil
    end

    def get_user_username(username, db)
        db = open_connection_if_nil(db)
        accounts = db.execute("SELECT * FROM accounts WHERE username = ?", [username])
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
end