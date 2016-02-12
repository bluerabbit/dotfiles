Pry.commands.alias_command 'c', 'continue'
Pry.commands.alias_command 's', 'step'
Pry.commands.alias_command 'n', 'next'

# https://gist.github.com/1297510
%w[rubygems pp logger].each do |gem|
  begin
    require gem
  rescue LoadError
  end
end

Pry.config.editor = "emacs -w"

# Default Command Set, add custom methods here:
default_command_set = Pry::CommandSet.new do
  command "copy", "Copy argument to the clip-board" do |str|
     IO.popen('pbcopy', 'w') { |f| f << str.to_s }
  end

  command "clear" do
    system 'clear'
    if ENV['RAILS_ENV']
      output.puts "Rails Environment: " + ENV['RAILS_ENV']
    end
  end

  command "sql", "Send sql over AR." do |query|
    if ENV['RAILS_ENV'] || defined?(Rails)
      pp ActiveRecord::Base.connection.select_all(query)
    else
      pp "Pry did not require the environment, try pry-rails"
    end
  end

  command "caller_method" do |depth|
    depth = depth.to_i || 1
    if /^(.+?):(\d+)(?::in `(.*)')?/ =~ caller(depth+1).first
      file   = Regexp.last_match[1]
      line   = Regexp.last_match[2].to_i
      method = Regexp.last_match[3]
      output.puts [file, line, method]
    end
  end
end

Pry.config.commands.import default_command_set
Pry.config.should_load_plugins = false

if defined? Hirb
 Hirb::View.instance_eval do
   def enable_output_method
     @output_method = true
     @old_print = Pry.config.print
     Pry.config.print = proc do |output, value|
       Hirb::View.view_or_page_output(value) || @old_print.call(output, value)
     end
   end

   def disable_output_method
     Pry.config.print = @old_print
     @output_method = nil
   end
 end

 Hirb.enable
end
