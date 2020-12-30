class Thought < ApplicationRecord

    def direction_html
        if rtl then 'rtl' else 'ltr' end
    end
    def html_class
        if rtl then 'sindhi' else '' end
    end

    def self.daily_thought
        Rails.cache.fetch('daily_thought', expires_in: 1.day) do
            Thought.all.sample
        end
    end
end
