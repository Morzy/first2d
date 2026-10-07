class_name StarMapScreen
extends Control

signal back_pressed

enum State { LIST, DETAIL, CONQUEST }
var _state: State = State.LIST
var _selected_idx: int = -1

var _content_root: VBoxContainer
var _energy_lbl:   Label
var _food_lbl:     Label
var _minerals_lbl: Label

func _ready() -> void:
	_build_frame()
	GameState.points_changed.connect(_update_resources)
	GameState.conquest_updated.connect(func(_id: String): _refresh_content())

# ── Frame (persistent chrome) ─────────────────────────────────────────────────

func _build_frame() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.04, 0.12)
	bg.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 10)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	margin.add_child(root)

	# Header
	var header := HBoxContainer.new()
	root.add_child(header)
	var back_btn := Button.new()
	back_btn.text = "← 返回主界面"
	back_btn.pressed.connect(func(): emit_signal("back_pressed"))
	header.add_child(back_btn)
	var title := Label.new()
	title.text = "  ★  星 际 地 图  ★"
	title.add_theme_font_size_override("font_size", 17)
	header.add_child(title)

	root.add_child(HSeparator.new())

	# Resource bar — from conquered planets
	var res_row := HBoxContainer.new()
	res_row.add_theme_constant_override("separation", 20)
	res_row.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(res_row)
	_energy_lbl   = _lbl("能源: 0",  Color(1.0, 0.9, 0.3), 12)
	_food_lbl     = _lbl("食物: 0",  Color(0.5, 1.0, 0.5), 12)
	_minerals_lbl = _lbl("矿物: 0",  Color(0.8, 0.6, 1.0), 12)
	res_row.add_child(_energy_lbl)
	res_row.add_child(_food_lbl)
	res_row.add_child(_minerals_lbl)

	root.add_child(HSeparator.new())

	# Scrollable dynamic content
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	root.add_child(scroll)

	_content_root = VBoxContainer.new()
	_content_root.size_flags_horizontal = SIZE_EXPAND_FILL
	_content_root.add_theme_constant_override("separation", 6)
	scroll.add_child(_content_root)

	_refresh_content()

# ── Content rebuilder ─────────────────────────────────────────────────────────

func _refresh_content() -> void:
	for child in _content_root.get_children():
		_content_root.remove_child(child)
		child.queue_free()
	match _state:
		State.LIST:     _build_list()
		State.DETAIL:   _build_detail()
		State.CONQUEST: _build_conquest()

func _build_list() -> void:
	_h(_content_root, "已探测星系", 14)
	_content_root.add_child(HSeparator.new())
	for i in range(GameState.star_systems.size()):
		var sys: Dictionary = GameState.star_systems[i]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		_content_root.add_child(row)

		var info := Label.new()
		info.text = "%s   1恒星 · 10行星 · %d敌方   %s" % [
			sys["name"], sys["enemy_count"], _status_str(sys["status"])
		]
		if sys["status"] == "conquered":
			info.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
		elif sys["status"] == "active":
			info.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
		info.size_flags_horizontal = SIZE_EXPAND_FILL
		row.add_child(info)

		var btn := Button.new()
		btn.text = "查看"
		var idx := i
		btn.pressed.connect(func():
			_selected_idx = idx
			_state = State.DETAIL
			_refresh_content()
		)
		row.add_child(btn)

func _build_detail() -> void:
	if _selected_idx < 0:
		_state = State.LIST
		_build_list()
		return
	var sys: Dictionary = GameState.star_systems[_selected_idx]

	var back_btn := Button.new()
	back_btn.text = "← 星系列表"
	back_btn.pressed.connect(func():
		_state = State.LIST
		_refresh_content()
	)
	_content_root.add_child(back_btn)

	_h(_content_root, sys["name"], 16)
	_content_root.add_child(HSeparator.new())

	_info_row(_content_root, "恒星数量", "1 颗")
	_info_row(_content_root, "总行星数", "10 颗")
	_info_row(_content_root, "敌方星球", "%d 颗" % sys["enemy_count"])
	_info_row(_content_root, "当前状态", _status_str(sys["status"]))

	_content_root.add_child(HSeparator.new())

	match sys["status"]:
		"unknown":
			var atk_btn := Button.new()
			atk_btn.text = "▶  开始进攻此星系"
			atk_btn.size_flags_horizontal = SIZE_EXPAND_FILL
			atk_btn.pressed.connect(func():
				GameState.start_conquest(_selected_idx)
				_state = State.CONQUEST
				_refresh_content()
			)
			_content_root.add_child(atk_btn)

		"active":
			var cont_btn := Button.new()
			cont_btn.text = "▶  继续进攻"
			cont_btn.size_flags_horizontal = SIZE_EXPAND_FILL
			cont_btn.pressed.connect(func():
				_state = State.CONQUEST
				_refresh_content()
			)
			_content_root.add_child(cont_btn)

		"conquered":
			var done_lbl := Label.new()
			done_lbl.text = "★  已完全征服"
			done_lbl.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
			done_lbl.add_theme_font_size_override("font_size", 14)
			done_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			_content_root.add_child(done_lbl)
			_content_root.add_child(HSeparator.new())
			_h(_content_root, "本系每秒产出", 12)
			var te := 0.0; var tf := 0.0; var tm := 0.0
			for p: Dictionary in sys["planets"]:
				if p["inhabited"]:
					te += p["energy_yield"]
					tf += p["food_yield"]
					tm += p["minerals_yield"]
			_info_row(_content_root, "能源", "+%.2f/s" % te)
			_info_row(_content_root, "食物", "+%.2f/s" % tf)
			_info_row(_content_root, "矿物", "+%.2f/s" % tm)

