= Análisis de Índices y Principio de Funcionamiento

El archivo `indexes.sql` propone una jerarquía de índices construidos sobre la tabla `post`. Cada uno de ellos ataca un patrón de acceso específico:

== Índice Monocolumna: `CREATE INDEX ON post (account_id);`
- *Mecanismo B-Tree:* Organiza las claves de `account_id` de forma ordenada en páginas raíz, intermedias y hojas, junto con los identificadores físicos de tupla (`ctid`).
- *Mejora esperada:* Permite una búsqueda binaria $O(log N)$ para ubicar las entradas correspondientes al usuario `1`. Para *Q1*, PostgreSQL reemplaza el barrido completo de la tabla por un `Bitmap Index Scan`, reduciendo el tiempo de lectura.
- *Index Only Scan en Q2:* Dado que la consulta solo requiere contar filas y la columna `account_id` se encuentra almacenada directamente en el árbol, PostgreSQL (apoyándose en el *Visibility Map*) evita por completo acceder a la tabla base (*Heap Fetches: 0*), realizando una agregación directa en memoria.

== Índice Monocolumna: `CREATE INDEX ON post (thread_id);`
- *Propósito:* Acelera búsquedas orientadas al identificador de hilo, aislando el ~0.1% de posts asociados a un hilo específico dentro de los 100.000 registros.

== Índices Compuestos: `(thread_id, visible)` y `(thread_id, account_id, visible)`
- *Orden de columnas y principio del prefijo izquierdo:* En un índice compuesto B-Tree, los datos se ordenan jerárquicamente por la primera columna, luego por la segunda y así sucesivamente.
- *Mejora en Q3 y Q4:* Permite satisfacer predicados de igualdad múltiples (`thread_id = 1 AND visible = TRUE` o `thread_id = 1 AND account_id = 1`) en una única pasada sobre el índice. Para *Q4*, el índice tricolumna cubre tanto el filtro como las columnas evaluadas, facilitando un `Index Only Scan` ultra rápido.

== Índices Parciales: `(thread_id, account_id) WHERE visible = TRUE;`
- *Principio:* En lugar de indexar las 100.000 filas, solo se incluyen aquellas tuplas que cumplen el predicado `visible = TRUE`.
- *Ventajas:*
  1. *Ahorro de almacenamiento y memoria:* Reduce el número de páginas hoja y el espacio ocupado en disco (~1.7 MB vs ~2.6 MB del índice completo), incrementando la probabilidad de permanencia en el *buffer pool*.
  2. *Mayor densidad de claves:* Se eliminan del árbol las publicaciones ocultas o borradas lógicamente, acelerando las búsquedas de usuarios activos.

== Índice Parcial con Ordenamiento: `(thread_id, created) WHERE visible = TRUE;`
- *Eliminación de la etapa de ordenamiento (Sort Elimination):* En la consulta *Q5*, sin índices el motor debe filtrar secuencialmente y luego ejecutar un algoritmo de ordenamiento en memoria (`quicksort` sobre disco/RAM). Con este índice, PostgreSQL busca las tuplas de `thread_id = 1` y las recorre secuencialmente a través de las hojas del árbol B-Tree, las cuales ya están físicamente ordenadas por `created ASC`. Como consecuencia, el nodo `Sort` desaparece completamente del plan de ejecución.
