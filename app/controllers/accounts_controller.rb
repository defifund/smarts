class AccountsController < ApplicationController
  def index
    @accounts = Current.user.accounts.order(:locale)
  end
end
