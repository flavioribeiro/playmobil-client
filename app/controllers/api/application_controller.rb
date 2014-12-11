# -*- coding: utf-8 -*-

class Api::ApplicationController < ActionController::Base

  def not_acceptable
    head 406
  end
end