func _build_conquest() -> void:
	if _selected_idx < 0:
		_state = State.LIST
		_build_list()
		return
	var sys: Dictionary = GameState.star_systems[_selected_idx]

	var back_btn := Button.new()
	back_btn.text = "← 星系详情"
	back_btn.pressed.connect(func():
		_state = State.DETAIL
		_refresh_content()
	)
	_content_root.add_child(back_btn)

	_h(_content_root, sys["name"] + " — 进攻进行中", 15)

	var power_lbl := Label.new()
	power_lbl.text = "帝国武力: %d" % int(GameState.empire_power)
	power_lbl.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))
	power_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_content_root.add_child(power_lbl)

	_content_root.add_child(HSeparator.new())

	var conquered_count := 0
	for pi in range(sys["planets"].size()):
		var planet: Dictionary = sys["planets"][pi]
		if not planet["inhabited"]:
			continue
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		_content_root.add_child(row)

		var p_lbl := Label.new()
		p_lbl.size_flags_horizontal = SIZE_EXPAND_FILL
		if planet["conquered"]:
			conquered_count += 1
			p_lbl.text = "✓ 星球 %d  [已征服]  能源+%.1f  食物+%.1f  矿物+%.1f /s" % [
				pi + 1, planet["energy_yield"], planet["food_yield"], planet["minerals_yield"]
			]
			p_lbl.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
		else:
			p_lbl.text = "● 星球 %d  [防御值 %d]" % [pi + 1, int(planet["defense"])]
		row.add_child(p_lbl)

		if not planet["conquered"]:
			var can_atk := GameState.empire_power >= planet["defense"]
			var atk_btn := Button.new()
			atk_btn.text = "攻取" if can_atk else "武力不足"
			atk_btn.disabled = not can_atk
			var pidx := pi
			var sidx := _selected_idx
			atk_btn.pressed.connect(func():
				GameState.attack_planet(sidx, pidx)
				_refresh_content()
			)
			row.add_child(atk_btn)

	_content_root.add_child(HSeparator.new())
	var prog_lbl := Label.new()
	prog_lbl.text = "进度: %d / %d 星球已攻取" % [conquered_count, sys["enemy_count"]]
	prog_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_content_root.add_child(prog_lbl)

	if sys["status"] == "conquered":
		_content_root.add_child(HSeparator.new())
		var win_lbl := Label.new()
		win_lbl.text = "★  星系完全征服！"
		win_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
		win_lbl.add_theme_font_size_override("font_size", 15)
		win_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_content_root.add_child(win_lbl)

# ── Signal handlers ───────────────────────────────────────────────────────────

func _update_resources() -> void:
	_energy_lbl.text   = "能源: %s  (+%.1f/s)" % [_fmt(GameState.energy),   GameState.energy_rate]
	_food_lbl.text     = "食物: %s  (+%.1f/s)" % [_fmt(GameState.food),     GameState.food_rate]
	_minerals_lbl.text = "矿物: %s  (+%.1f/s)" % [_fmt(GameState.minerals), GameState.minerals_rate]

# ── Helpers ───────────────────────────────────────────────────────────────────

func _status_str(status: String) -> String:
	match status:
		"unknown":   return "[未知]"
		"active":    return "[进攻中]"
		"conquered": return "[已征服]"
	return "[?]"

func _info_row(parent: Control, label_text: String, value_text: String) -> void:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var lbl := Label.new()
	lbl.text = label_text + ":"
	lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
	lbl.custom_minimum_size.x = 100
	row.add_child(lbl)
	var val := Label.new()
	val.text = value_text
	row.add_child(val)

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
