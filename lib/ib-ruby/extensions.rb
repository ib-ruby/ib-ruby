class Time
  # Render datetime in IB format (zero padded "yyyymmdd HH:mm:ss")
  def to_ib
    "#{year}#{sprintf("%02d", month)}#{sprintf("%02d", day)} " +
        "#{sprintf("%02d", hour)}:#{sprintf("%02d", min)}:#{sprintf("%02d", sec)}"
  end
end # Time

class Fixnum
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

### Patching Object#error in ib-ruby/errors
#  def error message, type=:standard

### Patching Object#log, #default_logger= in ib-ruby/logger
#  def default_logger
#  def default_logger= logger
#  def log *args
