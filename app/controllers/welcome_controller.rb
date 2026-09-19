class WelcomeController < ApplicationController
    
    def index        
        @thought = Thought.daily_thought
    end
    
    def about
    end

end
