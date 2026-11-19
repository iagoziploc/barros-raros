# Barros Raros

Tower defense hecho para la game jam [Liberen el Paraná](https://itch.io/jam/liberen-el-parana-gamejam).

Del norte llegan los inversores a llevarse las **tierras raras** y el **agua dulce** del Paraná. El **Cara de Barro** despierta y amasa **golems de barro** para defender el río.

Inspirado en la obra de [Manuel Brandazza](https://www.manuelbrandazza.com).

**Diseño y narrativa:** el GDD está en un documento compartido del equipo. Si sos parte del equipo y no lo tenés, pedile el link a iago.

## Equipo

| Rol | Persona |
| --- | --- |
| Game design, narrativa y programación | iago |
| Audio | _por definir_ |
| Arte y animación | _por definir_ |

## Cómo jugar la versión en desarrollo (sin saber programar)

No hace falta instalar nada más que Godot, ni saber usar Git.

### 1. Bajar Godot 4.7.2 (una sola vez)

1. Entrá a <https://godotengine.org/download/archive/> y buscá **4.7.2-stable**.
2. Descargá la versión **Standard** para tu sistema. **No** la que dice **.NET**.
3. En Windows viene en un `.zip`: descomprimilo en una carpeta fija (por ejemplo `C:\godot`). Adentro hay un `.exe` que se abre con doble clic; no tiene instalador.

Tiene que ser exactamente la 4.7.2: con otra versión, Godot puede modificar los archivos del proyecto.

### 2. Bajar el juego

1. Entrá a <https://github.com/iagoziploc/barros-raros>.
2. Tocá el botón verde **Code** y después **Download ZIP**.
3. Descomprimí el `.zip`. Te queda una carpeta `barros-raros-main`.

### 3. Abrirlo y jugar

1. Abrí Godot. Aparece el **Administrador de proyectos**.
2. Tocá **Importar**, buscá la carpeta `barros-raros-main` y elegí el archivo **`project.godot`**. Confirmá con **Importar y editar**.
3. La primera vez tarda un minuto: Godot prepara las imágenes y los sonidos.
4. Cuando se abra el editor, apretá **F5** (o el triángulo ▶ arriba a la derecha) para jugar.

### Controles

| Acción | Cómo |
| --- | --- |
| Elegir un golem | Botón de la barra de abajo, o teclas **1**, **2**, **3**… |
| Colocarlo | **Clic izquierdo** en el mapa (si el fantasma está rojo, ahí no se puede) |
| Cancelar | **Clic derecho** o **Esc** |
| Destruir un golem (devuelve la mitad) | **Clic derecho** sobre el golem, sin nada seleccionado |

Al terminar la oleada, los golems se disuelven y devuelven todo su costo. Si la tierra o el agua llegan a 0 y no las recuperás en 5 segundos, perdés.

### Para tener la versión más nueva

Repetí el paso 2 (bajar el ZIP) y el 3 (importar). Conviene borrar antes la carpeta vieja para no confundirlas.

## Para el equipo que edita el proyecto

- Todos con **Godot 4.7.2 estándar**.
- Clonar: `git clone https://github.com/iagoziploc/barros-raros.git` e importar `project.godot`.
- **Nombres de archivos:** minúsculas, con `_` y sin tildes ni ñ (`golem_de_barro.png`, no `Gólem de Barro.png`). La versión web distingue mayúsculas.
- Los archivos `.import` que Godot crea al lado de cada imagen o sonido **se suben al repo**: guardan cómo se importan (por ejemplo, el loop de la música).

### Estructura

| Carpeta | Qué va ahí |
| --- | --- |
| `assets/art/` | Sprites, animaciones, fondos |
| `assets/audio/` | Música y efectos |
| `assets/fonts/` | Tipografías |
| `localization/` | Todos los textos del juego (`strings.csv`) |
| `data/` | **Valores de balance** (`.tres`). Se editan en el inspector de Godot, sin tocar código |
| `systems/` | Sistemas globales: economía, oleadas, colocación de golems |
| `levels/` | Escenas de los niveles: mapa, camino, zona húmeda y río |
| `entities/` | Enemigos y golems |
| `ui/` | Interfaz: HUD y barra de construcción |
| `tests/` | Pruebas automáticas |

### Pruebas

```
godot --headless --path . res://tests/economy_test.tscn
godot --headless --path . res://tests/enemy_test.tscn
godot --headless --path . res://tests/wave_test.tscn
godot --headless --path . res://tests/hud_test.tscn
godot --headless --path . res://tests/golem_test.tscn
```

Cada una termina con código 0 si todo pasa.

## Fechas

- Cierre de entregas: **24/11/2026, 03:00**
