# frozen_string_literal: true

class MyController < ApplicationController
  def show
    @accounts = Current.user.accounts.order(:locale)
  end
end
