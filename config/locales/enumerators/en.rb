I18n.define_enumerator :en do
  def enumerate kind, list, options
    conjunction = { :all => ' and ', :any => ' or ', :one => ' or ' }[kind]
    if 2 >= list.length
      return list.join conjunction
    end
    return list[0...-1].join(', ') + conjunction + list[-1]
  end
end
