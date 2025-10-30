extends Control

var character_name = ""
var _typewriter_tween
var project_version = ProjectSettings.get_setting("application/config/version")

var sexuality_defs = [
	{ "id": "heterosexual", "name": "Heterosexual", "rom": "Heteromantic", "weight": 100.0, "rom_weight": 100 },
	{ "id": "homosexual", "name": "Homosexual", "rom": "Homoromantic", "weight": 100.0, "rom_weight": 100 },
	{ "id": "bisexual", "name": "Bisexual", "rom": "Biromantic", "weight": 100.0, "rom_weight": 100 },
	{ "id": "pansexual", "name": "Pansexual", "rom": "Panromantic", "weight": 100.0, "rom_weight": 100 },
	{ "id": "omnisexual", "name": "Omnisexual", "rom": "Omniromantic", "weight": 100.0, "rom_weight": 100 },
	{ "id": "demisexual", "name": "Demisexual", "rom": "Demiromantic", "weight": 100.0, "rom_weight": 100 },
	{ "id": "asexual", "name": "Asexual", "rom": "Aromantic", "weight": 100.0, "rom_weight": 100 },
]

var rows = {}

@onready var Output: RichTextLabel = $Content/VBox/Output
@onready var CopyNotifier: Label = $Content/VBox/HBoxContainer/CopyNotifier
@onready var HistoryVBox: VBoxContainer = $Content/VBox/FoldableContainer/ScrollContainer/VBoxContainer
@onready var NoHistoryText: RichTextLabel = $"Content/VBox/FoldableContainer/ScrollContainer/VBoxContainer/No History text"
@onready var VersionText: Label = $Content/VBox/VersionText
@onready var RowsParent: VBoxContainer = $Content/VBox/Weights/ScrollContainer/VBoxContainer

@onready var BiasSlider: Slider = $Content/VBox/Weights/ScrollContainer/VBoxContainer/MatchBiasContainer/BiasSlider
@onready var BiasLabel: Label = $Content/VBox/Weights/ScrollContainer/VBoxContainer/MatchBiasContainer/BiasLabel

# 0..100 probability to force romantic match with selected sexuality
var _match_bias_pct: float = 50.0

func _ready() -> void:
	VersionText.text = "Character Details Toolkit " + str(project_version) + " - Created by Kris Velivia"
	# Ensure bias slider behaves as 0..100%
	BiasSlider.min_value = 0
	BiasSlider.max_value = 100
	BiasSlider.step = 1
	_on_bias_slider_value_changed(BiasSlider.value)
	build_rows()
	
func build_rows() -> void:
	#for c in RowsParent.get_children():
		#c.queue_free()
	#await get_tree().process_frame
	
	#rows.clear()
	for def in sexuality_defs:
		var row = HBoxContainer.new()
		RowsParent.add_child(row)
		
		var sexuality_slider = HSlider.new()
		sexuality_slider.custom_minimum_size = Vector2(300, 30)
		sexuality_slider.step = 5.0
		sexuality_slider.scrollable = false
		sexuality_slider.value = float(def.weight)
		
		var sexuality_label = Label.new()
		
		var rom_slider = HSlider.new()
		rom_slider.custom_minimum_size = Vector2(300, 30)
		rom_slider.step = 5.0
		rom_slider.scrollable = false
		rom_slider.value = float(def.rom_weight)
		
		var rom_label = Label.new()
		
		row.add_child(sexuality_slider)
		row.add_child(sexuality_label)
		row.add_child(rom_slider)
		row.add_child(rom_label)
		
		rows[def.id] = {
			"name": def.name,
			"rom": def.rom,
			"sexuality_slider": sexuality_slider,
			"sexuality_label": sexuality_label,
			"rom_slider": rom_slider,
			"rom_label": rom_label,
		}
		
		_update_row_labels(def.id)
		
		sexuality_slider.value_changed.connect(_on_slider_changed.bind(def.id, true))
		rom_slider.value_changed.connect(_on_slider_changed.bind(def.id, false))

func _on_bias_slider_value_changed(value: float) -> void:
	_match_bias_pct = clampf(value, 0.0, 100.0)
	BiasLabel.text = "Bias: %d%%" % int(_match_bias_pct)
	
func _on_slider_changed(_value: float, id: String, _is_sexuality: bool) -> void:
	_update_row_labels(id)
	
func _update_row_labels(id: String) -> void:
	var e = rows[id]
	
	var sv = float(e.sexuality_slider.value)
	if sv == 0.0:
		e.sexuality_label.text = "%s: Disabled" % e.name
		e.sexuality_label.add_theme_color_override("font_color", Color("919498"))
	else:
		e.sexuality_label.text = "%s: %s%%" % [e.name, str(sv)]
		e.sexuality_label.add_theme_color_override("font_color", Color("cdcfd2"))
		
	var rv = float(e.rom_slider.value)
	if rv == 0.0:
		e.rom_label.text = "%s: Disabled" % e.rom
		e.rom_label.add_theme_color_override("font_color", Color("919498"))
	else:
		e.rom_label.text = "%s: %s%%" % [e.rom, str(rv)]
		e.rom_label.add_theme_color_override("font_color", Color("cdcfd2"))

