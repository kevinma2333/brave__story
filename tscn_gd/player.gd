extends CharacterBody2D

# (状态机) 枚举玩家状态
enum State{ 
	IDLE,
	RUNNING,
	JUMP,
	FALL,
	LANDING,
	WALL_SLIDING,
	WALL_JUMP,
}

const GROUND_STATES := [State.IDLE, State.RUNNING, State.LANDING] # 在地面上所对应的状态
const RUN_SPEED := 160.0 # 跑步速度
const JUMP_VELOCITY :=-320.0 # 跳跃高度
const FLOOR_ACCELERATION := RUN_SPEED / 0.2 # 在地面上的加速度
const AIR_ACCELERATION := RUN_SPEED / 0.1 # 在空中的加速度
const WALL_JUMP_VELOCITY := Vector2(500, -320) # 在墙跳时的跳跃高度

# 从项目设置中获取重力加速度
var default_gravity := ProjectSettings.get("physics/2d/default_gravity") as float 
#跳跃第一帧
var is_first_tick := false

@onready var graphics: Node2D = $Graphics
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var coyote_timer: Timer = $CoyoteTimer
@onready var jump_request_timer: Timer = $JumpRequestTimer
@onready var hand_checker: RayCast2D = $Graphics/HandChecker
@onready var foot_checker: RayCast2D = $Graphics/FootChecker
@onready var state_machine: StateMachine = $StateMachine

# coyote_timer 郊狼时间，指在高处下落时玩家可以在空中起跳
# jump_request_timer 在手动跳跃（非自然落地）落地前0.1秒内玩家若按下跳跃键，则玩家会在落地后的下一帧起跳

func  _unhandled_input(event: InputEvent) -> void: #根据玩家按键进行移动（仅处理跳跃）
	# 当有一个输入未被 Input 消耗时调用
	# 因为在 _physics_process 函数中没有任何一个 Input 消耗"jump"
	# 所以按下跳跃键必定触发"jump"
	if event.is_action_pressed("jump"):
		jump_request_timer.start()
	if event.is_action_released("jump"):
		jump_request_timer.stop() # 停止跳跃时间计时器
		if velocity.y < JUMP_VELOCITY /2:
		# 如果松开了跳跃键且速度的y分量小于跳跃高度的一半
		# 则主动帮玩家降低跳跃高度
		# 从而实现根据按跳跃键的时间的长度控制跳跃的高度
			velocity.y = JUMP_VELOCITY /2

		
# 因为我们在StateMachine节点中使用了 transition_state get_next_state tick_physics
# 所以在 StateMachine 的 owner 节点中定义这三个函数

func tick_physics(state:State, delta: float) -> void: # 写当玩家处于某个状态时执行的指令
	match state:	
		State.IDLE:
			move(default_gravity,delta)
			
		State.RUNNING:
			move(default_gravity,delta)
			
		State.JUMP:
			move(0.0 if is_first_tick else default_gravity,delta) # 取消跳跃第一帧的重力影响，时期可以跳到正常高度
			
		State.FALL:
			move(default_gravity,delta)
		
		State.LANDING:
			stand(default_gravity,delta)
		
		State.WALL_SLIDING:
			move(default_gravity / 5, delta)
			graphics.scale.x = get_wall_normal().x
			
		State.WALL_JUMP:
			if state_machine.state_time < 0.1: # 使玩家刚进入蹬墙跳的一段时间内忽略玩家输入，始终让角色背对墙
				stand(0.0 if is_first_tick else default_gravity,delta) # 取消跳跃第一帧的重力影响，时期可以跳到正常高度
				graphics.scale.x = get_wall_normal().x
			else:
				move(default_gravity,delta)
			

			
	is_first_tick = false # 不再是跳跃第一帧		

func move(gravity: float,delta:float) -> void:	#根据按键进行移动（不包括跳跃）
	 # 获取玩家按键输入，a为-1，不按为0，d为1 
	var direction := Input.get_axis("move_left","move_right")
	
	var acceleration := FLOOR_ACCELERATION if is_on_floor() else AIR_ACCELERATION # 判断加速度取何值
	#上面等效于下面
	#var acceleration
	#if is_on_floor():
		#acceleration = FLOOR_ACCELERATION
	#else:
		#acceleration = AIR_ACCELERATION
	
	#玩家的速度由 velocity.x 变到 direction * RUN_SPEED，加速度为 ACCELERATION * delta
	#其中 velocity.x 为当前速度， direction 为方向
	velocity.x = move_toward(velocity.x,direction * RUN_SPEED,acceleration * delta)
	velocity.y += gravity * delta # 速度 = 重力加速度 * 时间
	
	if not is_zero_approx(direction):
		graphics.scale.x = -1 if direction < 0 else +1 # 反转图像
	
	move_and_slide() # 根据 velocity 移动物体

