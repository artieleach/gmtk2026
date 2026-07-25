class_name SfxPlayer extends Node


const VOICES := 6

const RUN_START := preload("res://sfx/Count Ducula 1 Introduction_Laugh.wav")
const PLAYER_HIT := preload("res://sfx/Count Ducula 3 Jump.wav")
const ENEMY_HIT := preload("res://sfx/Dog Bark 1.wav")
const PLAYER_HURT := preload("res://sfx/Count Ducula 2 Pain.wav")
const ENEMY_DIED := preload("res://sfx/Crow.wav")
const WON := preload("res://sfx/Count Ducula 4 Victory.wav")
const LOST := preload("res://sfx/Falling SFX.wav")
const PICKUP := preload("res://sfx/Correct Stinger.wav")
const LETTER := preload("res://sfx/Flock of Pigeons.wav")

const NARRATION_PATHS := {
	Upgrade.Id.STRENGTH: "res://sfx/narration/strength.wav",
	Upgrade.Id.GRACE: "res://sfx/narration/grace.wav",
	Upgrade.Id.JUMP: "res://sfx/narration/plummet.wav",
	Upgrade.Id.CARVE: "res://sfx/narration/rend.wav",
	Upgrade.Id.RAPPEL: "res://sfx/narration/rappel.wav",
	Upgrade.Id.SUREFOOT: "res://sfx/narration/surefoot.wav",
	Upgrade.Id.AMBUSH: "res://sfx/narration/ambush.wav",
}

var game: Game
var narrate: bool = false

var _narration: Dictionary = {}
var _narrated: Dictionary = {}

var _voices: Array[AudioStreamPlayer] = []
var _next: int = 0
var _player_hp: int = 0


func _ready() -> void:
	for i in VOICES:
		var voice := AudioStreamPlayer.new()
		voice.bus = "SFX"
		add_child(voice)
		_voices.append(voice)

	for id: int in NARRATION_PATHS:
		var path: String = NARRATION_PATHS[id]
		if ResourceLoader.exists(path):
			var stream: AudioStream = load(path)
			if stream != null:
				_narration[id] = stream

	if game == null:
		return
	_player_hp = game.player.hp if game.player != null else 0
	game.run_started.connect(_on_run_started)
	game.actor_attacked.connect(_on_actor_attacked)
	game.actor_died.connect(_on_actor_died)
	game.run_ended.connect(_on_run_ended)
	game.hp_changed.connect(_on_hp_changed)
	game.upgrade_picked.connect(_on_upgrade_picked)
	game.letter_sent.connect(_on_letter_sent)


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


func _on_upgrade_picked(pickup: Pickup, gained: bool) -> void:
	_play(PICKUP)
	if narrate and gained and not _narrated.has(pickup.upgrade_id):
		_narrated[pickup.upgrade_id] = true
		_play(_narration.get(pickup.upgrade_id))


func _on_letter_sent(_letter: Letter, _index: int, _turns_gained: int) -> void:
	_play(LETTER)
