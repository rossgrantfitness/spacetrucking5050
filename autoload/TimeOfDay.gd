extends Node
## Night and day. There are no shifts (the developer's call: space truckers
## don't do three deliveries a day; a haul takes about a week). The calendar
## (days, weeks, bills) lives in Economy.gd and only moves when you deliver
## or sleep.


## Whether it's night: it follows the player's own clock, 9 p.m. to 6 a.m.
## (The Afterglow Block radio station only broadcasts at night, and the crew
## turn in.)
func is_night() -> bool:
	var hour: int = Time.get_datetime_dict_from_system()["hour"]
	return hour >= 21 or hour < 6
