class_name NewsEvent
extends Resource
## Lo que pasa entre dos oleadas: alguien trae una noticia (un diálogo)
## y el jugador elige una de las opciones. Cada evento es un .tres en data/news/.

## Diálogo con la noticia. Puede quedar vacío.
@export var dialogue: Dialogue
## Opciones para elegir (pensado para 2).
@export var options: Array[NewsOption] = []
