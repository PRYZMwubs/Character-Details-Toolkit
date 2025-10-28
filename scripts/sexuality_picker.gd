extends Control

var character_name = ""
var _typewriter_tween
var project_version = ProjectSettings.get_setting("application/config/version")

var sexuality_list = [
"Heterosexual",
"Homosexual",
"Bisexual",
"Pansexual",
"Asexual",
"Omnisexual",
]

var sexuality_weights = [
"100", # Heterosexual
"100", # Homosexual
"100", # Bisexual
"100", # Pansexual
"100", # Asexual
"100", # Omnisexual
]

@onready var Output = $Content/VBox/Output
@onready var CopyNotifier = $Content/VBox/HBoxContainer/CopyNotifier

# Het probability
@onready var HetSlider = $"Content/VBox/Weights/ScrollContainer/VBoxContainer/Heterosexual Container/HetSlider"
@onready var HetLabel = $"Content/VBox/Weights/ScrollContainer/VBoxContainer/Heterosexual Container/HetLabel"

# Homo probability
@onready var HomoSlider = $Content/VBox/Weights/ScrollContainer/VBoxContainer/HomosexualContainer/HomoSlider
@onready var HomoLabel = $Content/VBox/Weights/ScrollContainer/VBoxContainer/HomosexualContainer/HomoLabel

# Bi probability
@onready var BiSlider = $Content/VBox/Weights/ScrollContainer/VBoxContainer/Bisexual/BiSlider
@onready var BiLabel = $Content/VBox/Weights/ScrollContainer/VBoxContainer/Bisexual/BiLabel

# Pan probability
@onready var PanSlider = $Content/VBox/Weights/ScrollContainer/VBoxContainer/PansexualContainer/PanSlider
@onready var PanLabel = $Content/VBox/Weights/ScrollContainer/VBoxContainer/PansexualContainer/PanLabel

# Omni probability
@onready var OmniSlider = $Content/VBox/Weights/ScrollContainer/VBoxContainer/OmnisexualContainer/OmniSlider
@onready var OmniLabel = $Content/VBox/Weights/ScrollContainer/VBoxContainer/OmnisexualContainer/OmniLabel

# Act probability
@onready var AceSlider = $Content/VBox/Weights/ScrollContainer/VBoxContainer/AceContainer/AceSlider
@onready var AceLabel = $Content/VBox/Weights/ScrollContainer/VBoxContainer/AceContainer/AceLabel

@onready var HistoryVBox = $Content/VBox/FoldableContainer/ScrollContainer/VBoxContainer

@onready var NoHistoryText = $"Content/VBox/FoldableContainer/ScrollContainer/VBoxContainer/No History text"

@onready var VersionText = $Content/VBox/VersionText

func _ready() -> void:
	VersionText.text = "Character Details Toolkit " + str(project_version) + " - Created by Kris Velivia"

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
	
	var total = 0.0
	for w in sexuality_weights:
		total += float(w)
	if total <= 0.0:
		Output.push_color(Color("ff6666"))
		Output.add_text("Enable at least one sexuality in probability.")
		if CopyNotifier.visible:
			CopyNotifier.visible = false
		return			
	
	var final_pick = pick_weighted(sexuality_list, sexuality_weights)
	
	if character_name == "":
		Output.push_color(Color("cdcfd2"))
		Output.add_text("Your character is ")
		Output.push_bold()
		Output.add_text(final_pick)
		Output.pop()
		Output.add_text(".")
	else:
		Output.push_color(Color("cdcfd2"))
		Output.add_text(character_name + " is " + final_pick + ".")
		
	Output.visible_ratio = 0.0
	
	if is_instance_valid(_typewriter_tween):
		_typewriter_tween.kill()
	
	_typewriter_tween = create_tween()
	_typewriter_tween.tween_property(Output, "visible_ratio", 1.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	if CopyNotifier.visible:
		CopyNotifier.visible = false
		
	_create_history_item(final_pick)

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

func _on_het_slider_value_changed(value: float) -> void:
	if value == 0.0:
		HetLabel.text = "Heterosexual: Disabled"
		HetLabel.add_theme_color_override("font_color", Color("919498"))
	else:
		HetLabel.text = "Heterosexual: " + str(value) + "%"
		HetLabel.add_theme_color_override("font_color", Color("cdcfd2"))
	sexuality_weights.set(0, str(value))

func _on_homo_slider_value_changed(value: float) -> void:
	if value == 0.0:
		HomoLabel.text = "Homosexual: Disabled"
		HomoLabel.add_theme_color_override("font_color", Color("919498"))
	else:
		HomoLabel.text = "Homosexual: " + str(value) + "%"
		HomoLabel.add_theme_color_override("font_color", Color("cdcfd2"))
	sexuality_weights.set(1, str(value))
	
func _on_bi_slider_value_changed(value: float) -> void:
	if value == 0.0:
		BiLabel.text = "Bisexual: Disabled"
		BiLabel.add_theme_color_override("font_color", Color("919498"))
	else:
		BiLabel.text = "Bisexual: " + str(value) + "%"
		BiLabel.add_theme_color_override("font_color", Color("cdcfd2"))
	sexuality_weights.set(2, str(value))

func _on_pan_slider_value_changed(value: float) -> void:
	if value == 0.0:
		PanLabel.text = "Pansexual: Disabled"
		PanLabel.add_theme_color_override("font_color", Color("919498"))
	else:
		PanLabel.text = "Pansexual: " + str(value) + "%"
		PanLabel.add_theme_color_override("font_color", Color("cdcfd2"))
	sexuality_weights.set(3, str(value))
	
func _on_ace_slider_value_changed(value: float) -> void:
	if value == 0.0:
		AceLabel.text = "Asexual: Disabled"
		AceLabel.add_theme_color_override("font_color", Color("919498"))
	else:
		AceLabel.text = "Asexual: " + str(value) + "%"
		AceLabel.add_theme_color_override("font_color", Color("cdcfd2"))
	sexuality_weights.set(4, str(value))

func _on_omni_slider_value_changed(value: float) -> void:
	if value == 0.0:
		OmniLabel.text = "Omnisexual: Disabled"
		OmniLabel.add_theme_color_override("font_color", Color("919498"))
	else:
		OmniLabel.text = "Omnisexual: " + str(value) + "%"
		OmniLabel.add_theme_color_override("font_color", Color("cdcfd2"))
	sexuality_weights.set(5, str(value))

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
