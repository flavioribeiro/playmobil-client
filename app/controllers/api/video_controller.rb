# -*- coding: utf-8 -*-
class Api::VideoController < Api::ApplicationController

  def index
    respond_to do |format|
      format.json do

      task = params["task"]


        render json: {
          task: task
        }
      end
    end
  end

end
