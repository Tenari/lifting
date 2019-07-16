Requires ruby to be installed

Usage:

```
git clone https://github.com/Tenari/lifting
cd lifting
./lift.rb reset
```

Then for each exercise you know your "1 rep max" for, run

```
./lift.rb set max [lift] [1rm]
```
example:
```
./lift.rb set max bench 225
```

- To list available exercises: `./lift.rb show lifts`
- To add an exercise: `./lift.rb add exercise -n [name] -1rm [max] -p [primary muscle group] -s [optional secondary muscle group] [-c if a compound exercise]`

Then devise your lifting program and insert it day by day by:

1. making a file called workout.txt that looks like
```
bench 4x14 3
front_squat 4x14 3
upright_row 2x18 3
db_standing_curl 2x18 3
calfs 2x18 3
bar_shrug 2x18 3
```
where each row is `lift [sets]x[reps] rir` (rir = reps in reserve)

2. running `./lift.rb add workout workout.txt 2019-07-17`

then you can see your next workout by running
```
./lift.rb show workout
```
or your next week of workouts by running
```
./lift.rb show week
```

as you do lifts, just run
```
log 'bar shrug' 165x8 165x7 -rir 1
```
filling in the lift [weight]x[reps] for each set and rir. this will update your calculated maxes (if its higher) in the yml file, which will update how much weight it suggests you lift on future exercises
