class_name EconomyConfig
extends Resource
## Valores de balance que usa el autoload Economy.

@export_group("Inicio y máximo")
@export var starting_earth := 100
@export var starting_water := 100
@export var max_earth := 100
@export var max_water := 100

@export_group("Muerte súbita")
## Segundos entre que un recurso llega a 0 y la derrota.
@export var sudden_death_seconds := 5.0

@export_group("Devolución de golems")
## Fracción del costo devuelta al destruir un golem (0.5 = la mitad).
@export_range(0.0, 1.0, 0.05) var refund_ratio_destroyed := 0.5
## Fracción del costo devuelta si el golem llega al final de la oleada.
@export_range(0.0, 1.0, 0.05) var refund_ratio_survived := 1.0
