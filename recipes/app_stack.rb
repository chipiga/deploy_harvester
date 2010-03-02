# Hook into +load+ so that all configuration is loaded before we do anything. 
# That way, we know what deployment strategy the main deployment recipe has
# chosen.
on :load do
  case fetch(:app_stack, :passenger)
  when :passenger
    load "#{File.join(File.dirname(__FILE__), 'app_stack', 'passenger')}"
  end
end
