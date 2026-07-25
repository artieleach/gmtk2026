class_name SfxPlayer extends Node


const VOICES := 6

const RUN_START := preload("res://sfx/Count Ducula 1 Introduction_Laugh.wav")
const PLAYER_HIT := preload("res://sfx/Flap 1 Hit.wav")
const ENEMY_HIT := preload("res://sfx/Dog Bark 1.wav")
const PLAYER_HURT := preload("res://sfx/Count Ducula 2 Pain.wav")
const ENEMY_DIED := preload("res://sfx/Crow.wav")
const WON := preload("res://sfx/Count Ducula 4 Victory.wav")
const LOST := preload("res://sfx/Game Over.wav")
const DROP := preload("res://sfx/Flap Jump.wav")
const INTRO := preload("res://sfx/intro cin.mp3")

const ATTACK_SFX := {
	Species.Id.WINDOW_SWIPER: preload("res://sfx/Swiper Attack.wav"),
	Species.Id.CRAWLER: preload("res://sfx/Crawler Attack.wav"),
	Species.Id.GARGOYLE: preload("res://sfx/Gargoyle Attack.wav"),
	Species.Id.SHADE_LURKER: preload("res://sfx/Shade Attack.wav"),
	Species.Id.SWARMLING: preload("res://sfx/Hornet Attack.wav"),
	Species.Id.LANTERN_GUARD: [
		preload("res://sfx/Lantern Attack 1.wav"),
		preload("res://sfx/Lantern Attack 2.wav"),
	],
}

const BURN_SFX := [
	preload("res://sfx/Fire 1.wav"),
	preload("res://sfx/Fire 2.wav"),
	preload("res://sfx/Fire 3.wav"),
]

const BREAK_SFX := [
	preload("res://sfx/Brick 1.wav"),
	preload("res://sfx/Brick 2.wav"),
]
const STEAL_SFX := preload("res://sfx/Brick Steal.wav")
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
var _speech: AudioStreamPlayer
var _player_hp: int = 0
var _attack_alt: int = 0
var _burn_next: int = 0
var _break_next: int = 0
var _struck: bool = false


func _ready() -> void:
	for i in VOICES:
		var voice := AudioStreamPlayer.new()
		voice.bus = "SFX"
		add_child(voice)
		_voices.append(voice)

	_speech = AudioStreamPlayer.new()
	_speech.bus = "SFX"
	add_child(_speech)

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
	game.actor_moved.connect(_on_actor_moved)
	game.actor_attacked.connect(_on_actor_attacked)
	game.actor_died.connect(_on_actor_died)
	game.barrier_broken.connect(_on_barrier_broken)
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


func _play_cycled(streams: Array, cursor: int) -> int:
	_play(streams[cursor % streams.size()])
	return cursor + 1


func _say(stream: AudioStream) -> void:
	if stream == null:
		return
	_speech.stream = stream
	_speech.play()


func _on_run_started() -> void:
	_player_hp = game.player.hp if game.player != null else 0
	_struck = false
	if narrate:
		_say(INTRO)
	else:
		_play(RUN_START)


func _on_actor_moved(actor: Actor, from: Vector2i, to: Vector2i) -> void:
	if actor.is_player() and absi(to.y - from.y) > 1:
		_play(DROP)


func _on_actor_attacked(attacker: Actor, target: Actor) -> void:
	if target.is_player():
		_struck = true
	if attacker.is_player():
		_play(PLAYER_HIT)
		return
	var cue: Variant = ATTACK_SFX.get(attacker.species.id if attacker.species != null else -1)
	if cue is Array:
		_attack_alt = _play_cycled(cue, _attack_alt)
	else:
		_play(cue if cue != null else ENEMY_HIT)


func _on_actor_died(_actor: Actor) -> void:
	_play(ENEMY_DIED)


func _on_run_ended(won: bool) -> void:
	_play(WON if won else LOST)


func _on_hp_changed(actor: Actor, hp: int) -> void:
	if not actor.is_player():
		return
	if hp < _player_hp:
		if not _struck and _burning(actor):
			_burn_next = _play_cycled(BURN_SFX, _burn_next)
		else:
			_play(PLAYER_HURT)
	_struck = false
	_player_hp = hp


func _burning(actor: Actor) -> bool:
	return game.light != null and game.light.state_at(actor.pos) == LightField.State.LIT


func _on_barrier_broken(_pos: Vector2i, by_player: bool) -> void:
	if by_player:
		_break_next = _play_cycled(BREAK_SFX, _break_next)
	else:
		_play(STEAL_SFX)


func _on_upgrade_picked(pickup: Pickup, gained: bool) -> void:
	_play(PICKUP)
	if narrate and gained and not _narrated.has(pickup.upgrade_id):
		_narrated[pickup.upgrade_id] = true
		_say(_narration.get(pickup.upgrade_id))


func _on_letter_sent(_letter: Letter, _index: int, _turns_gained: int) -> void:
	_play(LETTER)
