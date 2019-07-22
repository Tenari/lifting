class Printing
  def self.sets(data, sets)
    data[:muscles].each do |muscle|
      printf("%-10s", muscle)
    end
    print "\n"
    data[:muscles].each do |muscle|
      printf("%-10s", (sets[muscle]||0))
    end
    print "\n"
  end

  def self.workouts(data, workouts)
    print "\n"
    header = ""
    count = 0
    workouts.each do |wk|
      count += 1
      header += "workout ##{count}           "
    end
    puts header

    data[:muscles].count.times do |time|
      str = ""
      workouts.each do |wk|
        muscle = wk.keys[time]
        if wk[muscle]
          str += ("%-10s %-10s" % [muscle, wk[muscle]])
        else
          str += "                     "
        end
      end
      puts str unless str.strip == ""
    end
  end

  def self.full_workout(data, reps, workout)
    puts "do #{reps} reps per set. Rest 2 minutes between sets"
    workout.each do |lift, sets|
      puts ("%-25s %s @ %s lbs" % [lift, sets, weight_for(data, reps, lift)])
    end
  end
end
