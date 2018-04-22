require 'sqlite3'
require_relative 'profile.rb'

include Profile

module Question
    # Gör Question till en klass så jag enkelt via Slim kan få tag på skaparen istället för dess ID osv. 
    class Question
        def initialize(question_id, title, description, author_id)
            db = open_connection()
            @title = title;
            @description = description;
            @author = Profile::get_profile(author_id, db)
            likes_hash = get_question_likes(question_id, db)
            @likes = []
            likes_hash.each do |like|
                @likes.push(Profile::get_profile(like['account_id'], db))
            end
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

    def get_all_questions(db)
        db = open_connection_if_nil(db)
        hashes = db.execute("SELECT * FROM questions")
        questions = []
        hashes.each do |hash|
            questions.push(Question.new(hash['id'], hash['title'], hash['description'], hash['account_id']))
        end
        return questions
    end

    def get_question_likes(question_id, db)
        db = open_connection_if_nil(db)
        return db.execute("SELECT * FROM question_likes WHERE question_id = ?", [question_id])
    end
end