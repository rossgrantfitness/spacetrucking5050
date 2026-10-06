class_name CalendarData
extends Resource
## The galaxy's calendar: a 365-day year in 12 months, each with a made-up
## name that tells a little story (the year starts as a spark, hauls through
## the long bright months, and goes to sleep at the end). Open
## res://data/calendar.tres to rename the months or change their lengths.
##
## The rules for how time passes are in res://autoload/Economy.gd, and how
## fast it goes is in tuning.tres ("Time and bills").


## The months, in order.
@export var month_names: PackedStringArray = PackedStringArray()
## How many days each month has (the same order; they should add up to 365).
@export var month_days: PackedInt32Array = PackedInt32Array()
## One line about each month, shown on the date card when you wake up.
@export var month_notes: PackedStringArray = PackedStringArray()
## The year the game starts in.
@export var start_year: int = 5050
## The name of the clock everyone keeps (shown after the time: "06:42 GST").
@export var clock_name: String = "GST"


## How many days in a year (365 with the default months).
func days_in_year() -> int:
	var total := 0
	for days in month_days:
		total += days
	return maxi(total, 1)


## The date of game day `day` (day 1 = the 1st of the first month of
## start_year): {"day" (of the month), "month" (0 to 11), "year"}.
func date_of(day: int) -> Dictionary:
	var year_length := days_in_year()
	var index := maxi(day, 1) - 1
	var year := start_year + floori(index / float(year_length))
	var left := index % year_length
	var month := 0
	while month < month_days.size() - 1 and left >= month_days[month]:
		left -= month_days[month]
		month += 1
	return {"day": left + 1, "month": month, "year": year}


## The name of month number `month` (0 to 11).
func month_name(month: int) -> String:
	return month_names[month] if month >= 0 and month < month_names.size() else "MONTH %d" % (month + 1)


## The line about month number `month`.
func month_note(month: int) -> String:
	return month_notes[month] if month >= 0 and month < month_notes.size() else ""
