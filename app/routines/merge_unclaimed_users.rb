class MergeUnclaimedUsers

  lev_routine

  protected

  uses_routine DestroyUser

  TRANSFER_ASSOCIATIONS = [ :group_members, :group_owners, :application_users ]

  # This will eventually perform a merge on the two accounts,
  # but for now we're just deleteing the unclaimed account
  def exec(email)

    living_user = email.user

    unclaimed_contacts = EmailAddress.with_users
      .where(value: email.value)
      .where(users: { state: User::UNCLAIMED })
      .where.not(id: email.id)

    unclaimed_contacts.each do | contact |
      dying_user = contact.user
      TRANSFER_ASSOCIATIONS.each do | association |

        # We can get away with using send(:assocation).each
        # since they're all :has_many.  If we need to support belongs_to/has_one
        # we could check dying_user.reflections[association].collection?
        dying_user.send(association).each do | belonging_model |
          # we can also get away with just re-assinging the user since
          # all the associations have an inverse that's named "user".
          # If they did not we could use the association's inverse_of to figure it out
          belonging_model.user = living_user
          unless belonging_model.save
            transfer_errors_from(belonging_model, {type: :verbatim})
          end
        end

      end

      run(DestroyUser, dying_user)
      transfer_errors_from(dying_user, {type: :verbatim})
    end

  end
end
