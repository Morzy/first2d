extends Control

var _s_lbl:      Label
var _e_lbl:      Label
var _c_lbl:      Label
var _rate_lbl:   Label
var _power_lbl:  Label
var _species_lbl: Label
var _talents_lbl: Label
var _tech_btns:  Dictionary = {}   # tech_id → Button

var _energy_lbl:   Label
var _food_lbl:     Label
var _minerals_lbl: Label

var _main_view:  MarginContainer
var _star_map:   StarMapScreen

func _ready() -> void:
	_build_ui()
	GameState.points_changed.connect(_on_pts)
	GameState.tech_researched.connect(_on_tech_done)
	GameState.character_updated.connect(_on_char)
	_on_pts()
	_on_char()

# ── UI construction ───────────────────────────────────────────────────────────

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.06, 0.14)
	bg.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bg)

	_main_view = MarginContainer.new()
	_main_view.set_anchors_preset(PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		_main_view.add_theme_constant_override("margin_" + side, 10)
	add_child(_main_view)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 6)
	_main_view.add_child(root)

	_h(root, "★  星 际 帝 国  ★", 20)
	root.add_child(HSeparator.new())

	# Research resources
	_h(root, "研究资源", 13)
	var res_row := HBoxContainer.new()
	res_row.alignment = BoxContainer.ALIGNMENT_CENTER
	res_row.add_theme_constant_override("separation", 18)
	root.add_child(res_row)
	_s_lbl = _lbl("理科: 0",  Color(0.45, 0.85, 1.0),  15)
	_e_lbl = _lbl("工科: 0",  Color(1.0,  0.72, 0.3),   15)
	_c_lbl = _lbl("社科: 0",  Color(0.55, 1.0,  0.55),  15)
	res_row.add_child(_s_lbl)
	res_row.add_child(_e_lbl)
	res_row.add_child(_c_lbl)

	_rate_lbl = _lbl("", Color(0.65, 0.65, 0.65), 11)
	_rate_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_rate_lbl)

	_power_lbl = _lbl("帝国武力: 0", Color(1.0, 0.5, 0.5), 13)
	_power_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_power_lbl)

	root.add_child(HSeparator.new())

	# Empire resources (from conquered planets)
	_h(root, "帝国资源", 13)
	var emp_row := HBoxContainer.new()
	emp_row.alignment = BoxContainer.ALIGNMENT_CENTER
	emp_row.add_theme_constant_override("separation", 16)
	root.add_child(emp_row)
	_energy_lbl   = _lbl("能源: 0",  Color(1.0, 0.9, 0.3), 13)
	_food_lbl     = _lbl("食物: 0",  Color(0.5, 1.0, 0.5), 13)
	_minerals_lbl = _lbl("矿物: 0",  Color(0.8, 0.6, 1.0), 13)
	emp_row.add_child(_energy_lbl)
	emp_row.add_child(_food_lbl)
	emp_row.add_child(_minerals_lbl)

	root.add_child(HSeparator.new())

	# Star map button
	var map_btn := Button.new()
	map_btn.text = "▶  星际地图"
	map_btn.size_flags_horizontal = SIZE_EXPAND_FILL
	map_btn.pressed.connect(_show_star_map)
	root.add_child(map_btn)

	root.add_child(HSeparator.new())

	# Character
	_h(root, "当前主角", 13)
	_species_lbl = Label.new()
	_species_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_species_lbl)
	_talents_lbl = Label.new()
	_talents_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_talents_lbl)

	root.add_child(HSeparator.new())

	# Tech tree
	_h(root, "科技树", 13)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	root.add_child(scroll)

	var tech_vbox := VBoxContainer.new()
	tech_vbox.size_flags_horizontal = SIZE_EXPAND_FILL
	tech_vbox.add_theme_constant_override("separation", 4)
	scroll.add_child(tech_vbox)
	_build_tech_buttons(tech_vbox)

	# Star map overlay (full-screen, hidden until opened)
	_star_map = StarMapScreen.new()
	_star_map.set_anchors_preset(PRESET_FULL_RECT)
	_star_map.visible = false
	_star_map.back_pressed.connect(_show_main)
	add_child(_star_map)

