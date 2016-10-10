I18n.define_enumerator :pl do
  def enumerate kind, list, options
    conjunction = { :all => ' oraz ', :any => ' lub ', :one => ' albo ' }[kind]
    if 2 >= list.length
      return list.join conjunction
    end
    return list[0...-1].join(', ') + conjunction + list[-1]
  end
end
