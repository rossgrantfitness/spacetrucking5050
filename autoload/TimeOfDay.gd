extends Node
## The base's gentle clock: days, and three shifts per day (morning, evening,
## night).
##
## Empty for now. Fills in at M3 (which dispatch employee is on shift) and M6
## (each flight uses up one shift, sleeping starts a new day, rent is weekly).
##
## This is never a stressful timer: time only moves forward when the player
## does something (flies a job, goes to sleep).


## Whether it's the night shift. Until shifts arrive (M6), it follows the
## player's own clock: 9 p.m. to 6 a.m. (The Afterglow Block radio station
## only broadcasts at night.)
func is_night() -> bool:
	var hour: int = Time.get_datetime_dict_from_system()["hour"]
	return hour >= 21 or hour < 6
