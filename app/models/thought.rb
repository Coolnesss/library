class Thought < ApplicationRecord

    def direction_html
        if rtl then 'rtl' else 'ltr' end
    end
    def html_class
        if rtl then 'sindhi' else '' end
    end

    # One thought a day per language: right-to-left ones for Sindhi pages.
    # Falls back to any thought while a language has none.
    def self.daily_thought(rtl:)
        Rails.cache.fetch(['daily_thought', rtl], expires_in: 1.day) do
            where(rtl: rtl ? true : [false, nil]).sample || all.sample
        end
    end
end
