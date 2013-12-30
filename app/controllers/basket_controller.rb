# encoding: utf-8

class BasketController < ApplicationController
  def new
    cookies['_hipsterpizza_action'] = 'choose_service'
    redirect_to pizzade_root_path
  end
end
