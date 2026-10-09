class_name EmailList
extends Resource
## Every email in the game (res://data/pc/emails.tres). Add one by adding
## an EmailData to the list in the inspector.


@export var emails: Array[EmailData] = []


## The emails that have arrived so far (their story flags are among
## `flags`, like GameState.flags), newest (latest in the list) first.
func inbox(flags: Dictionary) -> Array[EmailData]:
	var found: Array[EmailData] = []
	for email in emails:
		if email != null and (email.requires_flag.is_empty() or flags.has(email.requires_flag)):
			found.push_front(email)
	return found
