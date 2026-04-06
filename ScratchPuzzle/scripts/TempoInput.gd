extends SpinBox

var _debounce_timer: Timer

func _ready():
	step = 0.1
	custom_arrow_step = 0.1
	get_line_edit().focus_entered.connect(func(): get_line_edit().select_all())
	get_line_edit().text_changed.connect(_on_text_changed)
	_debounce_timer = Timer.new()
	_debounce_timer.one_shot = true
	_debounce_timer.wait_time = 0.5
	_debounce_timer.timeout.connect(func(): apply())
	add_child(_debounce_timer)

func _on_text_changed(_new_text: String) -> void:
	_debounce_timer.start()
