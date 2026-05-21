class Current < ActiveSupport::CurrentAttributes
  attribute :session
  attribute :mcp_user
  delegate :user, to: :session, allow_nil: true
end
