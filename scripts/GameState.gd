extends Node

# Research point pools
var science:     float = 0.0
var engineering: float = 0.0
var social:      float = 0.0

# Production per real second
var science_rate:     float = 1.0
var engineering_rate: float = 1.0
var social_rate:      float = 1.0

var empire_power: float = 0.0

# Empire resources from conquered planets
var energy:    float = 0.0
var food:      float = 0.0
var minerals:  float = 0.0
var energy_rate:   float = 0.0
var food_rate:     float = 0.0
var minerals_rate: float = 0.0

# { species_id: float } — values sum to 1.0
var population: Dictionary = {"human": 1.0}

var researched: Array[String] = []
var character:  Dictionary   = {}

# Star map data: Array of system Dictionaries
var star_systems: Array = []

var _last_save_time: int = 0

signal points_changed
signal tech_researched(tech_id: String)
signal character_updated
signal conquest_updated(system_id: String)

func _ready() -> void:
	_last_save_time = int(Time.get_unix_time_from_system())
	_apply_idle()
	_generate_character()
	_init_star_systems()

func _process(delta: float) -> void:
	science     += science_rate     * delta
	engineering += engineering_rate * delta
	social      += social_rate      * delta
	energy      += energy_rate      * delta
	food        += food_rate        * delta
	minerals    += minerals_rate    * delta
	emit_signal("points_changed")

func _apply_idle() -> void:
	var now     := int(Time.get_unix_time_from_system())
	var elapsed := now - _last_save_time
	if elapsed > 0 and elapsed < 86400 * 7:
		science     += science_rate     * elapsed
		engineering += engineering_rate * elapsed
		social      += social_rate      * elapsed
		energy      += energy_rate      * elapsed
		food        += food_rate        * elapsed
		minerals    += minerals_rate    * elapsed
	_last_save_time = now

func can_research(tech_id: String) -> bool:
	if tech_id in researched:
		return false
	var tech: Dictionary = TechDB.DATA.get(tech_id, {})
	if tech.is_empty():
		return false
	for prereq: String in tech.get("prereqs", []):
		if prereq not in researched:
			return false
	var cost: Dictionary = tech.get("cost", {})
	return science     >= cost.get("S", 0.0) \
		and engineering >= cost.get("E", 0.0) \
		and social      >= cost.get("C", 0.0)

func research(tech_id: String) -> bool:
	if not can_research(tech_id):
		return false
	var cost: Dictionary = TechDB.DATA[tech_id]["cost"]
	science     -= cost.get("S", 0.0)
	engineering -= cost.get("E", 0.0)
	social      -= cost.get("C", 0.0)
	researched.append(tech_id)
	_apply_effect(tech_id)
	emit_signal("tech_researched", tech_id)
	emit_signal("points_changed")
	return true

func _apply_effect(tech_id: String) -> void:
	var effect: Dictionary = TechDB.DATA[tech_id].get("effect", {})
	if "all_rate_pct" in effect:
		var m := 1.0 + float(effect["all_rate_pct"])
		science_rate     *= m
		engineering_rate *= m
		social_rate      *= m
	if "science_rate_pct" in effect:
		science_rate *= 1.0 + float(effect["science_rate_pct"])
	if "engineering_rate_pct" in effect:
		engineering_rate *= 1.0 + float(effect["engineering_rate_pct"])
	if "social_rate_pct" in effect:
		social_rate *= 1.0 + float(effect["social_rate_pct"])
	if "empire_power" in effect:
		empire_power += float(effect["empire_power"])

func _generate_character() -> void:
	character = CharacterGenerator.generate(population, researched)
	emit_signal("character_updated")

# ── Star map ──────────────────────────────────────────────────────────────────

func _init_star_systems() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42108  # fixed seed — same map each run until save/load added
	var names := ["猎户α系", "天狼β系", "参宿γ系", "心宿δ系",
				  "织女ε系", "牛郎ζ系", "北极η系", "南门θ系"]
	star_systems.clear()
	for i in range(names.size()):
		var enemy_count := rng.randi_range(2, 5)
		var planets: Array = []
		for j in range(10):
			var is_enemy := j < enemy_count
			planets.append({
				"inhabited":      is_enemy,
				"defense":        rng.randi_range(100, 800) if is_enemy else 0,
				"conquered":      false,
				"energy_yield":   rng.randf_range(0.2, 1.2),
				"food_yield":     rng.randf_range(0.2, 1.2),
				"minerals_yield": rng.randf_range(0.2, 1.2),
			})
		star_systems.append({
			"id":            "sys_%d" % i,
			"name":          names[i],
			"stars":         1,
			"total_planets": 10,
			"enemy_count":   enemy_count,
			"planets":       planets,
			"status":        "unknown",   # unknown / active / conquered
		})

func start_conquest(system_idx: int) -> void:
	if system_idx < 0 or system_idx >= star_systems.size():
		return
	var sys: Dictionary = star_systems[system_idx]
	if sys["status"] == "unknown":
		sys["status"] = "active"
	emit_signal("conquest_updated", sys["id"])

func attack_planet(system_idx: int, planet_idx: int) -> bool:
	if system_idx < 0 or system_idx >= star_systems.size():
		return false
	var sys: Dictionary = star_systems[system_idx]
	if planet_idx < 0 or planet_idx >= sys["planets"].size():
		return false
	var planet: Dictionary = sys["planets"][planet_idx]
	if not planet["inhabited"] or planet["conquered"]:
		return false
	if empire_power < planet["defense"]:
		return false
	planet["conquered"] = true
	energy_rate   += planet["energy_yield"]
	food_rate     += planet["food_yield"]
	minerals_rate += planet["minerals_yield"]
	var all_done := true
	for p: Dictionary in sys["planets"]:
		if p["inhabited"] and not p["conquered"]:
			all_done = false
			break
	if all_done:
		sys["status"] = "conquered"
	emit_signal("conquest_updated", sys["id"])
	emit_signal("points_changed")
	return true
