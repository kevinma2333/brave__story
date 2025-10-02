extends Enemy

enum State {
	IDLE,
	WALK,
	RUN,
}

@onready var wall_chacker: RayCast2D = $Graphics/WallChacker
@onready var player_chacker: RayCast2D = $Graphics/PlayerChacker2
@onready var floor_chacker: RayCast2D = $Graphics/FloorChacker2
@onready var calm_down_timer: Timer = $CalmDownTimer

func get_next_state(state: State) -> State: # 状态之间的转换逻辑
	if player_chacker.is_colliding(): # 如果检测到玩家
		return State.RUN
		
	match state:
		State.IDLE:
			if  state_machine.state_time > 2:
				return State.WALK
				
		State.WALK:
			if wall_chacker.is_colliding() or not floor_chacker.is_colliding(): #前方是墙或则不是悬崖
				return State.IDLE	
				
		State.RUN:
			if calm_down_timer.is_stopped():
				return State.WALK
	
	return state
	
