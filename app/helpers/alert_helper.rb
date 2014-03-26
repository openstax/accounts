# Copyright 2011-2013 Rice University. Licensed under the Affero General Public 
# License version 3 or later.  See the COPYRIGHT file for details.

module AlertHelper
  def convert_flash_alert
    add_local_error_alert now: true, content: flash.now[:alert] if flash.now[:alert]
  end

  def convert_flash_notice
    add_local_info_alert  now: true, content: flash.now[:notice] if flash.now[:notice]
  end

  def javascript_not_enabled_alert
    { type:       :error,
      intro:      "Hey!",
      content:    "Please enable JavaScript in your browser! Many #{SITE_NAME} pages will not work properly without it.",
      no_dismiss: true
    }
  end

  def add_global_error_alert(args={})
    alerts = fetch_global_alerts(args)
    add_error_alert(alerts, args)
  end

  def add_global_success_alert(args={})
    alerts = fetch_global_alerts(args)
    add_success_alert(alerts, args)
  end

  def add_global_info_alert(args={})
    alerts = fetch_global_alerts(args)
    add_info_alert(alerts, args)
  end

  def add_local_error_alert(args={})
    alerts = fetch_local_alerts(args)
    add_error_alert(alerts, args)
  end

  def add_local_success_alert(args={})
    alerts = fetch_local_alerts(args)
    add_success_alert(alerts, args)
  end

  def add_local_info_alert(args={})
    alerts = fetch_local_alerts(args)
    add_info_alert(alerts, args)
  end

  def fetch_global_alerts(args)
    args[:now] ? now_global_alerts : global_alerts
  end

  def fetch_local_alerts(args)
    args[:now] ? now_local_alerts : local_alerts
  end

  def add_error_alert(alerts, args={})
    args[:type] = :error
    add_alert alerts, args
  end

  def add_success_alert(alerts, args={})
    args[:type] = :success
    add_alert alerts, args
  end

  def add_info_alert(alerts, args={})
    args[:type] = :info
    add_alert alerts, args
  end

  def local_alerts
    flash[:local_alerts] ||= []
  end

  def now_local_alerts
    flash.now[:local_alerts] ||= []
  end

  def global_alerts
    flash[:global_alerts] ||= []
  end

  def now_global_alerts
    flash.now[:global_alerts] ||= []
  end

  VALID_ALERT_TYPES = [:error, :success, :info]
  def add_alert(alerts, args)
    raise "alert :content must be given"                    unless args[:content].present?
    raise "alert :type must be given"                       unless args[:type]
    raise "alert :type must be one of #{VALID_ALERT_TYPES}" unless VALID_ALERT_TYPES.include?(args[:type])
    alerts << args
  end

  def alert_class_attr(alert)
    classes = ["alert"]
    classes << case alert[:type]
               when :error
                 "alert-error"
               when :success
                 "alert-success"
               when :info
                 "alert-info"
               else
                 raise "invalid alert :type (#{alert[:type]})"
               end
    "class=\"#{classes.join(' ')}\"".html_safe
  end

  def alert_data_attr(alert)
    "data-test-#{alert[:type]}-alert"
  end

  def alert_no_dismiss?(alert)
    alert[:no_dismiss].present?
  end

  def alert_intro?(alert)
    alert[:intro].present?
  end

  def alert_intro(alert)
    alert[:intro]
  end

  def alert_content(alert)
    alert[:content]
  end
end
