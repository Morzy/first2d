class_name CharacterGenerator

static func generate(population: Dictionary, researched: Array) -> Dictionary:
	var species_id := _weighted_pick(population)
	var species: Dictionary = SpeciesDB.DATA[species_id]
	return {
		"species_id":   species_id,
		"species_name": species["name"],
		"talents":      _pick_talents(species_id, researched, population),
	}

static func _weighted_pick(weights: Dictionary) -> String:
	var roll := randf()
	var acc := 0.0
	for key: String in weights:
		acc += float(weights[key])
		if roll <= acc:
			return key
	return weights.keys()[-1]

static func _pick_talents(species_id: String, researched: Array, population: Dictionary) -> Array:
	var species: Dictionary = SpeciesDB.DATA[species_id]
	var pool: Array = species["talent_pool"].duplicate()

	if "interspecies_union" in researched:
		for other_id: String in population:
			if other_id != species_id and SpeciesDB.DATA.has(other_id):
				for t: String in SpeciesDB.DATA[other_id]["talent_pool"]:
					if t not in pool:
						pool.append(t)

	pool.shuffle()
	var count: int = species.get("talents_per_char", 2)
	var result: Array = []
	for t_id: String in pool.slice(0, min(count, pool.size())):
		result.append({"id": t_id, "data": TalentDB.DATA[t_id]})
	return result
