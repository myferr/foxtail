def parse_duration(s : String) : Time::Span?
  match = s.match(/^(\d+)(s|m|h|d)?$/)
  return nil unless match

  value = match[1].to_i
  unit = match[2]? || "s"

  case unit
  when "s" then Time::Span.new(seconds: value)
  when "m" then Time::Span.new(minutes: value)
  when "h" then Time::Span.new(hours: value)
  when "d" then Time::Span.new(days: value)
  else        nil
  end
end
