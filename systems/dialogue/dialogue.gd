class_name Dialogue
extends Resource
## Un diálogo completo: sus líneas en orden y cómo se muestra.
## Cada diálogo es un .tres en data/dialogues/.

enum Style {
	BOX,        ## Caja abajo con retrato, sobre el juego.
	CINEMATIC,  ## Pantalla oscura con el texto al centro.
}

@export var style := Style.BOX
## Si es true, el juego se pausa mientras dura el diálogo (la música sigue).
@export var pauses_game := true
@export var lines: Array[DialogueLine] = []
