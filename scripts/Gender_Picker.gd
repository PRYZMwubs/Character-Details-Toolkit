extends Control

var character_name = ""
var _typewriter_tween
var project_version = ProjectSettings.get_setting("application/config/version")

var gender_defs = [
	{ "id": "male", "name": "Male", "pronouns": "He/Him", "weights": 100, "pronoun_weights": 100 },
	{ "id": "female", "name": "Female", "pronouns": "She/Her", "weights": 100, "pronoun_weights": 100 },
	{ "id": "non-binary", "name": "Non-binary", "pronouns": "They/Them", "weights": 100, "pronoun_weights": 100 },
]

var rows = {}

@onready var Output: RichTextLabel = $Content/VBox/Output
@onready var CopyNotifier: Label = $Content/VBox/HBoxContainer/CopyNotifier
@onready var VersionText: Label = $Content/VBox/VersionText
@onready var RowsParent: VBoxContainer = $Content/VBox/Weights/ScrollContainer/VBoxContainer
@onready var BiasLabel: Label = $Content/VBox/Weights/ScrollContainer/VBoxContainer/MatchBiasContainer/BiasLabel

@onready var HistoryVBox: VBoxContainer = $Content/VBox/FoldableContainer/ScrollContainer/VBoxContainer
@onready var NoHistoryText: RichTextLabel = $"Content/VBox/FoldableContainer/ScrollContainer/VBoxContainer/No History text"

var _match_bias_pct: float = 50.0

func _ready() -> void:
	VersionText.text = "Character Details Toolkit " + str(project_version) + " - Created by Kris Velivia"
	build_rows()

func build_rows() -> void:
	for def in gender_defs:
		var row = HBoxContainer.new()
		RowsParent.add_child(row)
		
		var gender_slider = HSlider.new()
		gender_slider.custom_minimum_size = Vector2(300, 30)
		gender_slider.step = 5.0
		gender_slider.scrollable = false
		gender_slider.value = float(def.weights)
		
		var gender_label = Label.new()
		
		var pronoun_slider = HSlider.new()
		pronoun_slider.custom_minimum_size = Vector2(300, 30)
		pronoun_slider.step = 5.0
		pronoun_slider.scrollable = false
		pronoun_slider.value = float(def.pronoun_weights)
		
		var pronoun_label = Label.new()
		
		row.add_child(gender_slider)
		row.add_child(gender_label)
		row.add_child(pronoun_slider)
		row.add_child(pronoun_label)
		
		rows[def.id] = {
			"name": def.name,
			"pronoun": def.pronouns,
			"gender_slider": gender_slider,
			"gender_label": gender_label,
			"pronoun_slider": pronoun_slider,
			"pronoun_label": pronoun_label,
		}
		
		_update_row_labels(def.id)
		
		gender_slider.value_changed.connect(_on_slider_changed.bind(def.id, true))
		pronoun_slider.value_changed.connect(_on_slider_changed.bind(def.id, false))		

func _update_row_labels(id: String) -> void:
	var e = rows[id]
	
	var sv = float(e.gender_slider.value)
	if sv == 0.0:
		e.gender_label.text = "%s: Disabled" % e.name
		e.gender_label.add_theme_color_override("font_color", Color("919498"))
	else:
		e.gender_label.text = "%s: %s%%" % [e.name, str(sv)]
		e.gender_label.add_theme_color_override("font_color", Color("cdcfd2"))
		
	var rv = float(e.pronoun_slider.value)
	if rv == 0.0:
		e.pronoun_label.text = "%s: Disabled" % e.pronoun
		e.pronoun_label.add_theme_color_override("font_color", Color("919498"))
	else:
		e.pronoun_label.text = "%s: %s%%" % [e.pronoun, str(rv)]
		e.pronoun_label.add_theme_color_override("font_color", Color("cdcfd2"))		
	
func _on_slider_changed(_value: float, id: String, _is_sexuality: bool) -> void:
	_update_row_labels(id)
	
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

	var gender_ids: Array = []
	var gender_weights: Array = []
	var pronoun_ids: Array = []
	var pronoun_weights: Array = []

	for def in gender_defs:
		var id = def.id
		var e = rows[id]
		gender_ids.append(id)
		gender_weights.append(float(e.gender_slider.value))
		pronoun_ids.append(id)
		pronoun_weights.append(float(e.pronoun_slider.value))

	var gender_total = 0.0
	for w in gender_weights:
		gender_total += float(w)
	if gender_total <= 0.0:
		Output.push_color(Color("ff6666"))
		Output.add_text("Enable at least one gender in choices.")
		if CopyNotifier.visible:
			CopyNotifier.visible = false
		return

	var gen_pick_id: String = pick_weighted(gender_ids, gender_weights)
	var gen_text: String = rows[gen_pick_id].name

	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var force_match := rng.randf() < (_match_bias_pct / 100.0)
	
	var pronoun_text := ""
	if force_match:
		pronoun_text = rows[gen_pick_id].pronoun
	else:
		# Use user-set romantic weights (if any are enabled)
		var pronoun_total := 0.0
		for w in pronoun_weights:
			pronoun_total += float(w)
		if pronoun_total > 0.0:
			var pronoun_pick_id: String = pick_weighted(pronoun_ids, pronoun_weights)
			pronoun_text = rows[pronoun_pick_id].pronoun

	var line: String = ("%s." % gen_text) if pronoun_text == "" else ("%s and %s." % [gen_text, pronoun_text])
	
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

func _on_bias_slider_value_changed(value: float) -> void:
	_match_bias_pct = clampf(value, 0.0, 100.0)
	BiasLabel.text = "Bias: %d%%" % int(_match_bias_pct)

func _on_clear_button_pressed() -> void:
	Output.clear()
	Output.push_color(Color("919498"))
	Output.add_text("Press randomize to generate.")
	character_name = ""
	
	if CopyNotifier.visible:
		CopyNotifier.visible = false
		
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

func _on_copy_button_pressed() -> void:
	DisplayServer.clipboard_set(Output.text)
	CopyNotifier.visible = true

func _on_history_clear_button_pressed() -> void:
	for child in HistoryVBox.get_children():
		if child == NoHistoryText:
			continue
		HistoryVBox.remove_child(child)
		child.queue_free()
	NoHistoryText.visible = true
	
	NoHistoryText.modulate = Color(1, 1, 1, 0)
	create_tween().tween_property(NoHistoryText, "modulate", Color(1, 1, 1, 1), 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
