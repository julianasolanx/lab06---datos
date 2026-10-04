#set page(paper: "a4", margin: 2.5cm)
#set text(font: "Times New Roman", size: 12pt, lang: "es")

#align(center)[
  #v(2cm)
  #image("assets/logo.png", width: 25%)
  #v(1cm)

  #text(size: 18pt, weight: "bold")[
    LABORATORIO 06 - INDEXACIÓN
  ]

  #v(1.5cm)

  Juliana Sofía Novoa Solano \
  Miguel Francisco Vargas Contreras

  #v(1cm)

  Administración de Bases de Datos

  #v(1cm)

  Profesor: ANDRÉS CALDERÓN ROMERO

  #v(3cm)

  Pontificia Universidad Javeriana \
  Bogotá D.C. \
  2026
]

#pagebreak()
#set page(numbering: "1")

= Introducción

La recuperación eficiente de datos es un aspecto fundamental en la gestión de bases de datos, y la indexación desempeña un papel crucial en la optimización del rendimiento de las consultas. En este laboratorio, exploraremos el impacto de la indexación en el tiempo de ejecución de las consultas mediante el análisis de estas antes y después de la creación de índices.

Para lograrlo, trabajaremos con un conjunto de datos simulado que contiene cuentas de usuario, hilos de conversación y publicaciones en un foro hipotético. Generaremos datos aleatorios para poblar las tablas y ejecutaremos un conjunto de consultas predefinidas para medir su rendimiento. Utilizando el comando `EXPLAIN ANALYZE` en PostgreSQL, evaluaremos los tiempos de ejecución de las consultas, compararemos los resultados y observaremos cómo la indexación mejora la eficiencia.

= Resúmenes de Estadísticas Extendidas

A continuación se presentan los resúmenes manuscritos sobre los tres tipos de estadísticas extendidas en PostgreSQL (Capítulo 13 de *PostgreSQL for Jobseekers*), las cuales permiten al optimizador estimar con precisión la cardinalidad cuando existen correlaciones entre múltiples columnas:

== Dependencias funcionales (Functional dependencies)

#figure(
  image("assets/functional.jpeg", width: 60%),
  caption: [Resumen manuscrito: Dependencias funcionales.],
)

== Conteo de número de valores distintos (NDV counts)

#figure(
  image("assets/number.jpeg", width: 60%),
  caption: [Resumen manuscrito: Conteo de valores distintos (NDV).],
)

== Listas de valores más comunes (MCV lists)

#figure(
  image("assets/common.jpeg", width: 60%),
  caption: [Resumen manuscrito: Listas de valores más comunes (MCV).],
)

= Generación de Datos y Evaluación de Rendimiento

En esta sección, estableceremos las bases prácticas para analizar el comportamiento del motor de la base de datos. El proceso se divide en dos etapas principales:

- *Generación de datos sintéticos:* Crearemos un esquema relacional básico y poblaremos las tablas con datos simulados utilizando funciones aleatorias y diccionarios de texto.
- *Evaluación de rendimiento:* Mediremos los tiempos de respuesta de consultas predefinidas antes y después de aplicar estrategias de indexación, utilizando la herramienta `EXPLAIN ANALYZE` para observar los cambios en los planes de ejecución.

== Generación de Datos Aleatorios

Para la configuración del entorno, se utilizó un contenedor Docker con PostgreSQL montando el archivo de diccionario `words.txt`. A continuación se evidencia el proceso de conexión, creación del esquema relacional (`account`, `thread`, `post`), carga del diccionario mediante `COPY` y la generación aleatoria de 100.000 tuplas:

#figure(
  image("assets/conection.jpeg", width: 60%),
  caption: [Conexión a la base de datos con psql-client.],
)

#figure(
  image("assets/tables.jpg", width: 60%),
  caption: [Creación de tablas en PostgreSQL.],
)

#figure(
  image("assets/archivo.jpg", width: 60%),
  caption: [Script DDL de creación de tablas.],
)

