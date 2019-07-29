class Show
  def self.matching_lifts(data, muscle)
    maxlength = data[:exercises].keys.map(&:to_s).map(&:length).max
    puts("%-#{maxlength}s %-5s %s" % ["LIFT", "1RM", 'primary/secondary'])
    data[:exercises].each do |name, details|
      next unless details[:primary] == muscle || details[:secondary] == muscle || muscle.nil?
      puts("%-#{maxlength}s %-5s %s" % [name, details[:max], details[:primary] == muscle ? 'primary' : 'secondary'])
    end
  end

  def self.program(data)
    week_num = 0
    data[:program].each do |week|
      week_num += 1
      sets = {}
      workouts = []
      week[:workouts].each do |workout|
        wk = {}
        workout.each do |lift, set_count|
          sets[data[:exercises][lift][:primary]] ||= 0
          sets[data[:exercises][lift][:primary]] += set_count
          wk[data[:exercises][lift][:primary]] ||= 0
          wk[data[:exercises][lift][:primary]] += set_count
          if data[:exercises][lift][:secondary]
            sets[data[:exercises][lift][:secondary]] ||= 0
            sets[data[:exercises][lift][:secondary]] += (set_count * 0.5)
            wk[data[:exercises][lift][:secondary]] ||= 0
            wk[data[:exercises][lift][:secondary]] += (set_count * 0.5)
          end
        end
        workouts.push(wk)
      end
      puts "week #{week_num} totals: #{week[:format]} | #{week[:reps]} reps per set"
      Printing.sets(data, sets)
      Printing.workouts(data, workouts)
    end
  end

  def self.workout(data, args, specific_date = nil)
    date = specific_date || Date.today
    while true do
      if workout = data[:schedule][date]
        puts date
        puts "LIFT                      WEIGHT VOLUME  RiR   notes"
        workout.each do |lift, details|
          weight = weight_for(data, details[:reps].to_i, lift.to_sym, details[:rir]).round.to_i
          puts("%-25s %-6s %sx%-5s %-5s %s" % [lift, weight, details[:sets], details[:reps], details[:rir], details[:notes]])
        end
        print "\n"
        break
      else
        date += 1
      end
      break if specific_date
    end
  end

  def self.week(data, args)
    date = Date.today
    self.workout(data, args, date)
    self.workout(data, args, date+1)
    self.workout(data, args, date+2)
    self.workout(data, args, date+3)
    self.workout(data, args, date+4)
    self.workout(data, args, date+5)
    self.workout(data, args, date+6)
  end

  def self.schedule(data, args)
    date = Date.today
    misses = 0
    while misses < 20 do
      if data[:schedule][date]
        puts date
      else
        misses += 1
      end
      date += 1
    end
  end

  # ./lift.rb show history [lift]
  def self.history(data, args)
    lift = args[2].to_sym
    data[:history].each do |date, lifts|
      next unless lifts[lift]
      puts date
      lifts[lift][:sets].each do |set|
        norm_weight = normalize_weight(set[:weight], set[:reps].to_i, set[:rir])
        rep_key = rep_range_key(set[:reps])
        norm_rep = {max: 1, low: 6, mid: 11, high: 21}[rep_key]
        puts "#{set[:weight]}x#{set[:reps]} @ RIR #{set[:rir]} => #{norm_weight}x#{norm_rep}"
      end
    end
  end
end
