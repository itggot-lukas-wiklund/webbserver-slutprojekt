require 'sqlite3'
require_relative 'profile.rb'

include Profile

module Question
    # Gör Question till en klass så jag enkelt via Slim kan få tag på skaparen istället för dess ID osv. 
    class Question
        def initialize(account_id, question_id, title, description, author_id)
            db = open_connection()
            @id = question_id
            @title = title;
            @description = description;
            @author = Profile::get_profile(author_id, db)
            likes_hash = get_question_likes(question_id, db)
            @likes = []
            @is_liked = is_question_liked(account_id, question_id, db)
            likes_hash.each do |like|
                @likes.push(Profile::get_profile(like['account_id'], db))
            end
        end
        def id
            return @id
        end
        def title
            return @title
        end
        def description
            return @description
        end
        def author
            return @author
        end
        def likes
            return @likes
        end
        def is_liked
            return @is_liked
        end
    end

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

    def get_all_questions(account_id, db)
        db = open_connection_if_nil(db)
        hashes = db.execute("SELECT * FROM questions")
        questions = []
        hashes.each do |hash|
            questions.push(Question.new(account_id, hash['id'], hash['title'], hash['description'], hash['account_id']))
        end
        return questions
    end

    def get_question_likes(question_id, db)
        db = open_connection_if_nil(db)
        return db.execute("SELECT * FROM question_likes WHERE question_id = ?", [question_id])
    end

    def post_question(account_id, title, description, db)
        db = open_connection_if_nil(db)
        db.execute("INSERT INTO questions(account_id, title, description) VALUES(?, ?, ?)", [account_id, title, description])
    end

    def toggle_question_like(account_id, question_id, db)
        db = open_connection_if_nil(db)
        if is_question_liked(account_id, question_id, db)
            unlike_question(account_id, question_id, db)
        else
            like_question(account_id, question_id, db)
        end
    end

    def is_question_liked(account_id, question_id, db)
        db = open_connection_if_nil(db)
        result = db.execute("SELECT * FROM question_likes WHERE account_id = ? AND question_id = ?", [account_id, question_id])
        return result.size() > 0
    end

    def like_question(account_id, question_id, db)
        db = open_connection_if_nil(db)
        db.execute("INSERT INTO question_likes(account_id, question_id) VALUES(?, ?)", [account_id, question_id])
    end

    def unlike_question(account_id, question_id, db)
        db = open_connection_if_nil(db)
        db.execute("DELETE FROM question_likes WHERE question_id = ? AND account_id = ?", [question_id, account_id])
    end

    def get_comments(question_id, db)
        
    end
end