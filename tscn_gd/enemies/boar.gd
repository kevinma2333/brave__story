extends Enemy

enum State {
	IDLE,
	WALK,
	RUN,
}

@onready var wall_checker: RayCast2D = $Graphics/WallChecker
@onready var player_checker: RayCast2D = $Graphics/PlayerChecker
@onready var floor_checker: RayCast2D = $Graphics/FloorChecker
@onready var calm_down_timer: Timer = $CalmDownTimer

func can_see_player() -> bool: ## 只对玩家进行碰撞检测
	if not player_checker.is_colliding(): # 啥也没看到
		return false
	return player_checker.get_collider() is Player # 获取碰撞物是不是玩家

func tick_physics(state: State, delta: float) -> void:
	match state:
		State.IDLE:
			move(0.0, delta)
		
		State.WALK:
			move(max_speed / 3, delta)
		
		State.RUN:
			if wall_checker.is_colliding() or not floor_checker.is_colliding():
				direction *= -1
			move(max_speed, delta)
			if can_see_player():
				calm_down_timer.start()


func get_next_state(state: State) -> State: # 状态之间的转换逻辑
	if can_see_player():
		return State.RUN
		
	match state:
		State.IDLE:
			if  state_machine.state_time > 2:
				return State.WALK
				
		State.WALK:
			if wall_checker.is_colliding() or not floor_checker.is_colliding(): #前方是墙或不是悬崖
				return State.IDLE	
				
		State.RUN:
			if calm_down_timer.is_stopped():
				return State.WALK
	
	return state
	
func transition_state(from:State, to:State) -> void: # 传入两个参，一个从什么状态退出，一个进入什么状态
	
	match to:
		State.IDLE:
			animation_player.play("idle")
			if wall_checker.is_colliding():
				direction *= -1
		
		State.WALK:
			animation_player.play("walk")
			if not floor_checker.is_colliding():
				direction *= -1
				floor_checker.force_raycast_update() # 更新缓存内的碰撞数据，使野猪重新判断前方路况
		
		State.RUN:
			animation_player.play("run")


func _on_hurtbox_hurt(hitbox: Hitbox) -> void:
	stats.health -= 1
	if stats.health == 0:
		queue_free()
