class SearchUsers

  lev_routine transaction: :no_transaction

protected

  NAME_DISCARDED_CHAR_REGEX = /[^A-Za-z ']/

  # TODO Use options to limit what can be searched for (e.g. users can't search by email) 
  # and what can be returned (e.g. Users can't see email addresses)

  def exec(query, options={}, type=:any)
    users = User.scoped

    # Return all results if no search terms
    outputs[:users] = users and return if query.blank?
    
    KeywordSearch.search(query) do |with|

      with.keyword :username do |usernames|
        usernames = usernames.collect do |username| 
          username.gsub(User::USERNAME_DISCARDED_CHAR_REGEX,'').downcase + '%'
        end

        users = users.where{username.like_any usernames}
      end

      with.keyword :first_name do |first_names|
        users = users.where{lower(first_name).like_any my{prep_names(first_names)}}
      end

      with.keyword :last_name do |last_names|
        users = users.where{lower(last_name).like_any my{prep_names(last_names)}}
      end

      with.keyword :full_name do |full_names|
        users = users.where{lower(full_name).like_any my{prep_names(full_names)}}
      end

      with.keyword :id do |ids|
        users = users.where{id.in ids}
      end

      with.keyword :email do |emails|
        users = users.joins{contact_infos}
                     .where{{contact_infos: sift(:email_addresses)}}
                     .where{{contact_infos: sift(:verified)}}
                     .where{contact_infos.value.in emails}
      end

    end

    outputs[:users] = users
  end

  def prep_names(names)
    names.collect{|name| name.gsub(NAME_DISCARDED_CHAR_REGEX, '').downcase + '%'}
  end

end