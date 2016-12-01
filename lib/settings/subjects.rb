module Settings
  class Subjects

    class << self
      include Enumerable

      def each(sorted: false)
        list = Settings::Db.store.subjects
        if sorted
          list = list.sort_by{ |subject| subject.last['title']}
        end
        list.each{|code| yield code }
      end

      def [](code)
        book = find{|book_code, info| book_code == code }
        book ? book[1] : {}
      end

    end

  end
end
