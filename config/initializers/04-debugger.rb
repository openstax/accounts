unless Rails.env.production?
  # Let environment variables dictate which debugger to use; they are not compatible
  if ENV['DEBUGGER'] == 'byebug'
    # Call 'debugger' anywhere in the code to stop execution and get a debugger console
    require 'byebug'
  else
    # Debug in VS Code
    require 'ruby-debug-ide'
    require 'debase'
  end
end
