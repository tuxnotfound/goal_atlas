# Creates the initial admin user if no admin exists. Prints a generated
# 32-char password to stdout once; rotate it after first login via
# /passwords/new (or `rails console`).
#
# Env vars (both required to actually create the user):
#   ADMIN_EMAIL    — email to create
#   ADMIN_PASSWORD — optional; if omitted we generate one
#
# Idempotent: skips silently if any admin already exists or ADMIN_EMAIL is
# unset.

if User.where(admin: true).exists?
  puts "Admin user already exists; skipping."
elsif ENV["ADMIN_EMAIL"].blank?
  puts "ADMIN_EMAIL not set; skipping admin user seed."
else
  password = ENV["ADMIN_PASSWORD"].presence || SecureRandom.alphanumeric(32)

  user = User.create!(
    email_address: ENV["ADMIN_EMAIL"],
    password: password,
    admin: true
  )

  puts ""
  puts "=" * 64
  puts "Admin user created:"
  puts "  email:    #{user.email_address}"
  if ENV["ADMIN_PASSWORD"].present?
    puts "  password: <set from ADMIN_PASSWORD env>"
  else
    puts "  password: #{password}"
    puts "  ↑ COPY THIS NOW. It will not be shown again."
  end
  puts "=" * 64
  puts ""
end
