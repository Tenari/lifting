#!/usr/bin/env ruby
# usage:
#   ./lift.rb show workout                      shows next workout and date
#   ./lift.rb show week                         shows this week's workout plans
#   ./lift.rb show food                         shows today's food plan
#   ./lift.rb show program                      shows summary of the program's working sets per body part
#   ./lift.rb show lifts [muscle]               shows the list of lifts matching [muscle]
#   ./lift.rb add exercise -n name -1rm 100     adds an exercise to the list of active lifts
#   ./lift.rb program                           begins interactive programming mode
require 'date'
require 'yaml'

def print_sets(data, sets)
  data[:muscles].each do |muscle|
    printf("%-10s", muscle)
  end
  print "\n"
  data[:muscles].each do |muscle|
    printf("%-10s", (sets[muscle]||0))
  end
  print "\n"
end

def print_workouts(data, workouts)
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

def print_full_workout(data, reps, workout)
  puts "do #{reps} reps per set. Rest 2 minutes between sets"
  workout.each do |lift, sets|
    puts ("%-25s %s @ %s lbs" % [lift, sets, weight_for(data, reps, lift)])
  end
end

def weight_for(data, reps, lift)
  arr = [nil, 100, 95, 91, 88, 85, 83, 81, 79, 77, 75, 73, 72, 70, 69, 68, 66, 65, 64, 63, 62]
  data[:exercises][lift][:max] * arr[reps].to_f / 100.0
end

def show_matching_lifts(data, muscle)
  puts("%-20s %-5s %s" % ["lift", "1RM", 'primary/secondary'])
  data[:exercises].each do |name, details|
    next unless details[:primary] == muscle || details[:secondary] == muscle
    puts("%-20s %-5s %s" % [name, details[:max], details[:primary] == muscle ? 'primary' : 'secondary'])
  end
end

def show_program(data)
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
    print_sets(data, sets)
    print_workouts(data, workouts)
  end
end

def add_exercise(data, args)
  exercise = {}
  mapping = {'-n' => :name, '-1rm' => :max, '-p' => :primary, '-s' => :secondary, '-c' => :compound}
  args.each_with_index do |arg, index|
    if mapping.keys.include?(arg)
      val = args[index+1]
      val = args[index+1].to_i if arg == '-1rm'
      val = !!args[index+1] if arg == '-c'
      exercise[mapping[arg]] = val
    end
  end
  data[:exercises][exercise.delete(:name).to_sym] = exercise
  File.write(FILENAME, YAML.dump(data))
end

today = Date.today
FILENAME = 'lifting_data.yml'
data = YAML.load_file(FILENAME)

if ARGV[0] == 'show'
  if ARGV[1] == 'program'
    show_program(data)
  elsif ARGV[1] == 'lifts'
    show_matching_lifts(data, ARGV[2])
  end
elsif ARGV[0] == 'add'
  if ARGV[1] == 'exercise'
    add_exercise(data, ARGV)
  end
elsif ARGV[0] == 'program'
  show_program(data)
  keep_going = true
  while keep_going do
    puts "what now? (type 'help' if you need it)"
    help = "\tedit week 1\n\tadd week\n\trm week 1\n\tq   (quit)"
    val = STDIN.gets.strip
    if val == 'help'
      puts help
    elsif val.match('edit week')
      week = val.split(" ").last.to_i - 1
      week_obj = data[:program][week]
      puts "which workout?"
      workout_index = STDIN.gets.to_i - 1
      workout = week_obj[:workouts][workout_index]
      print_full_workout(data, week_obj[:reps], workout)
    elsif val == 'q'
      keep_going = false
    end
  end
end