# Godot doesn't have a pick_random_weighted() function for some reason, grr.
func pick_weighted(list:Array, weights:Array) -> Variant:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var total = 0
	for w in weights:
		total += float(w)
	var r = rng.randf() * total
	var sum = 0
	for i in range(weights.size()):
		sum += float(weights[i])
		if r < sum:
			return list[i]
	return list[list.size()-1]
	
func _on_name_text_changed(new_text: String) -> void:
	character_name = new_text

func _on_randomize_button_pressed() -> void:
	Output.clear()
	
	var sexuality_ids: Array = []
	var sexuality_weights: Array = []
	var rom_ids: Array = []
	var rom_weights: Array = []
	
	for def in sexuality_defs:
		var id = def.id
		var e = rows[id]
		sexuality_ids.append(id)
		sexuality_weights.append(float(e.sexuality_slider.value))
		rom_ids.append(id)
		rom_weights.append(float(e.rom_slider.value))
		
	var sexuality_total = 0.0
	for w in sexuality_weights:
		sexuality_total += float(w)
	if sexuality_total <= 0.0:
		Output.push_color(Color("ff6666"))
		Output.add_text("Enable at least one sexuality in choices.")
		if CopyNotifier.visible:
			CopyNotifier.visible = false
		return

	# Pick sexuality first
	var sex_pick_id: String = pick_weighted(sexuality_ids, sexuality_weights)
	var sex_text: String = rows[sex_pick_id].name

	# Decide whether to force a romantic match
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var force_match := rng.randf() < (_match_bias_pct / 100.0)

	var rom_text := ""
	if force_match:
		rom_text = rows[sex_pick_id].rom
	else:
		# Use user-set romantic weights (if any are enabled)
		var rom_total := 0.0
		for w in rom_weights:
			rom_total += float(w)
		if rom_total > 0.0:
			var rom_pick_id: String = pick_weighted(rom_ids, rom_weights)
			rom_text = rows[rom_pick_id].rom
		# else leave rom_text empty (only sexuality shown)

	var line: String = ("%s." % sex_text) if rom_text == "" else ("%s and %s." % [sex_text, rom_text])
	
	if character_name == "":
		Output.push_color(Color("cdcfd2"))
		Output.add_text("Your character is ")
		Output.push_bold()
		Output.add_text(line)
		Output.pop()
	else:
		Output.push_color(Color("cdcfd2"))
		Output.add_text(character_name + " is " + line)
		
	Output.visible_ratio = 0.0
	
	if is_instance_valid(_typewriter_tween):
		_typewriter_tween.kill()
	
	_typewriter_tween = create_tween()
	_typewriter_tween.tween_property(Output, "visible_ratio", 1.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	if CopyNotifier.visible:
		CopyNotifier.visible = false
		
	_create_history_item(line)

func _on_clear_button_pressed() -> void:
	Output.clear()
	Output.push_color(Color("919498"))
	Output.add_text("Press randomize to generate.")
	character_name = ""
	
	if CopyNotifier.visible:
		CopyNotifier.visible = false

func _on_copy_button_pressed() -> void:
	DisplayServer.clipboard_set(Output.text)
	CopyNotifier.visible = true

func _create_history_item(text: String) -> void:
	NoHistoryText.visible = false

	var HistoryLabel = RichTextLabel.new()
	var Stylebox = StyleBoxFlat.new()
	Stylebox.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	HistoryLabel.add_theme_stylebox_override("normal", Stylebox)
	HistoryLabel.custom_minimum_size.x = 500
	HistoryLabel.custom_minimum_size.y = 40
	HistoryLabel.selection_enabled = true
	
	HistoryLabel.text = "1. " + text
	HistoryVBox.add_child(HistoryLabel)
	HistoryVBox.move_child(HistoryLabel, 0)
	
	HistoryLabel.modulate = Color(1, 1, 1, 0)
	create_tween().tween_property(HistoryLabel, "modulate", Color(1, 1, 1, 1), 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	var items = []
	for child in HistoryVBox.get_children():
		if child == NoHistoryText:
			continue
		items.append(child)
		
	while items.size() > 5:
		var last = items.pop_back()
		HistoryVBox.remove_child(last)
		last.queue_free()
		
	for i in range(items.size()):
		var label = items[i]
		var parts = label.text.split(". ")
		var body = parts[1] if parts.size() > 1 else label.text
		label.text = str(i+1) + ". " + body
	
	for i in range(1, HistoryVBox.get_child_count()):
		var label = HistoryVBox.get_child(i)
		if label == NoHistoryText:
			continue
		var parts = label.text.split(". ")
		var body = parts[1] if parts.size() > 1 else label.text
		label.text = str(i+1) + ". " + body


func _on_history_clear_button_pressed() -> void:
	for child in HistoryVBox.get_children():
		if child == NoHistoryText:
			continue
		HistoryVBox.remove_child(child)
		child.queue_free()
	NoHistoryText.visible = true
	
	NoHistoryText.modulate = Color(1, 1, 1, 0)
	create_tween().tween_property(NoHistoryText, "modulate", Color(1, 1, 1, 1), 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
