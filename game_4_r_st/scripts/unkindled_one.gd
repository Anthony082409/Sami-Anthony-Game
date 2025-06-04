extends CharacterBody2D

@onready var animated_sprite = $AnimatedSprite2D

const SPEED = 300.0
const JUMP_VELOCITY = -450.0
const GRAVITY = 1200.0
const MAX_FALL_SPEED = 900.0
const COYOTE_TIME = 0.1
const JUMP_BUFFER_TIME = 0.1
const DASH_SPEED = 800.0
const DASH_TIME = 0.15
const DASH_COOLDOWN = 0.4

# Wall climbing
const WALL_SLIDE_SPEED = 100.0
const WALL_JUMP_VELOCITY = Vector2(350, -450)

# Attack combo
const COMBO_RESET_TIME = 0.5

var jump_buffer_timer: float = 0.0
var coyote_timer: float = 0.0
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var facing_direction: int = 1

# Wall
var is_touching_wall: bool = false
var wall_dir: int = 0

# Attack
var combo_step: int = 0
var combo_timer: float = 0.0
var is_attacking: bool = false


func _physics_process(delta: float) -> void:
	handle_timers(delta)
	var input_vector = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	
	if input_vector != 0:
		facing_direction = sign(input_vector)
	
	# Wall detection
	is_touching_wall = false
	wall_dir = 0

	if not is_on_floor():
		if is_on_wall():
			var collision = get_last_slide_collision()
			if collision:
				wall_dir = sign(collision.normal.x)
				is_touching_wall = true

	# Horizontal movement (disabled while dashing)
	if not is_dashing:
		velocity.x = input_vector * SPEED

	# Gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta
		velocity.y = min(velocity.y, MAX_FALL_SPEED)
	else:
		coyote_timer = COYOTE_TIME
		if Input.is_action_just_pressed("jump"):
			jump_buffer_timer = JUMP_BUFFER_TIME

	# Wall slide
	if is_touching_wall and velocity.y > 0:
		velocity.y = min(velocity.y, WALL_SLIDE_SPEED)

	# Jumping (normal and wall jump)
	if jump_buffer_timer > 0 and coyote_timer > 0:
		velocity.y = JUMP_VELOCITY
		jump_buffer_timer = 0
		coyote_timer = 0
	elif Input.is_action_just_pressed("jump") and is_touching_wall:
		velocity = Vector2(-wall_dir * WALL_JUMP_VELOCITY.x, WALL_JUMP_VELOCITY.y)
		coyote_timer = 0
		jump_buffer_timer = 0

	# Variable jump height
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= 0.5

	# Dash input
	if Input.is_action_just_pressed("dash") and not is_dashing and dash_cooldown_timer <= 0:
		is_dashing = true
		dash_timer = DASH_TIME
		dash_cooldown_timer = DASH_COOLDOWN
		velocity = Vector2(facing_direction * DASH_SPEED, 0)

	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false

	# Attack combo timer and input
	if combo_timer > 0:
		combo_timer -= delta
	else:
		combo_step = 0

	if Input.is_action_just_pressed("attack") and not is_attacking:
		attack()

	move_and_slide()
	handle_movement_animation(facing_direction)

# In the function definition
func handle_movement_animation(dir):
	if is_on_floor():
		if !velocity:
			animated_sprite.play("idle")
		if velocity:
			animated_sprite.play("run")
			toggle_flip_sprite(dir)
	elif !is_on_floor():
		animated_sprite.play("fall")

# Flip sprite based on direction
func toggle_flip_sprite(dir):
	if dir == 1:
		animated_sprite.flip_h = false
	if dir == -1:
		animated_sprite.flip_h = true


func handle_timers(delta: float) -> void:
	if jump_buffer_timer > 0:
		jump_buffer_timer -= delta
	if coyote_timer > 0:
		coyote_timer -= delta
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta


func attack():
	is_attacking = true
	combo_step += 1
	combo_timer = COMBO_RESET_TIME
	
	# Placeholder for attack logic (animations, hit detection, etc.)
	print("Attack step ", combo_step)
	
	await get_tree().create_timer(0.2).timeout
	is_attacking = false
