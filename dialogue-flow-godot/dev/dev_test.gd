extends Node2D

@onready var controller: DialogueController = $DialogueController

func _ready() -> void:
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
