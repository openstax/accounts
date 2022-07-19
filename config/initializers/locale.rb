module I18n
  module Enumerators
    # A fallback enumerator which just returns all elements separated by ','
    module Simple
      def self.enumerate kind, list, options = {}
        return list.join ', '
      end
    end

    @@enumerators = {}

    def self.get language
      return @@enumerators[language] || Simple
    end

    def self.define language, mod
      @@enumerators[language] = mod
    end
  end

  # Transforms an Array of I18n keys into a localised enumeration. For example
  #
  #   I18n.enumerate :all, [:a, :b, :c]
  #
  # would return "noun_a, noun_b and noun_c" in :en locale and
  # "rzeczownik_a, rzeczownik_b oraz rzeczownik_c" in :pl locale (assuming that
  # :a resolves to "noun_a" in :en locale and to "rzeczownik_a" in :pl locale).
  #
  # Similarly
  #
  #   I18n.enumerate :any, [:a, :b, :c]
  #
  # would return "noun_a, noun_b or noun_c" in :en locale and
  # "rzeczonik_a, rzeczownik_b lub rzeczonik_c" in :pl locale.
  #
  # Optionally, one can use expand: option to control whether the items should
  # be expanded or not. Thus, with expand: false, the following becomes correct
  #
  #   I18n.enumerate kind, ["not a translation key", ...], expand: false
  #
  # Since grammatical form of enumeration will often depend on kind of elements
  # enumerated and reason for enumerating them a description of this intent
  # is required to be specified via the kind parameter. Valid values are
  # :all  Enumeration lists a complete set of items.
  # :any  Enumeration lists a list of possible choices. Any number of them may
  #       be chosen.
  # :one  Enumeration lists a list of possible choices. Only one item may be
  #       chosen.
  def self.enumerate kind, list, options = {}
    unless [:all, :any, :one].include? kind
      raise ArgumentError.new "kind must be one of: :all, :any or :one"
    end

    if options.fetch :expand, true
      list.map! {|key| I18n.translate key, options }
    end

    return Enumerators.get(locale).enumerate kind, list, options
  end

  # Defines an enumerator for a new language. The passed block will be evaluated
  # as content of a module and must define at least the enumerate method.
  #
  #   I18n.define_enumerator :language_tag, do
  #     def enumerate kind, list, options
  #       # returns localised enumeration
  #     end
  #
  #     # optionally additional methods used by enumerate
  #   end
  #
  # The enumerate method is passed a list of already expanded items; it should
  # not attempt to expand them.
  def self.define_enumerator language, &block
    enumerator = Module.new
    enumerator.instance_eval &block
    Enumerators.define language, enumerator
  end
end

Dir.glob('config/locales/enumerators/*.rb').each do |file|
  load file
end
