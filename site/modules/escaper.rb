module Escaper
    def escape(string)
        return string.gsub("<", "&lt;").gsub(">", "&gt;")
    end
end