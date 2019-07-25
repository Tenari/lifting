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
#   ./lift.rb schedule program --beginner       schedules the default beginner program
require 'date'
require 'yaml'
require './printing.rb'
require './show.rb'

RM_CONVERSION = [nil, 100, 95, 91, 88, 85, 83, 81, 79, 77, 75, 73, 72, 70, 69, 68, 66, 65, 64, 63, 62, 61, 60, 59, 58, 57, 56, 55, 54, 53, 52, 51, 49]
RR_INDEX = {max: 1, low: 6, mid: 11, high: 21}

def rep_range_key(reps)
  case reps.to_i
  when 1..5
    :max
  when 6..10
    :low
  when 11..20
    :mid
  when 21..30
    :high
  end
end

def weight_for(data, reps, lift, rir = 1)
  reps += rir - 1
  key = rep_range_key(reps)
  key = :max if !data[:exercises][lift][key]
  data[:exercises][lift][key] * RM_CONVERSION[reps].to_f / RM_CONVERSION[RR_INDEX[key]].to_f
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

def add_workout(data, args)
  return puts "./lift.rb add workout [filename|string] yyyy-mm-dd [-m]\n     format is `[lift] [sets]x[reps] [rir] [optional notes]\\n`" unless [4,5].include?(args.count)
  current_date = Date.parse(args[3])
  if args.include?("-m")
    workouts_data = args[2]
    workouts_data = File.read(workouts_data).to_s if File.exists?(workouts_data)
    workouts_data.split("=====\n").each do |workout_data|
      if workout_data.length > 12
        add_workout_logic(data, workout_data, current_date)
      else
        current_date = Date.parse(workout_data)
      end
    end
  else
    workout_data = args[2]
    workout_data = File.read(workout_data).to_s if File.exists?(workout_data)
    add_workout_logic(data, workout_data, current_date)
  end
end

def add_workout_logic(data, workout_data, date)
  workout = {}
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
  data[:schedule][date] = (data[:schedule][date] || {}).merge(workout)
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
  record[:sets].each do |set|
    max_key = rep_range_key(set[:reps].to_i)
    # calculate based off 1 rep in reserve (rir) 
    mod = set[:rir].to_i - 1
    new_max = (RM_CONVERSION[RR_INDEX[max_key]].to_f * set[:weight].to_i / RM_CONVERSION[mod+set[:reps].to_i].to_f).round
    data[:exercises][lift][max_key] = new_max if new_max > (data[:exercises][lift][max_key]||0)
  end
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

FILENAME = 'data.yml'
data = YAML.load_file(FILENAME)

if ARGV[0] == 'show'
  if ARGV[1] == 'program'
    Show.program(data)
  elsif ARGV[1] == 'lifts'
    Show.matching_lifts(data, ARGV[2])
  elsif ARGV[1] == 'workout'
    Show.workout(data, ARGV)
  elsif ARGV[1] == 'week'
    Show.week(data, ARGV)
  elsif ARGV[1] == 'schedule'
    Show.schedule(data, ARGV)
  end
elsif ARGV[0] == 'add'
  self.send("add_#{ARGV[1]}", data, ARGV)
elsif ARGV[0] == 'log'
  log_sets(data, ARGV.drop(1)) # ./lift.rb log [lift] [set..] -rir 2       adds the set(s) to your history
elsif ARGV[0] == 'program'
  Show.program(data)
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
      Printing.full_workout(data, week_obj[:reps], workout)
    elsif val == 'q'
      keep_going = false
    end
  end
elsif ARGV[0] == 'reset'
  reset_data(data)
end
