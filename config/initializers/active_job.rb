class ActiveJob::Base

  rescue_from(Exception) do |exception|
    error_id = "%06d" % SecureRandom.random_number(10**6)

    ExceptionNotifier.notify_exception(
      exception,
      data: {
        error_id: error_id,
        class: exception.class.name,
        message: exception.message,
        first_line_of_backtrace: exception.backtrace.first,
        cause: exception.cause
      },
      sections: %w(data backtrace)
    )

    Rails.logger.error {
      "A background job exception occurred: #{exception.class.name} [#{error_id}] " +
      "#{exception.message}\n\n#{exception.backtrace.join("\n")}"
    }

    raise
  end

end
