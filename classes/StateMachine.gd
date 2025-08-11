class_name StateMachine
extends Node

# 我们需要在该节点的owner节点中自定义这三个函数 transition_state get_next_state tick_physics
# get_next_state 根据当前状态判断下一时刻所处的状态
# transition_state 进入不同的状态执行的代码，如播放动画，设置速度
# tick_physics 写当处于某个状态时执行的指令

var current_state : int = -1 : # 当前状态 # 一旦它的值被改变，就会触发 transition_state
	set(v):
		owner.transition_state(current_state, v)

		current_state = v
		state_time = 0

var state_time : float
	
func _ready() -> void: # 初始化状态机
	await owner.ready #等待该节点的最前面的父节点 ready
	current_state = 0 # 设置为 current_state
	
func _physics_process(delta: float) -> void:
	while true:
		var next := owner.get_next_state(current_state) as int
		if current_state == next:
			break
		current_state = next
	
	owner.tick_physics(current_state, delta)
	state_time += delta
	