func _build_tech_buttons(container: VBoxContainer) -> void:
	for tech_id: String in TechDB.DATA:
		var btn := Button.new()
		btn.text = _tech_text(tech_id)
		btn.disabled = not GameState.can_research(tech_id)
		btn.size_flags_horizontal = SIZE_EXPAND_FILL
		btn.pressed.connect(func(): GameState.research(tech_id))
		container.add_child(btn)
		_tech_btns[tech_id] = btn

# ── Screen transitions ────────────────────────────────────────────────────────

func _show_star_map() -> void:
	_main_view.visible = false
	_star_map.visible  = true

func _show_main() -> void:
	_star_map.visible  = false
	_main_view.visible = true

# ── Signal handlers ───────────────────────────────────────────────────────────

func _on_pts() -> void:
	_s_lbl.text    = "理科: "   + _fmt(GameState.science)
	_e_lbl.text    = "工科: "   + _fmt(GameState.engineering)
	_c_lbl.text    = "社科: "   + _fmt(GameState.social)
	_rate_lbl.text = "产出/秒  理%.2f  工%.2f  社%.2f" % [
		GameState.science_rate, GameState.engineering_rate, GameState.social_rate
	]
	_power_lbl.text    = "帝国武力: %d" % int(GameState.empire_power)
	_energy_lbl.text   = "能源: "   + _fmt(GameState.energy)
	_food_lbl.text     = "食物: "   + _fmt(GameState.food)
	_minerals_lbl.text = "矿物: "   + _fmt(GameState.minerals)
	for tid: String in _tech_btns:
		if tid not in GameState.researched:
			_tech_btns[tid].disabled = not GameState.can_research(tid)

func _on_tech_done(tech_id: String) -> void:
	if tech_id in _tech_btns:
		_tech_btns[tech_id].text     = "✓ " + TechDB.DATA[tech_id]["name"]
		_tech_btns[tech_id].disabled = true
		_tech_btns[tech_id].modulate = Color(0.5, 1.0, 0.5)
	for tid: String in _tech_btns:
		if tid not in GameState.researched:
			_tech_btns[tid].disabled = not GameState.can_research(tid)

func _on_char() -> void:
	var c := GameState.character
	if c.is_empty():
		return
	_species_lbl.text = "物种: " + c.get("species_name", "?")
	var lines: PackedStringArray = []
	for t: Dictionary in c.get("talents", []):
		lines.append("  %s — %s" % [t["data"]["name"], t["data"]["desc"]])
	_talents_lbl.text = "天赋:\n" + "\n".join(lines) if lines.size() > 0 else "天赋: 无"

# ── Helpers ───────────────────────────────────────────────────────────────────

func _tech_text(tech_id: String) -> String:
	var tech: Dictionary = TechDB.DATA[tech_id]
	var cost: Dictionary = tech.get("cost", {})

	var cost_parts: PackedStringArray = []
	if cost.get("S", 0) > 0: cost_parts.append("理%s" % _fmt(cost["S"]))
	if cost.get("E", 0) > 0: cost_parts.append("工%s" % _fmt(cost["E"]))
	if cost.get("C", 0) > 0: cost_parts.append("社%s" % _fmt(cost["C"]))
	var cost_str := "、".join(cost_parts) if cost_parts.size() > 0 else "免费"

	var prereqs: Array = tech.get("prereqs", [])
	var prereq_str := ""
	if not prereqs.is_empty():
		var names: PackedStringArray = []
		for p: String in prereqs:
			names.append(TechDB.DATA.get(p, {}).get("name", p))
		prereq_str = "\n  前置: " + "、".join(names)

	return "%s  [%s]\n  %s%s" % [tech["name"], cost_str, tech.get("desc", ""), prereq_str]

func _h(parent: Control, text: String, size: int) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(l)

func _lbl(text: String, color: Color, size: int = 12) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_size_override("font_size", size)
	return l

func _fmt(n: float) -> String:
	if n >= 1_000_000.0: return "%.2fM" % (n / 1_000_000.0)
	if n >= 1_000.0:     return "%.1fK" % (n / 1_000.0)
	return "%d" % int(n)
