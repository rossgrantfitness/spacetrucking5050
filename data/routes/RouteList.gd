class_name RouteList
extends Resource
## Every route choice out on the road (see RouteData.gd).


@export var routes: Array[RouteData] = []


func find(id: String) -> RouteData:
	for route in routes:
		if route != null and route.id == id:
			return route
	return null
