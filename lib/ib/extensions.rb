class Time
  # Render datetime in IB format (zero padded "yyyymmdd HH:mm:ss")
  def to_ib
    "#{year}#{sprintf("%02d", month)}#{sprintf("%02d", day)} " +
        "#{sprintf("%02d", hour)}:#{sprintf("%02d", min)}:#{sprintf("%02d", sec)}"
  end
end # Time

class Numeric
  # Conversion 0/1 into true/false
  def to_bool
    self == 0 ? false : true
  end
end

class TrueClass
  def to_bool
    self
  end
end

class FalseClass
  def to_bool
    self
  end
end

class String
  def to_bool
    case self.chomp.upcase
      when 'TRUE', 'T', '1'
        true
      when 'FALSE', 'F', '0', ''
        false
      else
        error "Unable to convert #{self} to bool"
    end
  end
end

class NilClass
  # We still need to pass on nil, meaning: no value
  def to_bool
    self
  end
end

class Symbol
  def to_f
    0
  end

  # ActiveModel serialization depends on this method
  def <=> other
    to_s <=> other.to_s
  end
end

class Object
  # We still need to pass on nil, meaning: no value
  def to_sup
    self.to_s.upcase unless self.nil?
  end
end

module Kernel
  # we use a duration for the base from the current time and bundle it with
  # current millisecond which gives us uniq enough (in selected time frame) Integer
  def duration_based_rand duration
    t=Time.now
    "#{(t.to_i % duration).to_i}#{((t - t.to_i).to_f * 1_000).to_i}".to_i
  end
end

### Patching Object#error in ib/errors
#  def error message, type=:standard

### Patching Object#log, #default_logger= in ib/logger
#  def default_logger
#  def default_logger= logger
#  def log *args
