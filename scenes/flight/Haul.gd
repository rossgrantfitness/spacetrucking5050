class_name Haul
extends RefCounted
## A job in progress: what you're hauling, how long you've been flying it,
## and what it's on track to pay. The HUD reads it for the cargo, pay and
## rush-timer readouts.


var job: JobData
## Seconds since takeoff with this job.
var elapsed: float = 0.0
var delivered: bool = false
## What it paid on delivery (0 until then).
var paid: int = 0


func _init(new_job: JobData) -> void:
	job = new_job


func update(delta: float) -> void:
	if not delivered:
		elapsed += delta


## What it would pay if you delivered right now with cargo in `condition`.
func projected_pay(condition: float) -> int:
	return paid if delivered else job.pay_for(condition, elapsed)


## Seconds left to earn the rush bonus (negative once you're late).
func rush_seconds_left() -> float:
	return job.rush_seconds - elapsed


func deliver(condition: float) -> void:
	if delivered:
		return
	paid = job.pay_for(condition, elapsed)
	delivered = true
