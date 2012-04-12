require 'pp'
require 'rubygems'
require 'irb/completion'

#$require 'ruby-debug'　
#debugger

begin
  require 'what_methods'
rescue LoadError => e
  p e.message
end

#begin
#  require 'wirble'
#  Wirble.init
#  Wirble.colorize
#rescue LoadError => e
#  p e.message
#end

begin
  require 'wirb'
  Wirb.start
rescue LoadError => e
  p e.message
end


begin
  require 'irb/history'
  IRB::History.start_client
rescue LoadError => e
  require 'irb/ext/save-history'
end

#IRB.conf[:PROMPT][:ORIGINAL] = {
#  :PROMPT_I => "%03n:>> ",
#  :PROMPT_N => "%03n:%i>",
#  :PROMPT_S => "%03n:>%l ",
#  :PROMPT_C => "%03n:>> ",
#  :RETURN => "=> %s\n"
#}
IRB.conf[:PROMPT_MODE] = :SIMPLE if IRB.conf[:PROMPT_MODE] == :DEFAULT
IRB.conf[:USE_READLINE] = true
IRB.conf[:AUTO_INDENT] = true
IRB.conf[:SAVE_HISTORY] = 3000
IRB.conf[:HISTORY_PATH] = File::expand_path("~/.irb_history")
