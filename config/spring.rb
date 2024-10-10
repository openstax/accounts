# Prevent warning on OS X
ENV['OBJC_DISABLE_INITIALIZE_FORK_SAFETY'] = 'YES'

Spring.watch(
  ".ruby-version",
  ".rbenv-vars",
  "tmp/restart.txt",
  "tmp/caching-dev.txt"
)
