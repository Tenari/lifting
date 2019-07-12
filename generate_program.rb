class LiftingProgram
  # musclegroup_sets_per_week is an array of weeks like {chest: 6, shoulders: 6} etc
  def self.generate(data, musclegroup_sets_per_week)
    # auto-generated program rules:
    # 1 big compound lift for upper body and 1 big compound lift for lower body each day
    # work one from following pairs: chest/shoulders hams/quads biceps/triceps abs/calfs traps+neck/forearm
    pairs = {
      chest: :shoulders, shoulders: :chest,
      hams: :quads, quads: :hams,
      biceps: :triceps, triceps: :biceps,
      abs: :calfs, calfs: :abs,
      traps: :forearm, forearm: :traps
    }
    # do up to 2 direct exercises for each muscle group per workout
    # do up to 4 sets of the big compound lift per day
    # workout frequency is determined by total sets per day max
    # 20 working sets per workout max
    #
    # output: [{format: rWrWrWr, reps: 15, workouts: [{press: 4, row: 2}]}]

    program = []
    musclegroup_sets_per_week.each do |week|
      # first, determine the format
      total_working_sets = week.values.inject(0, :+)
      format = 'rWrWrWr'
      format = 'WWrWWrr' if total_working_sets > 60
      format = 'WWrWrWW' if total_working_sets > 80
      format = 'WWrWWWW' if total_working_sets > 100

      workout_count = format.count('W')
      program_week = {format: format, workouts: []}
      workout_count.times do |iter|
        program_week[:workouts][iter] = {}
      end

      data[:muscles].each do |muscle|
        muscle = muscle.to_sym
        next unless week[muscle]
        sets = week[muscle]
        pair = pairs[muscle]
        start_day = 0
        frequency = workout_count / 2
        if pair
          if self.workout_works_muscle(data, program_week[:workouts][0], pair)
            start_day = 1
          end
          if workout_count.odd?
            if week[muscle] > week[pair]
            elsif week[muscle] == week[pair]
            else
              start_day = 1
            end
          end
        end
        frequency = frequency + 1 - start_day
        frequency.times do |iter|
          index = iter * 2 + start_day
          next unless week[muscle]
          heavy_sets = week[muscle] / frequency
          sets_added = 0
          while sets_added < heavy_sets do
            if sets_added == 0 && exercise = data[:exercises].find {|k,e| e[:primary].to_sym == muscle && e[:compound]}
              compound_sets = [heavy_sets, 4].min
              program_week[:workouts][index][exercise.first] = compound_sets
              sets_added += compound_sets
            else
              extra_sets = heavy_sets - sets_added
              exercise = data[:exercises].find {|k,e| e[:primary].to_sym == muscle && !e[:compound]}
              program_week[:workouts][index][exercise.first] = extra_sets
              sets_added += extra_sets
            end
          end
        end

      end
      program.push(program_week)
    end
    program
  end

  def self.workout_works_muscle(data, workout, muscle)
    result =false 
    workout.each do |lift, sets|
      result = true if data[:exercises][lift.to_sym][:primary] == muscle.to_s
    end
    result
  end
end

# LiftingProgram.generate(data, [{chest: 4, shoulders: 8, back: 6, quads:8, hams: 4, calfs: 6, abs: 3, traps: 6, forearm: 3},{chest: 8, shoulders: 4, back: 6, quads: 4, hams: 8, calfs: 3, abs: 6, traps: 3, forearm: 6}])
