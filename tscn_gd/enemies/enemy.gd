class_name Enemy
extends CharacterBody2D

enum Direction { # 枚举纹理方向
	LEFT = -1,
	RIGHT = +1,
}
@export var direction := Direction.LEFT: # 初始化方向值并到处该变量
	set(v): # 当direction发生变化时触发
		direction = v # 修改direction状态
		if not is_node_ready(): # 等待graphics初始化后再运行
			await ready
		graphics.scale.x = -direction # 使其左右翻转
@export var max_speed: float = 180 # 最大速度
@export var acceleration: float = 2000 # 加速度

#加速度
var default_gravity := ProjectSettings.get("physics/2d/default_gravity") as float 


@onready var graphics: Node2D = $Graphics
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var state_machine: StateMachine = $StateMachine


func move(speed: float, delta: float) -> void:
	velocity.x = move_toward(velocity.x, speed * direction, acceleration * delta)
	velocity.y += default_gravity * delta
	
	move_and_slide()