#figure(
  image("assets/txt.jpg", width: 60%),
  caption: [Transferencia del archivo words.txt al servidor.],
)

#figure(
  image("assets/compose.jpg", width: 60%),
  caption: [Configuración de volúmenes en Docker Compose.],
)

#figure(
  image("assets/load.jpg", width: 60%),
  caption: [Carga del archivo de palabras en el contenedor.],
)

#figure(
  image("assets/sql.jpg", width: 60%),
  caption: [Creación y llenado de la tabla auxiliar words.],
)

#figure(
  image("assets/registros.jpg", width: 60%),
  caption: [Verificación de registros generados en account, thread y post.],
)

#figure(
  image("assets/insert.jpg", width: 60%),
  caption: [Procedimiento SQL para generación de registros aleatorios.],
)

#figure(
  image("assets/consultas.jpg", width: 60%),
  caption: [Definición de las cinco consultas de prueba.],
)

== Medición de Rendimiento Sin y Con Índices

A continuación se evalúan las cinco consultas del laboratorio comparando su plan de ejecución antes y después de la creación de índices.

=== Consulta Q1: Ver todas mis publicaciones (See all my posts)
Recupera todas las publicaciones creadas por un usuario específico:
```sql
SELECT * FROM post WHERE account_id = 1;
```

#figure(
  image("assets/q1.jpg", width: 60%),
  caption: [Plan de ejecución de la consulta Q1.],
)

=== Consulta Q2: Total de publicaciones realizadas (How many posts have I made?)
Calcula el total de publicaciones realizadas por un usuario:
```sql
SELECT count(*) FROM post WHERE account_id = 1;
```

#figure(
  image("assets/q2.jpg", width: 60%),
  caption: [Plan de ejecución de la consulta Q2.],
)

=== Consulta Q3: Publicaciones activas de un hilo (See all current posts for a Thread)
Obtiene las publicaciones activas (`visible = TRUE`) asociadas a un hilo:
```sql
SELECT * FROM post WHERE thread_id = 1 AND visible = TRUE;
```

#figure(
  image("assets/q3.jpg", width: 60%),
  caption: [Plan de ejecución de la consulta Q3.],
)

=== Consulta Q4: Publicaciones de un usuario en un hilo (How many posts have I made to a Thread?)
Cuenta las publicaciones visibles de un usuario dentro de un hilo específico:
```sql
SELECT count(*) FROM post WHERE thread_id = 1 AND account_id = 1 AND visible = TRUE;
```

#figure(
  image("assets/q4.jpg", width: 60%),
  caption: [Plan de ejecución de la consulta Q4.],
)

=== Consulta Q5: Publicaciones de un hilo para este mes en orden (See all current posts for a Thread for this month, in order)
Recupera los posts visibles de un hilo creados en el mes corriente ordenados cronológicamente:
```sql
SELECT * FROM post
WHERE thread_id = 1 AND visible = TRUE
  AND created >= date_trunc('month', now())
ORDER BY created;
```

#figure(
  image("assets/q5.jpg", width: 60%),
  caption: [Plan de ejecución de la consulta Q5.],
)

= Rendimiento de las consultas con la mejor implementación de índices

#figure(
  image("assets/index.jpg", width: 75%),
  caption: [Comparación de tiempo de ejecución antes y después de índices en PostgreSQL.],
)

A continuación se sintetizan los tiempos promedio de ejecución medidos con `EXPLAIN (ANALYZE, BUFFERS)`:

#align(center)[
  #table(
    columns: (auto, auto, auto, auto),
    inset: 8pt,
    align: (left, center, center, center),
    table.header([*Consulta*], [*Sin Índices*], [*Con Índices*], [*Aceleración*]),
    [Q1: Ver todas mis publicaciones], [7.39 ms], [0.33 ms], [*22.4×*],
    [Q2: Total de publicaciones realizadas], [6.59 ms], [0.11 ms], [*59.9×*],
    [Q3: Publicaciones activas de un hilo], [6.49 ms], [0.08 ms], [*81.1×*],
    [Q4: Publicaciones de usuario en un hilo], [6.35 ms], [0.03 ms], [*211.7×*],
    [Q5: Publicaciones de un hilo para este mes], [8.66 ms], [0.02 ms], [*433.0×*],
  )
]

