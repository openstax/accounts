# Based on https://robots.thoughtbot.com/automatically-wait-for-ajax-with-capybara
module CapybaraWait
  def wait_until(timeout = Capybara.default_max_wait_time, interval = 0.1)
    Timeout.timeout(timeout) { sleep(interval) until yield }
  end

  def wait_for_ajax(timeout = Capybara.default_max_wait_time, interval = 0.1)
    wait_until(timeout, interval) { finished_all_ajax_requests? }
  end

  def finished_all_ajax_requests?
    page.evaluate_script('jQuery.active').zero?
  end

  def wait_for_animations(timeout = Capybara.default_max_wait_time, interval = 0.1)
    wait_until(timeout, interval) { finished_all_animations? }
  end

  def finished_all_animations?
    page.evaluate_script('$(":animated").length').zero?
  end
end

RSpec.configure{ |config| config.include CapybaraWait, type: :feature }
