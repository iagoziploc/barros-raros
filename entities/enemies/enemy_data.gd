class_name EnemyData
extends Resource
## Datos de un tipo de enemigo. Cada tipo es un .tres en data/enemies/.

@export_group("Movimiento y vida")
## Píxeles por segundo a lo largo del camino.
@export var speed := 60.0
@export var max_health := 10
## Se resta al daño de cada golpe. Cada golpe hace al menos 1 de daño.
@export var armor := 0

@export_group("Robo")
## Tierra que roba al entrar en la zona húmeda. 0 = no roba tierra.
@export var earth_stolen := 0
## Agua que roba al llegar al río. 0 = no roba agua.
@export var water_stolen := 0

@export_group("Recompensa")
## Cuánto carga la barra de la ultimate al morir.
@export var ultimate_charge := 1

@export_group("Visual")
## Si es null se dibuja un cuadrado de `placeholder_color`.
@export var texture: Texture2D
@export var sprite_scale := 1.0
@export var placeholder_color := Color.WHITE
