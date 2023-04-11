
# Monkey patch for Origami to support latest ruby
module Origami

    module Filter
  
        module Predictor

            def pre_prediction(data)
                return data unless @params.Predictor.is_a?(Integer)
  
                apply_pre_prediction(data, **prediction_parameters)
            end

            def post_prediction(data)
              return data unless @params.Predictor.is_a?(Integer)
  
              apply_post_prediction(data, **prediction_parameters)
            end
        end
    end
end


module Origami

    module String

    class Date < LiteralString #:nodoc:

        def self.parse(str) #:nodoc:
            raise InvalidDateError, "Not a valid Date string" unless str =~ REGEXP_TOKEN

            date =
            {
                year: $~['year'].to_i
            }

            date[:month] = $~['month'].to_i if $~['month']
            date[:day] = $~['day'].to_i if $~['day']
            date[:hour] = $~['hour'].to_i if $~['hour']
            date[:min] = $~['min'].to_i if $~['min']
            date[:sec] = $~['sec'].to_i if $~['sec']

            if %w[+ -].include?($~['ut'])
                utc_offset = $~['ut_hour_off'].to_i * 3600 + $~['ut_min_off'].to_i * 60
                utc_offset = -utc_offset if $~['ut'] == '-'

                date[:utc_offset] = utc_offset
            end

            Origami::Date.new(**date)
        end

        #
        # Returns current Date String in UTC time.
        #
        def self.now
            now = Time.now.utc

            date =
            {
                year: now.strftime("%Y").to_i,
                month: now.strftime("%m").to_i,
                day: now.strftime("%d").to_i,
                hour: now.strftime("%H").to_i,
                min: now.strftime("%M").to_i,
                sec: now.strftime("%S").to_i,
                utc_offset: now.utc_offset
            }

            Origami::Date.new(**date)
        end
    end
end
end