class UsersController < ApplicationController

    def edit
        @user = current_user
    end

end
