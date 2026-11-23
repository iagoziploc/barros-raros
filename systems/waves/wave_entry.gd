class_name WaveEntry
extends Resource
## Un grupo de enemigos iguales dentro de una oleada.
## Cada grupo corre en paralelo con los demás de la misma oleada.

@export var enemy: EnemyData
@export var count := 10
## Segundos entre un enemigo y el siguiente de este grupo.
@export var interval := 2.0
## Segundos desde el inicio de la oleada hasta que sale el primero de este grupo.
@export var start_time := 0.0
## Por qué entradas puede salir cada enemigo del grupo: cada uno sortea una de las tildadas.
## Los que roban tierra nunca usan una entrada sin pozo (la izquierda), aunque esté tildada.
@export_flags("Arriba izquierda", "Arriba derecha", "Izquierda") var entrances := 7
