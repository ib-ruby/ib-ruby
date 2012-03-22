# Add method to_ib to render datetime in IB format (zero padded "yyyymmdd HH:mm:ss")
class Time
  def to_ib
    "#{year}#{sprintf("%02d", month)}#{sprintf("%02d", day)} " +
        "#{sprintf("%02d", hour)}:#{sprintf("%02d", min)}:#{sprintf("%02d", sec)}"
  end
end # Time

### Patching Object#error in ib-ruby/errors
#  def error message, type=:standard

### Patching Object#log, #default_logger= in ib-ruby/logger
#  def default_logger
#  def default_logger= logger
#  def log *args
