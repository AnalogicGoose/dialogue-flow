extends Control

@export var controller: DialogueController

@onready var speaker_label: Label = $Panel/MarginContainer/VBoxContainer/SpeakerLabel
@onready var text_label: Label = $Panel/MarginContainer/VBoxContainer/TextLabel
@onready var responses_container: VBoxContainer = $Panel/MarginContainer/VBoxContainer/ResponsesContainer

func _ready() -> void:
	hide()
	if controller == null:
		push_warning("DialogueUI: no controller assigned")
		return
	controller.dialogue_started.connect(_on_dialogue_started)
	controller.dialogue_finished.connect(_on_dialogue_ended)
	controller.dialogue_cancelled.connect(_on_dialogue_ended)
	controller.speech_changed.connect(_on_speech_changed)
	controller.responses_changed.connect(_on_responses_changed)

func _on_dialogue_started() -> void:
	show()

func _on_dialogue_ended() -> void:
	hide()

func _on_speech_changed(speaker: String, text: String) -> void:
	speaker_label.text = speaker
	text_label.text = text
	_clear_responses()

func _on_responses_changed(response_texts: Array) -> void:
	_clear_responses()
	for i in response_texts.size():
		var button := Button.new()
		button.text = response_texts[i]
		button.pressed.connect(controller.choose.bind(i))
		responses_container.add_child(button)

func _clear_responses() -> void:
	for child in responses_container.get_children():
		child.queue_free()