= Análisis de Índices y Principio de Funcionamiento

El archivo `indexes.sql` propone una jerarquía de índices construidos sobre la tabla `post`. Cada uno de ellos ataca un patrón de acceso específico:

== Índice Monocolumna: `CREATE INDEX ON post (account_id);`
- *Mecanismo B-Tree:* Organiza las claves de `account_id` de forma ordenada en páginas raíz, intermedias y hojas, junto con los identificadores físicos de tupla (`ctid`).
- *Mejora esperada:* Permite una búsqueda binaria $O(log N)$ para ubicar las entradas correspondientes al usuario `1`. Para *Q1*, PostgreSQL reemplaza el barrido completo de la tabla por una búsqueda directa en el índice, reduciendo sustancialmente el tiempo de lectura.
- *Index Only Scan en Q2:* Dado que la consulta solo requiere contar filas y la columna `account_id` se encuentra almacenada directamente en el árbol, PostgreSQL (apoyándose en el mapa de visibilidad o *Visibility Map*) evita por completo acceder a la tabla base (*Heap Fetches: 0*), realizando una agregación directa en memoria.

== Índice Monocolumna: `CREATE INDEX ON post (thread_id);`
- *Propósito:* Acelera búsquedas orientadas al identificador de hilo, aislando el ~0.1% de publicaciones asociadas a un hilo específico dentro de los 100.000 registros.

== Índices Compuestos: `(thread_id, visible)` y `(thread_id, account_id, visible)`
- *Orden de columnas y principio del prefijo izquierdo:* En un índice compuesto B-Tree, los datos se ordenan jerárquicamente por la primera columna, luego por la segunda y así sucesivamente.
- *Mejora en Q3 y Q4:* Permite satisfacer predicados de igualdad múltiples (`thread_id = 1 AND visible = TRUE` o `thread_id = 1 AND account_id = 1`) en una única pasada sobre el índice. Para *Q4*, el índice tricolumna cubre tanto el filtro como las columnas evaluadas, facilitando un acceso directo ultra rápido.

== Índices Parciales: `(thread_id, account_id) WHERE visible = TRUE;`
- *Principio:* En lugar de indexar las 100.000 filas, solo se incluyen aquellas tuplas que cumplen el predicado `visible = TRUE`.

== Índice Parcial con Ordenamiento: `(thread_id, created) WHERE visible = TRUE;`
- *Eliminación del ordenamiento en memoria (Sort Elimination):* En la consulta *Q5*, sin índices el motor debe filtrar secuencialmente y luego ordenar los registros en memoria. Con este índice, PostgreSQL busca las tuplas de `thread_id = 1` y las recorre a través de las hojas del árbol B-Tree, las cuales ya están físicamente ordenadas por `created ASC`. Como consecuencia, la necesidad de ordenar en memoria desaparece completamente.

= Trabajo Autónomo

== MongoDB

Para evaluar un gestor de base de datos no relacional, se implementó la misma estructura de datos en MongoDB poblando la colección `post` con 100.000 documentos equivalentes.

=== Creación de índices

#figure(
  image("assets/i1.png", width: 60%),
  caption: [Índice en orden ascendente sobre el campo account_id.],
)

#figure(
  image("assets/i2.png", width: 60%),
  caption: [Índice en orden ascendente sobre el campo thread_id.],
)

#figure(
  image("assets/i4.png", width: 60%),
  caption: [Índice compuesto sobre thread_id y visible en orden ascendente.],
)

