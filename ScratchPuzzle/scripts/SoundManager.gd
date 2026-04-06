extends Node

@onready var jump_player = $JumpPlayer
@onready var step_player = $StepPlayer
#@onready var land_player: AudioStreamPlayer = $LandPlayer
@onready var death_player = $DeathPlayer
@onready var button_player = $ButtonPlayer
@onready var won_player = $WonPlayer
#@onready var applause_player = $ApplausePlayer
@onready var music_player: AudioStreamPlayer = $MenuMusicPlayer
@onready var endless_player: AudioStreamPlayer = $EndlessMusicPlayer
@onready var menu_player: AudioStreamPlayer = $MenuMusicPlayer

#var land_sound: AudioStream
var step_sound: AudioStream
var death_sound: AudioStream
var button_sound: AudioStream
var jump_sounds: Array[AudioStream]
var menu_music: AudioStream
var won_music: AudioStream
#var applause_sound: AudioStream
var music_playing := false
var endless_playing := false
#var game_musics: Array[AudioStream] = []
var endless_music: AudioStream

func _ready():
	menu_music = load("res://assets/Sounds/moonlight.mp3")
	if menu_music:
		menu_music.loop = true
	menu_player.volume_db = -10
	step_sound = load("res://assets/Sounds/walk.ogg")
	death_sound = load("res://assets/Sounds/sfx_hurt.ogg") 
	button_sound = load("res://assets/Sounds/bong_001.ogg") 
	#applause_sound = load("res://Assets/Sounds/applause.ogg")
	won_music = load("res://assets/Sounds/winfretless.ogg")
	jump_sounds = [
		#load("res://assets/Sounds/CartoonJump.ogg"),
		load("res://assets/Sounds/jump2.ogg"),
	]
	#game_musics = [
	#load("res://Assets/Sounds/music1.ogg"),
	#load("res://Assets/Sounds/music2.ogg"),
	#load("res://Assets/Sounds/music3.ogg"),
	#]
	endless_music = load("res://assets/Sounds/moonlight.mp3")
	if endless_music:
		endless_music.loop = true
	endless_player.volume_db = -10
	
func _process(_delta):
	var current_scene = get_tree().current_scene
	if current_scene == null:
		return  # ainda carregando ou trocando de cena

	var scene_name = current_scene.name
	if scene_name == "main_menu":
		if (not music_playing or music_player.stream == menu_music) and not endless_playing:
			stop_music()
			#play_random_game_music()
	#
	else:
		if not music_playing or music_player.stream != menu_music:
			if endless_playing:
				play_endless_music()
			else:
				stop_music()
				play_music()
		

#func play_random_game_music():
	#if music_playing:
		#return
#
	#var selected = game_musics[randi() % game_musics.size()]
	#music_player.stream = selected
	#music_player.play()
	#music_playing = true
	
func play_music():
	stop_endless_music()
	
	if music_playing:
		return
	music_player.stream = menu_music
	music_player.play()
	music_playing = true

func play_endless_music():
	stop_music()
		
	if endless_playing:
		return
		
	endless_player.stream = endless_music
	endless_player.play()
	endless_playing = true

func stop_music():
	music_player.stop()
	music_playing = false

func stop_endless_music():
	endless_player.stop()
	endless_playing = false

func play_won():
	won_player.stream = won_music
	won_player.play()
	#applause_player.stream = applause_sound
	#applause_player.play()

func play_button():
	button_player.stream = button_sound
	button_player.play()
	
func play_step():
	step_player.stream = step_sound
	step_player.play()

#func play_land():
	#if land_player and land_sound:
		#land_player.stream = land_sound
		#land_player.play()

func play_death():
	death_player.stream = death_sound
	death_player.play()

func play_jump():
	if jump_sounds.size() == 0:
		return
	var index = randi() % jump_sounds.size()
	jump_player.stream = jump_sounds[index]
	jump_player.play()
	
#func stop_all_sounds():
	#for player in [jump_player, step_player, death_player, won_player, applause_player, music_player, endless_player]:
		#if player.playing:
			#player.stop()
	#music_playing = false
	#endless_playing = false
