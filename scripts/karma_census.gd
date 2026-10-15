class_name KarmaCensus
extends RefCounted

# Rolled starting census (ecosystem-census): same equilibrium rules every game,
# different numbers every game. Pure static taking an explicit rng so tests can
# seed it deterministically. Counts always include the player as one member.


const PREY := ["oruga", "sapo", "raton", "ardilla", "topo"]
const HUNTERS := ["zorro", "lobo", "halcon"]


static func roll(rng: RandomNumberGenerator, player_species := "raton", theme_override := "") -> Dictionary:
	var theme := theme_override if theme_override != "" else _pick_theme(rng)
	var counts := _themed_counts(rng, theme)
	_clamp_diet(counts)
	_clamp_ratio(counts)
	if int(counts.get(player_species, 0)) < 1:
		counts[player_species] = 1
	return {"counts": counts, "theme": theme}


static func _pick_theme(rng: RandomNumberGenerator) -> String:
	return KarmaData.CENSUS_THEMES[rng.randi() % KarmaData.CENSUS_THEMES.size()]


static func _themed_counts(rng: RandomNumberGenerator, theme: String) -> Dictionary:
	var counts := {}
	if theme == "lean":
		for sp in KarmaData.CENSUS_FLOOR:
			counts[sp] = int(KarmaData.CENSUS_FLOOR[sp])
		return counts
	for sp in KarmaData.CENSUS_MID:
		counts[sp] = int(KarmaData.CENSUS_MID[sp])
	match theme:
		"bloom":
			counts["oruga"] = int(counts["oruga"]) + 2
		"rodent":
			counts["raton"] = int(counts["raton"]) + 2
			counts["ardilla"] = int(counts["ardilla"]) + 2
		"wet":
			counts["sapo"] = int(counts["sapo"]) + 2
			counts["topo"] = int(counts["topo"]) - 1
	for sp in counts:
		counts[sp] = clampi(int(counts[sp]) + rng.randi() % 3 - 1,
			int(KarmaData.CENSUS_FLOOR[sp]), int(KarmaData.CENSUS_CAP[sp]))
	return counts


static func _clamp_diet(counts: Dictionary) -> void:
	while float(counts["sapo"]) + float(counts["topo"]) * 0.5 > float(KarmaData.CENSUS["insectMaxDemand"]):
		if int(counts["topo"]) > int(KarmaData.CENSUS_FLOOR["topo"]):
			counts["topo"] = int(counts["topo"]) - 1
		else:
			counts["sapo"] = int(counts["sapo"]) - 1


static func _clamp_ratio(counts: Dictionary) -> void:
	while _prey(counts) < _hunters(counts) * float(KarmaData.CENSUS["preyPerHunter"]):
		var cut := false
		for sp in ["lobo", "halcon", "zorro"]:
			if int(counts[sp]) > int(KarmaData.CENSUS_FLOOR[sp]):
				counts[sp] = int(counts[sp]) - 1
				cut = true
				break
		if cut:
			continue
		if int(counts["oruga"]) < int(KarmaData.CENSUS_CAP["oruga"]):
			counts["oruga"] = int(counts["oruga"]) + 1
			continue
		break


static func _prey(counts: Dictionary) -> float:
	var n := 0.0
	for sp in PREY:
		n += float(counts[sp])
	return n


static func _hunters(counts: Dictionary) -> float:
	var n := 0.0
	for sp in HUNTERS:
		n += float(counts[sp])
	return n
