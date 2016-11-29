module Settings
  class Subjects

    class << self
      include Enumerable

      def each
        Settings::Db.store.subjects.each{|code| yield code }
      end

    end

  end
end
