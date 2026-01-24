class_name Hitbox
extends Area2D

signal hit(hurtbox) # 定义信号，打到了hurtbox


func _init() -> void:
	area_entered.connect(_on_area_entered) # 当接收的 area 进入此区域时发出, 调用 _on_area_entered

func _on_area_entered(hurtbox:Hurtbox) -> void:
	print("[Hit] %s => %s" % [owner.name, hurtbox.owner.name]) # 打印信息， 谁 打了 谁
	hit.emit(hurtbox) # 发出信号
	hurtbox.hurt.emit(self)
