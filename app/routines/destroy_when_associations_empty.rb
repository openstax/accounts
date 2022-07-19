class DestroyWhenAssociationEmpty

  lev_routine

  protected

  def exec(record, association)
    return if record.nil?
    relations = record.send(association)
    record.destroy if relations.empty?
  end

end
