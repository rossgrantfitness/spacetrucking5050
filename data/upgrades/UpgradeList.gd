class_name UpgradeList
extends Resource
## Every upgrade in the game, in shop order. Add one by making an
## UpgradeData .tres file and adding it to res://data/upgrades/upgrades.tres.


@export var upgrades: Array[UpgradeData] = []


func find(id: String) -> UpgradeData:
	for upgrade in upgrades:
		if upgrade != null and upgrade.id == id:
			return upgrade
	return null


## The upgrades on one of Dusty's shelves ("engine", "hauling",
## "navigation" or "cab"), in shop order.
func in_category(category: String) -> Array[UpgradeData]:
	var found: Array[UpgradeData] = []
	for upgrade in upgrades:
		if upgrade != null and upgrade.category == category:
			found.append(upgrade)
	return found
