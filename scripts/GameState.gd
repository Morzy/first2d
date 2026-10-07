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

# { species_id: float } — values sum to 1.0
var population: Dictionary = {"human": 1.0}

var researched: Array[String] = []
var character:  Dictionary   = {}

var _last_save_time: int = 0

signal points_changed
signal tech_researched(tech_id: String)
signal character_updated

func _ready() -> void:
	_last_save_time = int(Time.get_unix_time_from_system())
	_apply_idle()
	_generate_character()

func _process(delta: float) -> void:
	science     += science_rate     * delta
	engineering += engineering_rate * delta
	social      += social_rate      * delta
	emit_signal("points_changed")

# Credit points accumulated while the game was closed
func _apply_idle() -> void:
	var now     := int(Time.get_unix_time_from_system())
	var elapsed := now - _last_save_time
	if elapsed > 0 and elapsed < 86400 * 7:
		science     += science_rate     * elapsed
		engineering += engineering_rate * elapsed
		social      += social_rate      * elapsed
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

func regenerate_character() -> void:
	_generate_character()

func _generate_character() -> void:
	character = CharacterGenerator.generate(population, researched)
	emit_signal("character_updated")
