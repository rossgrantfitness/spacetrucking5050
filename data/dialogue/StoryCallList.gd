class_name StoryCallList
extends Resource
## Every story call in the game (see StoryCall.gd), in the order they're
## checked: the first one that fits is the one that plays.


@export var calls: Array[StoryCall] = []


## The first call that should play now, or null.
func next_call() -> StoryCall:
	for story_call in calls:
		if story_call != null and story_call.fits():
			return story_call
	return null
