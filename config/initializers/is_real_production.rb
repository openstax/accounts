def is_real_production?
  [ 'production', 'prodtutor' ].include? secrets.environment_name
end
