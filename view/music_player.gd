class_name MusicPlayer extends Node


const MENU := preload("res://music/Midnight Feathers .Bmp120. main.mp3")
const GAME := preload("res://music/Count Quackula_s Theme.BMP72mscz.mp3")

var _player: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player = AudioStreamPlayer.new()
	_player.bus = "Music"
	add_child(_player)


func play(stream: AudioStream) -> void:
	if _player.stream == stream and _player.playing:
		return
	_player.stream = stream
	_player.play()
