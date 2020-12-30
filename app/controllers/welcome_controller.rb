class WelcomeController < ApplicationController
    
    def index        
        @thought = Thought.daily_thought
        @markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, extensions = {autolink: true})
    end
    
    def about
    end

end