#figure(
  image("assets/i3.png", width: 60%),
  caption: [Índice compuesto sobre thread_id, account_id y visible.],
)

#figure(
  image("assets/i5.png", width: 60%),
  caption: [Índice parcial sobre thread_id y account_id con filtro visible: true.],
)

#figure(
  image("assets/i6.png", width: 60%),
  caption: [Índice parcial sobre thread_id ordenado por created con filtro visible: true.],
)

=== Principio de Funcionamiento de los Índices en MongoDB

En MongoDB (utilizando su motor de almacenamiento por defecto, WiredTiger), los índices se estructuran mediante árboles B-Tree que mantienen un subconjunto ordenado de los campos de los documentos, almacenando punteros directos hacia la ubicación física en disco de cada documento (*RecordId*):

- *Búsqueda por Índice:* Sin índices, MongoDB debe realizar un escaneo completo de la colección, inspeccionando los 100.000 documentos uno a uno. Con un índice sobre el campo consultado, el motor ejecuta una búsqueda binaria en el árbol B-Tree, examinando únicamente las entradas de clave coincidentes y recuperando solo los documentos pertinentes.
- *Consultas Cubiertas (Covered Queries):* Cuando todos los campos solicitados por la consulta (tanto en los criterios del filtro como en la proyección) residen dentro del índice, MongoDB resuelve la operación directamente sobre las páginas del árbol B-Tree en memoria caché, sin acceder a la colección en disco (`totalDocsExamined: 0`). Esto elimina por completo el costo de E/S y produce tiempos de respuesta inferiores a un milisegundo (como se evidenció en las consultas Q2 y Q4).
- *Índices Compuestos y la regla ESR:* Al crear índices sobre múltiples campos (por ejemplo, `{ thread_id: 1, visible: 1 }`), MongoDB los ordena de forma jerárquica siguiendo la regla ESR (*Equality, Sort, Range*). Las consultas que filtran por el prefijo del índice pueden satisfacer múltiples condiciones de igualdad en una sola pasada eficiente por el árbol.
- *Expresiones de Filtro Parcial (`partialFilterExpression`):* Permiten indexar únicamente los documentos que cumplen una condición específica (por ejemplo, `{ visible: true }`). Esto disminuye drásticamente el espacio ocupado por el índice en memoria RAM y reduce la sobrecarga de mantenimiento en operaciones de inserción o actualización, ignorando publicaciones inactivas o borradas lógicamente.
- *Eliminación del ordenamiento en memoria:* Por defecto, si una consulta requiere ordenar resultados (`sort`) y no existe un índice con dicho ordenamiento previo, MongoDB acumula los documentos en memoria para ordenarlos, proceso limitado por un consumo de memoria estricto. Al utilizar un índice compuesto con la clave de orden (`created`), las entradas se leen ya ordenadas desde las hojas del árbol B-Tree, evitando cualquier ordenamiento en memoria (observado en Q5).

=== Comparación de Rendimiento en MongoDB antes y después de índices

#figure(
  image("assets/mongo.jpg", width: 75%),
  caption: [Rendimiento en MongoDB antes y después de índices.],
)

A continuación se presentan los tiempos promedio de ejecución obtenidos en MongoDB antes y después de aplicar los índices:

#align(center)[
  #table(
    columns: (auto, auto, auto, auto),
    inset: 8pt,
    align: (left, center, center, center),
    table.header([*Consulta*], [*Sin Índices*], [*Con Índices*], [*Aceleración*]),
    [Q1: Ver todas mis publicaciones], [51.58 ms], [1.00 ms], [*51.6×*],
    [Q2: Total de publicaciones realizadas], [34.42 ms], [0.65 ms], [*52.9×*],
    [Q3: Publicaciones activas de un hilo], [53.75 ms], [1.22 ms], [*44.1×*],
    [Q4: Publicaciones de usuario en un hilo], [38.33 ms], [0.58 ms], [*66.1×*],
    [Q5: Publicaciones de un hilo para este mes], [62.75 ms], [0.70 ms], [*89.6×*],
  )
]

