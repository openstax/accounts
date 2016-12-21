# Based on https://robots.thoughtbot.com/automatically-wait-for-ajax-with-capybara
module CapybaraWait
  def wait_until(timeout = Capybara.default_max_wait_time, interval = 0.1)
    Timeout.timeout(timeout) { sleep(interval) until yield }
  end

  def wait_for_ajax(timeout = Capybara.default_max_wait_time, interval = 0.1)
    wait_until(timeout, interval) { finished_all_ajax_requests? }
  end

  def finished_all_ajax_requests?
    has_jquery? ? page.evaluate_script('jQuery.active').zero? : true
  end

  def wait_for_animations(timeout = Capybara.default_max_wait_time, interval = 0.1)
    wait_until(timeout, interval) { finished_all_animations? }
  end

  def has_jquery?
    page.evaluate_script('typeof(jQuery) == "undefined"') == false
  end

  def finished_all_animations?
    has_jquery? ? page.evaluate_script('$(":animated").length').zero? : true
  end
end

RSpec.configure{ |config| config.include CapybaraWait, type: :feature }
