module Settings
  class Subjects

    class << self
      include Enumerable

      def each
        Settings::Db.store.subjects.each{|code| yield code }
      end

      def [](code)
        book = find{|book_code, info| book_code == code }
        book ? book['info'] : {}
      end

    end

  end
end
