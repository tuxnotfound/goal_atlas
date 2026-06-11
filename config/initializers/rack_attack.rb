# Throttles abusive requests with Rack::Attack so brute-forcing /session
# (login) costs an attacker rapidly. Layered on top of SessionsController's
# Rails 8 `rate_limit` (which uses Solid Cache) for defense in depth at the
# middleware layer, before any controller logic runs.

class Rack::Attack
  # 5 POSTs to /session per IP per minute
  throttle("session/ip", limit: 5, period: 1.minute) do |req|
    req.ip if req.post? && req.path == "/session"
  end

  # 3 POSTs to /session per email address per 5 minutes
  throttle("session/email", limit: 3, period: 5.minutes) do |req|
    if req.post? && req.path == "/session"
      req.params["email_address"].to_s.strip.downcase.presence
    end
  end

  self.throttled_responder = lambda do |env|
    [429, { "Content-Type" => "text/plain" }, ["Too many attempts. Try again later.\n"]]
  end
end
