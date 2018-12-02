extends Camera2D

const SHIFT_TRANS = Tween.TRANS_CIRC
const SHIFT_EASE = Tween.EASE_OUT
const SHIFT_DURATION = 0.5
const PANIC_TRANS = Tween.TRANS_CUBIC
const PANIC_EASE = Tween.EASE_OUT
const PANIC_DURATION = 0.4
const LOOK_AHEAD_FACTOR = 0.2
const STEADY_TOP_MARGIN = 0.8
const PANIC_SMOOTH_SPEED = 7
const PANIC_LINE = 0.2
const PANIC_Y_OFFSET = 5 * 64

var facing = 0
var is_steady = false setget _set_is_steady
var is_panicing = false setget _set_is_panicing
var default_drag_margin_top

onready var default_smoothing_speed = smoothing_speed
onready var previous_position = get_camera_position()
onready var parent = get_parent()
onready var shift_tween = $ShiftTween

func _ready():
	default_drag_margin_top = drag_margin_top

func _process(delta):
	_check_facing()
	_check_panicing()
	
	previous_position = get_camera_position()

# Check to see if the camera has moved in the opposite direction
# If it has then shift it's position so that it's in front of the player
func _check_facing():
	var new_facing = sign((get_camera_position() - previous_position).x)
	if new_facing != 0 && new_facing != facing:
		facing = new_facing
		
		var target_offset = get_viewport_rect().size.x * LOOK_AHEAD_FACTOR * facing
		
		shift_tween.interpolate_property(self, "position:x", position.x, target_offset, SHIFT_DURATION, SHIFT_TRANS, SHIFT_EASE)
		shift_tween.start()

# Checks to see if the parent is below the panic margin, if so then start panicing.
# If already panicing then instead check to see if we should return to normal.
func _check_panicing():
	if !is_panicing && parent.global_position.y > (get_camera_screen_center() + get_viewport_rect().size * PANIC_LINE).y:
		_set_is_panicing(true)
	elif is_panicing:
		if parent.state_machine.state != parent.state_machine.FALLING:
			_set_is_panicing(false)

# If "is_steady" is changed outside of this script, then this method will
# trigger and adjust the top margin. This is meant to minimize camera movement when
# The player is jumping.
func _set_is_steady(value):
	if value:
		drag_margin_top = STEADY_TOP_MARGIN
	else:
		drag_margin_top = default_drag_margin_top

# If the player character falls too far below the camera, then the camera will increase it's smoothing speed
# and offset it's position to allow the player more visibility for landing
func _set_is_panicing(value):
	if is_panicing != value:
		if value:
			smoothing_speed = PANIC_SMOOTH_SPEED
			shift_tween.interpolate_property(self, "position:y", position.y, PANIC_Y_OFFSET, PANIC_DURATION, PANIC_TRANS, PANIC_EASE)
			shift_tween.start()
		else:
			smoothing_speed = default_smoothing_speed
			shift_tween.interpolate_property(self, "position:y", position.y, 0, PANIC_DURATION, PANIC_TRANS, PANIC_EASE)
			shift_tween.start()
	
	is_panicing = value