class_name Stats
extends Node

@export var max_health: int = 3

@onready var health : int = max_health: # 确保可以获得赋值后的 max_health
	set(v):
		v = clamp(v, 0, max_health) # 限制v的大小在0 ~ max_health之间
		if health == v:
			return
		health = v
