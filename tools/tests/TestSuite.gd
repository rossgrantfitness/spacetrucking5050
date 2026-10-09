extends RefCounted
## The base for every test file in this folder. To add tests: make a file
## whose name ends in "Tests.gd", start it with
##     extends "res://tools/tests/TestSuite.gd"
## and add functions named test_something() that call check().


var problems := 0


## Reports a problem (and makes tools/validate.sh fail) if condition is false.
func check(condition: bool, message: String) -> void:
	if not condition:
		problems += 1
		push_error("Self-test failed: " + message)
