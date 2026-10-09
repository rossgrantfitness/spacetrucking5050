class_name JobList
extends Resource
## Every job in the game. Add a job by making a JobData .tres file and
## adding it to the list in res://data/jobs/jobs.tres.


@export var jobs: Array[JobData] = []


## The job with this id, or null.
func find(id: String) -> JobData:
	for job in jobs:
		if job != null and job.id == id:
			return job
	return null