= Comparativa de Índices: PostgreSQL frente a MongoDB

#table(
  columns: (auto, 1fr, 1fr),
  inset: 10pt,
  align: (center + horizon, left, left),
  table.header([*Característica*], [*PostgreSQL*], [*MongoDB*]),
  [*Estructura Principal*],
  [Árboles B-Tree (además de GiST, GIN, BRIN y Hash).],
  [Árboles B-Tree por defecto para índices secundarios y clave primaria única (\_id).],

  [*Creación de Índice*],
  [
    ```sql
    CREATE INDEX idx_name
    ON table_name(column_name);
    ```
  ],
  [
    ```javascript
    await coll.createIndex(
      { field_name: 1 },
      { name: "idx_name" }
    );
    ```
  ],

  [*Índices Parciales*],
  [
    ```sql
    CREATE INDEX idx_partial
    ON table(col)
    WHERE visible = true;
    ```
  ],
  [
    ```javascript
    await coll.createIndex(
      { field: 1 },
      {
        partialFilterExpression:
          { visible: true }
      }
    );
    ```
  ],

  [*Análisis de Rendimiento*],
  [
    `EXPLAIN ANALYZE` (detalla los tiempos reales de ejecución y el uso de buffers).
  ],
  [
    `.explain("executionStats")` (revela documentos examinados frente a devueltos y latencia).
  ],
)

= Conclusión

A lo largo de este laboratorio, se demostró de manera práctica el impacto crítico que tienen las estrategias de indexación en el rendimiento de los motores de bases de datos, abarcando tanto entornos relacionales (PostgreSQL) como no relacionales (MongoDB). A partir de la evaluación de consultas sobre un conjunto de datos sintético de 100.000 registros, se pueden extraer las siguientes conclusiones principales:

- *Mitigación del impacto del escaneo secuencial:* Sin índices, el motor de la base de datos se ve obligado a realizar un recorrido secuencial completo por toda la tabla o colección para resolver las consultas, lo que genera latencias elevadas y un consumo innecesario de recursos de entrada/salida y memoria a medida que el volumen de datos crece.

- *Eficiencia de los índices B-Tree y compuestos:* La implementación de índices monocolumna y compuestos (como aquellos estructurados por `thread_id`, `account_id` y `visible`) permite reducir drásticamente los tiempos de ejecución de las consultas. En la mayoría de los casos evaluados (Q1 a Q5), el tiempo de respuesta disminuyó desde el rango de los milisegundos altos (6 ms - 60+ ms) hasta fracciones de milisegundo, transformando búsquedas costosas en accesos directos de tipo Index Scan.

- *Optimización mediante índices parciales y ordenamiento previo:* El uso de índices parciales (filtrados por condiciones como `visible = true`) no solo optimiza el espacio de almacenamiento y aumenta la densidad de claves en la memoria caché (buffer pool), sino que también permite la eliminación completa de fases de ordenamiento costosas (*Sort Elimination*), tal como se evidenció en la consulta Q5.

- *Paralelos conceptuales entre arquitecturas:* Aunque PostgreSQL y MongoDB manejan sintaxis y modelos de datos distintos, comparten principios de optimización fundamentales. Mientras PostgreSQL aprovecha características avanzadas como *Index Only Scans* mediante mapas de visibilidad y planes analíticos detallados (`EXPLAIN ANALYZE`), MongoDB utiliza índices secundarios sobre documentos con filtros parciales (`partialFilterExpression`) y consultas cubiertas (*Covered Queries*), logrando factores de aceleración muy similares.

En resumen, una correcta planeación, diseño y aplicación de índices —alineados directamente con los patrones de acceso y las consultas más frecuentes de la aplicación— es una práctica indispensable para garantizar la escalabilidad, la eficiencia operativa y la reducción de la carga computacional en los sistemas gestores de bases de datos.
