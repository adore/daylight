##
# Runs `alias_api` in the console during API development to re-alias the
# reloaded constants.  Otherwise, they will hold onto the old un-reloaded
# constants in memory.
#
# This is not intended for end-users of the API, but can be used by them if
# needed.
#
# You must enable this functionality:
#
#     require 'daylight/client_reloader'
#
# NOTE: Currently only works with IRB

module ClientReloader
  extend ActiveSupport::Concern

  included do
    def reload! print=true
      super

      puts "Realiasing API..." if print
      suppress_warnings do
        Daylight::API.send(:alias_apis)
      end
    end
  end

  class << self
    def include
      if console && defined?(console::ExtendCommandBundle)
        console::ExtendCommandBundle.class_eval do
          include ClientReloader
        end
      end
    end

    def console
      # we'll figure a way to set other consoles (eg. pry) later if neccessary
      @console ||= IRB rescue nil
    end
  end
end

ClientReloader.include
