extends Node
## The base's gentle clock: days, and three shifts per day (morning, evening,
## night).
##
## Empty for now. Fills in at M3 (which dispatch employee is on shift) and M6
## (each flight uses up one shift, sleeping starts a new day, rent is weekly).
##
## This is never a stressful timer: time only moves forward when the player
## does something (flies a job, goes to sleep).
