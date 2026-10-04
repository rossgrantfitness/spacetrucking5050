class_name LogbookView
## The logbook: every sight you've seen on the road, and the ones still out
## there (shown as ???). Rare ones are marked with a star. Opens from the
## pause menu, or with L in flight.


## Shows the logbook and waits until it's closed.
static func open(tree: SceneTree) -> void:
	var book := GameState.sights
	var options: Array = []
	var seen := 0
	# Sights you've seen first, then the ones still out there.
	var ordered: Array[LogbookEntry] = []
	for entry in book.entries:
		if entry != null and GameState.logbook.has(entry.id):
			ordered.append(entry)
	for entry in book.entries:
		if entry != null and not GameState.logbook.has(entry.id):
			ordered.append(entry)
	for entry in ordered:
		if entry == null:
			continue
		var times := int(GameState.logbook.get(entry.id, 0))
		if times > 0:
			seen += 1
			options.append({"text": ("* " if entry.rare else "") + entry.display_name,
					"detail": "x%d" % times, "description": entry.description})
		else:
			options.append({"text": "???", "detail": "RARE" if entry.rare else "",
					"description": "Not seen yet. Keep driving." + (" (This one's rare.)" if entry.rare else "")})
	options.append({"text": "CLOSE"})
	var body := "%d of %d sights seen, over %d deliveries." % [seen, book.entries.size(), GameState.deliveries]
	await MenuPanel.ask(tree, "LOGBOOK", body, options)
