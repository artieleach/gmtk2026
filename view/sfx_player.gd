class_name SfxPlayer extends Node


const VOICES := 6

const RUN_START := preload("res://sfx/Count Ducula 1 Introduction_Laugh.wav")
const PLAYER_HIT := preload("res://sfx/Count Ducula 3 Jump.wav")
const ENEMY_HIT := preload("res://sfx/Dog Bark 1.wav")
const PLAYER_HURT := preload("res://sfx/Count Ducula 2 Pain.wav")
const ENEMY_DIED := preload("res://sfx/Crow.wav")
const WON := preload("res://sfx/Count Ducula 4 Victory.wav")
const LOST := preload("res://sfx/Falling SFX.wav")
const ALTAR := preload("res://sfx/Correct Stinger.wav")

var game: Game

var _voices: Array[AudioStreamPlayer] = []
var _next: int = 0
var _player_hp: int = 0


func _ready() -> void:
	for i in VOICES:
		var voice := AudioStreamPlayer.new()
		voice.bus = "SFX"
		add_child(voice)
		_voices.append(voice)

	if game == null:
		return
	_player_hp = game.player.hp if game.player != null else 0
	game.run_started.connect(_on_run_started)
	game.actor_attacked.connect(_on_actor_attacked)
	game.actor_died.connect(_on_actor_died)
	game.run_ended.connect(_on_run_ended)
	game.hp_changed.connect(_on_hp_changed)
	game.altar_opened.connect(_on_altar_opened)


func _play(stream: AudioStream) -> void:
	if stream == null:
		return
	var voice := _voices[_next]
	_next = (_next + 1) % VOICES
	voice.stream = stream
	voice.play()


func _on_run_started() -> void:
	_player_hp = game.player.hp if game.player != null else 0
	_play(RUN_START)


func _on_actor_attacked(attacker: Actor, _target: Actor) -> void:
	_play(PLAYER_HIT if attacker.is_player() else ENEMY_HIT)


func _on_actor_died(_actor: Actor) -> void:
	_play(ENEMY_DIED)


func _on_run_ended(won: bool) -> void:
	_play(WON if won else LOST)


func _on_hp_changed(actor: Actor, hp: int) -> void:
	if not actor.is_player():
		return
	if hp < _player_hp:
		_play(PLAYER_HURT)
	_player_hp = hp


func _on_altar_opened(_altar: Altar) -> void:
	_play(ALTAR)
