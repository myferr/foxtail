module Foxtail
  class Config
    property files : Array(String)
    property grep_pattern : Regex?
    property json_mode : Bool = false
    property no_color : Bool = false
    property since_duration : Time::Span?
    property ignore_case : Bool = false
    property follow : Bool = true
    property lines : Int32?

    def initialize(@files = [] of String)
    end
  end
end