func stand(gravity: float,delta: float) -> void: # 忽略键盘输入进行向下坠落（播放着陆动画时不能使玩家产生位移）
	var acceleration := FLOOR_ACCELERATION if is_on_floor() else AIR_ACCELERATION # 判断加速度取何值
	velocity.x = move_toward(velocity.x,0.0,acceleration * delta) # 从运动到静止匀速减速运动
	velocity.y += gravity * delta
	
	move_and_slide()
	
func can_wall_slide() ->bool: # 判断是否在墙上（是否可以向下滑动）
	return is_on_wall() and hand_checker.is_colliding() and foot_checker.is_colliding

func get_next_state(state: State) -> State: # 根据当前状态判断玩家下一时刻所处的状态
	
	var can_jump := is_on_floor() or coyote_timer.time_left > 0 # 如果玩家在地板上或郊狼时间内，则为true
	var should_jump := can_jump and jump_request_timer.time_left > 0 # 如果玩家跳跃或空中跳跃时间内，则为true
	if should_jump: # 如果因该起跳
		return State.JUMP # 将状态更改为跳跃
	
	var direction := Input.get_axis("move_left","move_right") # 获取玩家按键输入，a为-1，不按为0，d为1 
	var is_still := is_zero_approx(direction) and is_zero_approx(velocity.x)  # 仅当玩家完全停止时返回true
	
	match state: # match 相当于if,例如：当State为IDLE时执行。。。，当State为RUNNING执行。。。
		State.IDLE:
			if not is_on_floor(): # 处理非手动跳跃情况（下落）
				return State.FALL
			if not is_still: # 如果玩家不是站立不动的
				return State.RUNNING # 将状态切换为运动
		State.RUNNING:
			if not is_on_floor(): # 处理非手动跳跃情况（下落）
				return State.FALL
			if is_still: # 如果玩家是站立不动的
				return State.IDLE # 将状态切换为站立
		State.JUMP:
			if velocity.y >= 0: # 当在空中且y加速度大于0（因为godot中y正方向向下，所以y加速度大于0时为下降）
				return State.FALL # 将状态更改为下降 
		State.FALL:
			if is_on_floor():
				return State.LANDING if is_still else State.RUNNING
			if can_wall_slide(): 
				# 手脚均需要碰到墙面才可以触发滑墙
				return State.WALL_SLIDING
		State.LANDING:
			if not is_still:
				return State.RUNNING
			if not animation_player.is_playing():
				return State.IDLE
		State.WALL_SLIDING:
			if jump_request_timer.time_left > 0: # 可以跳
				return State.WALL_JUMP
			if is_on_floor():
				return State.IDLE
			if not is_on_wall():
				return State.FALL
		State.WALL_JUMP:
			if velocity.y >= 0: # 下落状态
				return State.FALL
			if can_wall_slide() and not is_first_tick:
				return State.WALL_SLIDING
		
	return state
	
	
func transition_state(from:State, to:State) -> void: # 传入两个参，一个从什么状态退出，一个进入什么状态
# transition_state 进入不同的状态执行的代码，如播放动画，设置速度
	
	## 测试用（打印玩家状态）
	#print("[%s] %s => %s" %[
		#Engine.get_physics_frames(),
		#State.keys()[from],
		#State.keys()[to],
	#])
	
	if from not in GROUND_STATES and to in GROUND_STATES: # 如果from在空中，to在地面上
		coyote_timer.stop()
	
	match to:
		State.IDLE:
			animation_player.play("idle")
			
		State.RUNNING:
			animation_player.play("running")
			
		State.JUMP:
			animation_player.play("jump")
			velocity.y = JUMP_VELOCITY
			coyote_timer.stop() # 停止郊狼时间的计时器
			jump_request_timer.stop() # 停止在空中跳跃计时器
			
		State.FALL:
			animation_player.play("fall")
			if from in GROUND_STATES: # 从地面开始下落
				coyote_timer.start()
		
		State.LANDING:
				animation_player.play("landing")
				
		State.WALL_SLIDING:
				animation_player.play("wall_sliding")
				
		State.WALL_JUMP:
			animation_player.play("jump")
			velocity= WALL_JUMP_VELOCITY
			velocity.x *= get_wall_normal().x # 根据墙壁方向判断向左还是向右
			jump_request_timer.stop() # 停止在空中跳跃计时器
	
	## 测试用	（在蹬墙跳的时候减慢时间）
	#if to == State.WALL_JUMP:
		#Engine.time_scale = 0.3
	#if from == State.WALL_JUMP:
		#Engine.time_scale = 1.0

	is_first_tick = true # 因为刚切换，所以这是跳跃第一帧			
