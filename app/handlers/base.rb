
# Common methods for all input handlers.  Input handlers are classes that are
# responsible for taking input data from a form or other widget and doing something
# with it.
#
# All input handlers must:
#   1) live in the "Handlers" namespace 
#   2) include this module ("include Handlers::Base")
#   3) implement the 'exec' method
#   4) implement the 'authorized?' method
#
# Input handlers may:
#   1) implement the 'setup' method which runs before
#      'authorized?' and 'exec'.  This method can do anything, and will likely
#      include setting up some instance objects based on the params.
#
# All handler instance methods have the following available to them:
#   1) 'params' -- the params from the input
#   2) 'caller' -- the user submitting the input
#   3) 'errors' -- an object in which to store errors
#   
# this module, e.g.:
# 
#   class Handlers::MyHandler
#     include Handler
#   protected
#     def authorized?
#       # return true iff exec is allowed to be called, e.g. might
#       # check the caller against the params
#     def exec
#       # do the work, add errors to errors object as needed
#     end
#   end
#
module Handlers
  module Base

    def self.included(base)
      base.extend(ClassMethods)
    end

    def handle(caller, params)
      containing_handler.present? ?
        handle_guts(caller, params) :
        ActiveRecord::Base.transaction { handle_guts(caller, params) }
    end

    module ClassMethods
      def handle(caller, params)
        new.handle(caller, params)
      end
    end

    class Error
      attr_accessor :code
      attr_accessor :data
      attr_accessor :ui_label

      def initialize(args)
        self.code = args[:code]
        self.data = args[:data]
        self.ui_label = args[:ui_label]
      end
    end

    class Errors < Array
      def add(args)
        super.push(Errors.new)
      end

      def [](key)
        super[key]
      end
    end

  protected

    attr_accessor :params
    attr_accessor :caller
    attr_accessor :errors

    def handle_guts(caller, params)
      self.caller = caller
      self.params = params
      self.errors = Errors.new

      setup
      raise SecurityTransgression unless authorized?
      exec

      self.errors
    end

    def authorized?
      false # default for safety, forces implementation in the handler
    end

    # don't know if we really need this nesting capability like in algorithm
    attr_accessor :containing_handler

    def handle_nested(other_handler, caller, params)
      other_handler = other_handler.new if other_handler.is_a? Class

      raise IllegalArgument, "A handler can only nestedly handle another handler" \
        if !(other_handler.eigenclass.included_modules.include? InputHandler)

      other_handler.containing_handler = self
      other_handler.handle(caller, params)
    end

  end
end
