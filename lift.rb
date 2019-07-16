#!/usr/bin/env ruby
# usage:
#   ./lift.rb show workout                      shows next workout and date
#   ./lift.rb show week                         shows this week's workout plans
#   ./lift.rb show food                         shows today's food plan
#   ./lift.rb show program                      shows summary of the program's working sets per body part
#   ./lift.rb show lifts [muscle]               shows the list of lifts matching [muscle]
#   ./lift.rb add exercise -n name -1rm 100     adds an exercise to the list of active lifts
#   ./lift.rb program                           begins interactive programming mode
#   ./lift.rb add workout [filename|string]     format is `[lift] [sets]x[reps] [rir] [optional notes]\n`
#   ./lift.rb log [muscle] [set..] -rir 2       adds the set(s) to your history
require 'date'
require 'yaml'

RM_CONVERSION = [nil, 100, 95, 91, 88, 85, 83, 81, 79, 77, 75, 73, 72, 70, 69, 68, 66, 65, 64, 63, 62, 61, 60, 59, 58, 57, 56, 55, 54, 53, 52, 51, 49]
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

def weight_for(data, reps, lift, rir = 1)
  reps += rir - 1
  data[:exercises][lift][:max] * RM_CONVERSION[reps].to_f / 100.0
end

# calculate based off 1 rep in reserve (rir) 
def set_to_max(reps, weight, rir)
  mod = rir.to_i - 1
  (100.0 * weight.to_i / RM_CONVERSION[mod+reps.to_i].to_f).round
end

def show_matching_lifts(data, muscle)
  maxlength = data[:exercises].keys.map(&:to_s).map(&:length).max
  puts("%-#{maxlength}s %-5s %s" % ["LIFT", "1RM", 'primary/secondary'])
  data[:exercises].each do |name, details|
    next unless details[:primary] == muscle || details[:secondary] == muscle || muscle.nil?
    puts("%-#{maxlength}s %-5s %s" % [name, details[:max], details[:primary] == muscle ? 'primary' : 'secondary'])
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

def show_workout(data, args, specific_date = nil)
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

def show_week(data, args)
  date = Date.today
  show_workout(data, args, date)
  show_workout(data, args, date+1)
  show_workout(data, args, date+2)
  show_workout(data, args, date+3)
  show_workout(data, args, date+4)
  show_workout(data, args, date+5)
  show_workout(data, args, date+6)
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

#   ./lift.rb add workout [filename|string] yyyy-mm-dd     format is `[lift] [sets]x[reps] [rir] [optional notes]\n`
def add_workout(data, args)
  return puts "./lift.rb add workout [filename|string] yyyy-mm-dd     format is `[lift] [sets]x[reps] [rir] [optional notes]\\n`" if args.count != 4
  workout = {}
  workout_data = args[2]
  workout_data = File.read(workout_data).to_s if File.exists?(workout_data)
  workout_data.split("\n").each do |line|
    parts = line.split(" ", 4)
    lift = parts.first.gsub('_', " ")
    sets = parts[1].split('x').first.to_i
    reps = parts[1].split('x').last.to_i
    workout[lift] = {
      sets: sets,
      reps: reps,
      rir: parts[2].to_i,
    }
    workout[lift][:notes] = parts[3] if parts[3]
  end
  data[:schedule] ||= {}
  data[:schedule][Date.parse(args[3])] = (data[:schedule][Date.parse(args[3])] || {}).merge(workout)
  File.write(FILENAME, YAML.dump(data))
end

def log_sets(data, args)
  lift = args[0].to_sym
  data[:history] ||= {}
  data[:history][Date.today] ||= {}
  record = data[:history][Date.today][lift] || {sets: []}
  rir = 1
  args.each_with_index do |arg, index|
    if arg.include?('x')
      record[:sets].push({weight: arg.split('x').first.to_i, reps: arg.split('x').last.to_i})
    elsif arg == '-rir'
      rir = args[index+1].to_i
    end
  end
  record[:sets].each do |set|
    set[:rir] ||= rir
  end
  data[:history][Date.today][lift] = record
  # update the max
  new_max = record[:sets].map{|set| set_to_max(set[:reps], set[:weight], set[:rir]) }.max
  data[:exercises][lift][:max] = [data[:exercises][lift][:max], new_max].max
  File.write(FILENAME, YAML.dump(data))
end

def reset_data(data)
  data[:exercises].each do |lift, details|
    details[:max] = 0
  end
  data[:history] = {}
  data[:schedule] = {}
  File.write(FILENAME, YAML.dump(data))
end

FILENAME = 'lifting_data.yml'
data = YAML.load_file(FILENAME)

if ARGV[0] == 'show'
  if ARGV[1] == 'program'
    show_program(data)
  elsif ARGV[1] == 'lifts'
    show_matching_lifts(data, ARGV[2])
  elsif ARGV[1] == 'workout'
    show_workout(data, ARGV)
  elsif ARGV[1] == 'week'
    show_week(data, ARGV)
  end
elsif ARGV[0] == 'add'
  self.send("add_#{ARGV[1]}", data, ARGV)
#   ./lift.rb log [lift] [set..] -rir 2       adds the set(s) to your history
elsif ARGV[0] == 'log'
  log_sets(data, ARGV.drop(1))
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
elsif ARGV[0] == 'reset'
  reset_data(data)
end
