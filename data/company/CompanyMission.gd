class_name CompanyMission
extends Resource
## One of the boss's missions: a job only he hands out, in order, at the
## {company} office (see `missions` in res://data/company/company.tres).
## He pitches it, insults you, and insults you again when you collect the
## check. Buying the company only comes up once every mission's done.
##
## Lines can use {bunny}, {boss}, {company} and {currency}.


## The job itself (a one-off, off the job board).
@export var job: JobData
## Not until she's made this many deliveries, ever (so the missions are
## spread out between other work).
@export_range(0, 1000) var min_deliveries: int = 0
## The boss, handing it over.
@export var pitch: PackedStringArray = PackedStringArray()
## The boss, when she says "not right now".
@export var declined: PackedStringArray = PackedStringArray()
## The boss, at check-in after she's delivered it.
@export var done: PackedStringArray = PackedStringArray()


## Whether it's been delivered.
func is_done() -> bool:
	return job != null and job.id in GameState.finished_jobs
