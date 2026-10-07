class_name FreightMarket
extends Resource
## THE FREIGHT MARKET: everyday loads that keep the job boards full, around
## the hand-written story jobs. Every place on the freight network posts a
## handful of loads to the other places, made from the cargo kinds below,
## paid by distance, weight and urgency (and the kind of cargo). The boards
## change every `refresh_days` days, so there's always one more haul.
##
## A place joins the network once its `freight_flag` is set (see
## PlaceData's "Freight market" group); `freight_pay_factor` there makes the
## steep, faraway roads pay better. Everything else is tuned here, in
## res://data/freight/freight_market.tres.


## Every kind of everyday freight (see CargoType.gd).
@export var cargo_types: Array[CargoType] = []

@export_group("Pay")
## Every load pays this much to start with...
@export_range(0, 10000, 10) var base_fee: int = 200
## ...plus this much per kilometer, as the crow flies...
@export_range(0.0, 200.0, 0.5) var pay_per_km: float = 14.0
## ...plus this much per billion tons it weighs.
@export_range(0, 10000, 10) var pay_per_billion_tons: int = 150
## Careful cargo's care bonus: this share of the pay.
@export_range(0.0, 2.0, 0.05) var care_share: float = 0.35
## A rush job's bonus: this share of the pay.
@export_range(0.0, 2.0, 0.05) var rush_share: float = 0.3
## A rush job's deadline: the time it takes at this speed (m/s; the
## Thumper cruises at 55, so faster than that means some boosting).
@export_range(10.0, 500.0, 1.0) var rush_speed: float = 70.0

@export_group("Boards")
## How many loads each board posts.
@export_range(0, 20, 1) var loads_per_board: int = 5
## The boards change every this many days.
@export_range(1, 30, 1) var refresh_days: int = 1
## Loads don't go to places closer than this (km).
@export_range(0.0, 100.0, 1.0) var shortest_km: float = 5.0

## Freight job ids start with this.
const PREFIX: String = "freight:"


## Whether `id` is a freight market job (not a hand-written one).
static func is_freight_id(id: String) -> bool:
	return id.begins_with(PREFIX)


## Which board posting period `day` falls in.
func period_of(day: int) -> int:
	return int(floor(float(maxi(day - 1, 0)) / float(maxi(refresh_days, 1))))


## Whether a place is on the freight network right now.
func place_open(place: PlaceData) -> bool:
	if place == null or not place.on_the_map:
		return false
	return place.freight_flag.is_empty() or GameState.has_flag(place.freight_flag)


## The loads posted at `place_id` in board period `period` (the same every
## time you look, until the period changes). `market_seed` makes each save
## game's market its own.
func board(place_id: String, period: int, market_seed: int) -> Array[JobData]:
	var found: Array[JobData] = []
	var here := GameState.places.find(place_id)
	if not place_open(here):
		return found
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([market_seed, period, place_id])
	var to_places: Array[PlaceData] = []
	for place in GameState.places.places:
		if place != here and place_open(place) and here.map_position.distance_to(place.map_position) / 1000.0 >= shortest_km:
			to_places.append(place)
	if to_places.is_empty():
		return found
	for n in loads_per_board:
		var kinds := cargo_types.filter(func(option: CargoType) -> bool:
			return option != null and option.ships_from(place_id) \
					and (option.requires_flag.is_empty() or GameState.has_flag(option.requires_flag)))
		if kinds.is_empty():
			break
		var kind: CargoType = kinds[rng.randi_range(0, kinds.size() - 1)]
		var choices := to_places.filter(func(place: PlaceData) -> bool: return kind.ships_to(place.id))
		if choices.is_empty():
			continue
		var to: PlaceData = choices[rng.randi_range(0, choices.size() - 1)]
		found.append(make_job(kind, here, to, rng, "%s%s:%d:%d" % [PREFIX, place_id, period, n]))
	return found


## Posts one load of `kind` from `from` to `to`.
func make_job(kind: CargoType, from: PlaceData, to: PlaceData, rng: RandomNumberGenerator, id: String) -> JobData:
	var job := JobData.new()
	job.id = id
	job.cargo_name = _pick(kind.names, rng, "Freight")
	job.client_name = _pick(kind.clients, rng, "A shipper")
	job.description = _pick(kind.blurbs, rng, "")
	job.from_place = from.id
	job.to_place = to.id
	job.weight = snappedf(rng.randf_range(kind.weight_range.x, kind.weight_range.y), 1e7)
	job.cargo_look = kind.look
	job.cargo_color = kind.color
	var km := from.map_position.distance_to(to.map_position) / 1000.0
	job.base_pay = pay_for(km, job.weight, kind.pay_factor * maxf(from.freight_pay_factor, to.freight_pay_factor))
	if kind.care_kind != "none":
		job.care_kind = kind.care_kind
		job.care_bonus = snappedi(roundi(job.base_pay * care_share), 10)
	if rng.randf() < kind.rush_chance:
		job.rush_seconds = snappedf(km * 1000.0 / rush_speed, 10.0)
		job.rush_bonus = snappedi(roundi(job.base_pay * rush_share), 10)
	return job


## The base pay for a load: the fee, plus distance and weight, times
## `factor` (the cargo kind and the road).
func pay_for(km: float, weight: float, factor: float) -> int:
	var pay := (base_fee + km * pay_per_km + weight / 1e9 * pay_per_billion_tons) * factor
	return snappedi(roundi(pay), 10)


## A freight job as plain data, for the save file.
static func to_save(job: JobData) -> Dictionary:
	return {"id": job.id, "cargo_name": job.cargo_name, "client_name": job.client_name, "description": job.description,
			"from_place": job.from_place, "to_place": job.to_place, "weight": job.weight, "base_pay": job.base_pay,
			"care_bonus": job.care_bonus, "care_kind": job.care_kind, "rush_seconds": job.rush_seconds,
			"rush_bonus": job.rush_bonus, "cargo_look": job.cargo_look, "cargo_color": job.cargo_color.to_html()}


## A freight job back from the save file (null if it doesn't make sense).
static func from_save(data: Dictionary) -> JobData:
	if not is_freight_id(str(data.get("id", ""))) or GameState.places.find(str(data.get("to_place", ""))) == null:
		return null
	var job := JobData.new()
	job.id = str(data["id"])
	job.cargo_name = str(data.get("cargo_name", "Freight"))
	job.client_name = str(data.get("client_name", "A shipper"))
	job.description = str(data.get("description", ""))
	job.from_place = str(data.get("from_place", ""))
	job.to_place = str(data["to_place"])
	job.weight = maxf(float(data.get("weight", 5e8)), 0.0)
	job.base_pay = maxi(int(data.get("base_pay", 0)), 0)
	job.care_bonus = maxi(int(data.get("care_bonus", 0)), 0)
	job.care_kind = str(data.get("care_kind", "fragile"))
	job.rush_seconds = maxf(float(data.get("rush_seconds", 0.0)), 0.0)
	job.rush_bonus = maxi(int(data.get("rush_bonus", 0)), 0)
	job.cargo_look = str(data.get("cargo_look", "auto"))
	job.cargo_color = Color.from_string(str(data.get("cargo_color", "")), Color(0, 0, 0, 0))
	job.repeatable = true
	return job


static func _pick(options: PackedStringArray, rng: RandomNumberGenerator, fallback: String) -> String:
	return options[rng.randi_range(0, options.size() - 1)] if not options.is_empty() else fallback
