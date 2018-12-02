extends KinematicBody2D

const RUN_SPEED = 8 * 64 # Number tiles the player will run per second and full speed
const SLOPE_SLIDE_STOP = 5
const MIN_JUMP_HEIGHT = 0.8 * 64
const FALL_DURATION = 0.5 # Time in seconds it should take the player to fall 'Global.PLAYER_JUMP_HEIGHT' distance
const WALL_STICK_CHECK = 0.3 # Time in seconds player can move away from wall but still stick to it.
const WALL_CLIMB_HEIGHT = 5.25 * 64
const WALL_HOP_HEIGHT = 3.5 * 64
const WALL_LEAP_HEIGHT = 2.5 * 64
const MAX_VELOCITY = 1200
const WALL_SLIDE_MAX_VELOCITY = 150
const WALL_SLIDE_GRAVITY_MODIFIER = 0.25

var velocity = Vector2()
var is_grounded = false
var move_direction = 0 # Direction player is attempting to move
var facing = 1 # Direction the player is facing
var wall_direction = 0 setget ,_get_wall_direction # Direction of the wall if the player is wall_sliding
var wall_stick_duration = 0 # Current duration player has been moving away from wall

onready var fall_gravity = 2 * Global.PLAYER_JUMP_HEIGHT / pow(FALL_DURATION, 2)
onready var max_jump_velocity = Utility.get_velocity_from_height(Global.PLAYER_JUMP_HEIGHT)
onready var min_jump_velocity = Utility.get_velocity_from_height(MIN_JUMP_HEIGHT)
onready var wall_climb_velocity = Vector2(1200, Utility.get_velocity_from_height(WALL_CLIMB_HEIGHT))
onready var wall_hop_velocity = Vector2(600, Utility.get_velocity_from_height(WALL_HOP_HEIGHT))
onready var wall_leap_velocity = Vector2(1200, Utility.get_velocity_from_height(WALL_LEAP_HEIGHT))

onready var camera = $PlatformerCamera
onready var ground_raycasts = $GroundRaycasts
onready var body = $Body
onready var state_machine = $PlayerStateMachine
onready var wall_slide_wait_timer = $WallSlideWaitTimer
onready var coyote_timer = $CoyoteTimer

func _physics_process(delta):
	# Get input to determine which way to attempt to move
	move_direction = -int(Input.is_action_pressed("move_left")) + int(Input.is_action_pressed("move_right"))
	state_machine.state_physics_process(delta)
	_check_raycasts(ground_raycasts)
	
	var was_grounded = is_grounded
	is_grounded = is_on_floor()
	
	if !is_grounded && was_grounded:
		coyote_timer.start()

func _input(event):
	state_machine.state_input(event)

func _apply_h_movement():
	# Apply linear interpolation to create acceleration and deceleration
	var target_speed = move_direction * RUN_SPEED
	velocity.x = lerp(velocity.x, target_speed, _get_h_weight(target_speed))
	# Determine facing from move_direction
	if move_direction != 0:
		facing = move_direction

# Set which way the player is facing. Can be used to face the opposite of facing during a wall jump.
func set_body_facing(facing = self.facing):
	body.scale.x = facing

# Apply gravity based on whether character is jumping or falling. Slow gravity when falling to allow
# the player more time to align their landing.
func _apply_gravity(delta, max_velocity = MAX_VELOCITY):
	if velocity.y < 0:
		velocity.y += Global.gravity * delta
	else:
		velocity.y += fall_gravity * delta
	
	velocity.y = min(velocity.y, max_velocity)

# Move player with physics
func _apply_movement():
	velocity = move_and_slide(velocity, Global.UP_VEC, SLOPE_SLIDE_STOP)

# Loop through the children of a given node, checking for RayCast2D's and returns
# a boolean based on whether any collision was detected
func _check_raycasts(raycasts):
	var is_colliding = false
	for raycast in raycasts.get_children():
		if raycast is RayCast2D and raycast.is_colliding():
			var collider = raycast.get_collider()
			if !collider is TileMap && collider.get_parent().has_method("interact"):
				collider.get_parent().interact()
			is_colliding = true
	return is_colliding

# Checks conditions to determine what weight to apply to character acceleration / deceleration
func _get_h_weight(target_speed):
	var weight = 0.4 if is_grounded else 0.125
	
	# If player is pressing move towards velocity
	# And player is moving faster than their speed
	# This is meant to provide less deceleration in air while maintaining tight controls
	if move_direction == sign(velocity.x) && abs(velocity.x) > abs(target_speed):
		if !is_grounded:
			weight *= 0.05
	
	return weight

# Checks to see if a player is moving towards a wall and is colliding with the wall
func _check_wall_sliding():
	if move_direction == Global.RIGHT && $WallJumpRaycasts/RightWallRaycast.is_colliding() \
			|| move_direction == Global.LEFT && $WallJumpRaycasts/LeftWallRaycast.is_colliding():
		return true
	else: return false

# Check the wall raycasts to determine which direction a wall is next to the player if any.
func _get_wall_direction():
	if $WallJumpRaycasts/RightWallRaycast.is_colliding():
		wall_direction = Global.RIGHT
	elif $WallJumpRaycasts/LeftWallRaycast.is_colliding():
		wall_direction = Global.LEFT
	else:
		wall_direction = 0
	
	return wall_direction

func _on_HitboxArea_body_entered(body):
	if body is TileMap:
		get_tree().reload_current_scene()
	pass # replace with function body
