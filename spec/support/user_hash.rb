def user_hash(user)
  {
    'id' => user.id,
    'username' => user.username,
    'first_name' => user.first_name,
    'last_name' => user.last_name,
    'full_name' => user.full_name,
    'uuid' => user.uuid
  }
end
