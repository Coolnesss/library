class WelcomeController < ApplicationController
    
    def index        
        @thought = Thought.daily_thought(rtl: rtl?)
        @stats = Book.stats
    end
    
    def about
    end

end
