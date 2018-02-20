module SubjectsUtils
  def self.form_choices_to_salesforce_string(form_choices)
    return nil if form_choices.nil?

    # form_choices is a hash of book code name to "1" or "0", depending on
    # if that book was selected or not selected, respectively.  We need to convert this
    # hash to a semicolon-separated string of Salesforce book codes, e.g.:
    # "Macro Econ;Micro Econ;US History;AP Macro Econ".

    form_choices.select{|k,v| v == '1'}
                .keys
                .map{|code| Settings::Subjects[code]['sf']}
                .join(';')
  end
end
