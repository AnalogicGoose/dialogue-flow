extends Node2D

var controller: DialogueController

func _ready() -> void:
	controller = DialogueController.new()
	controller.conversation = load("res://dev/dialogue_data/test_conversation.tres")
	
	controller.dialogue_started.connect(func(): print("-- dialogue_started --"))
	controller.dialogue_finished.connect(func(): print("-- dialogue_finished --"))
	controller.dialogue_cancelled.connect(func(): print("-- dialogue_cancelled --"))
	controller.speech_changed.connect(_on_speech_changed)
	controller.responses_changed.connect(_on_responses_changed)
	
	controller.start()

func _on_speech_changed(speaker: String, text: String) -> void:
	print("%s: %s" % [speaker, text])

func _on_responses_changed(response_texts: Array) -> void:
	for i in response_texts.size():
		print("%s: %s" % [i, response_texts[i]])
	print("Press a number key to choose a response.")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		var digit = event.keycode - KEY_0
		if digit >= 0 and digit <= 9:
			controller.choose(digit)
