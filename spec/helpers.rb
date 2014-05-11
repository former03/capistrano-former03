require 'pp'

def get_last_desc(md,key)
  if md.has_key?(key)
    return md[key]
  else
    return md
  end
end


module Helpers
  def set_task
    puts described_class
    #puts "TEST: #{example.metadata}"
  end
  def get_task
    puts described_class
    #puts "TEST: #{example.metadata}"
  end
end
