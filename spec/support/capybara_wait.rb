# Based on https://robots.thoughtbot.com/automatically-wait-for-ajax-with-capybara
module CapybaraWait
  def wait_until(timeout = Capybara.default_max_wait_time, interval = 0.1)
    Timeout.timeout(timeout) { sleep(interval) until yield }
  end

  def wait_for_ajax(timeout = Capybara.default_max_wait_time, interval = 0.1)
    wait_until(timeout, interval) { finished_all_ajax_requests? }
  end

  def finished_all_ajax_requests?
    return true unless has_jquery?
    begin
      page.evaluate_script('jQuery.active').zero?
    rescue Selenium::WebDriver::Error::JavascriptError
      true
    end
  end

  def wait_for_animations(timeout = Capybara.default_max_wait_time, interval = 0.1)
    wait_until(timeout, interval) { finished_all_animations? }
  end

  def has_jquery?
    page.evaluate_script('typeof(jQuery) == "undefined"') == false
  end

  def finished_all_animations?
    return true unless has_jquery?
    begin
      page.evaluate_script('jQuery(":animated").length').zero?
    rescue Selenium::WebDriver::Error::JavascriptError
      true
    end
  end
end

RSpec.configure{ |config| config.include CapybaraWait, type: :feature }
