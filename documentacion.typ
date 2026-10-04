#set page(paper: "a4", margin: 2.5cm)
#set text(font: "Times New Roman", size: 12pt)

#align(center)[
  #v(4cm)

  #text(size: 16pt, weight: "bold")[
    LAB 06 - INDEXING
  ]

  #v(2cm)

  Juliana Sofía Novoa Solano

  Miguel Francisco Vargas Contreras

  #v(1cm)

  Administración de Bases de Datos

  #v(1cm)

  Profesor: ANDRÉS CALDERÓN ROMERO

  #v(5cm)

  Pontificia Universidad Javeriana

  Bogotá D.C.

  2026
]

#pagebreak()

= Introducción

La recuperación eficiente de datos es un aspecto fundamental en la gestión de bases de datos, y la indexación desempeña un papel crucial en la optimización del rendimiento de las consultas. En este laboratorio, exploraremos el impacto de la indexación en el tiempo de ejecución de las consultas mediante el análisis de estas antes y después de la creación de índices.

Para lograrlo, trabajaremos con un conjunto de datos simulado que contiene cuentas de usuario, hilos de conversación y publicaciones en un foro hipotético. Generaremos datos aleatorios para poblar las tablas y ejecutaremos un conjunto de consultas predefinidas para medir su rendimiento. Utilizando el comando `EXPLAIN ANALYZE` en PostgreSQL, evaluaremos los tiempos de ejecución de las consultas, compararemos los resultados y observaremos cómo la indexación mejora la eficiencia.

= Summaries

== Functional dependencies

#figure(
  image("assets/functional.jpeg", width: 60%),
  caption: [Functional dependencies summary.],
)

== Number of distinct values (NDV) counts

#figure(
  image("assets/number.jpeg", width: 60%),
  caption: [Number of distinct values counts summary.],
)

== Most common values (MCV) lists

#figure(
  image("assets/common.jpeg", width: 60%),
  caption: [Most common values lists summary.],
)

= Data Generation and Performance Evaluation

En esta sección, estableceremos las bases prácticas para analizar el comportamiento del motor de la base de datos. El proceso se divide en dos etapas principales:

- *Generación de datos sintéticos:* Crearemos un esquema relacional básico y poblaremos las tablas con datos simulados utilizando funciones aleatorias y diccionarios de texto.
- *Evaluación de rendimiento:* Mediremos los tiempos de respuesta de consultas predefinidas antes y después de aplicar estrategias de indexación, utilizando la herramienta `EXPLAIN ANALYZE` para observar los cambios en los planes de ejecución.

== Generating Random Data

#figure(
  image("assets/conection.jpeg", width: 60%),
  caption: [Conexióna la db con psql-client.],
)

#figure(
  image("assets/tables.jpg", width: 60%),
  caption: [Creación de tablas.],
)

#figure(
  image("assets/archivo.jpg", width: 60%),
  caption: [Creación de tablas (archivo).],
)

#figure(
  image("assets/txt.jpg", width: 60%),
  caption: [Mover el archivo words.txt al servidor.],
)

#figure(
  image("assets/compose.jpg", width: 60%),
  caption: [Edición del compose que crea el postgresql para poder tener el archivo.],
)

#figure(
  image("assets/load.jpg", width: 60%),
  caption: [Carga del archivo al servidor.],
)

#figure(
  image("assets/sql.jpg", width: 60%),
  caption: [Crear la tabla "words" y llenarla con ese sql.],
)

#figure(
  image("assets/registros.jpg", width: 60%),
  caption: [Registros aleatorios en "account", "thread" y "post", creadas anteriormente.],
)

#figure(
  image("assets/insert.jpg", width: 60%),
  caption: [Sql para creación de registros aleatorios.],
)

#figure(
  image("assets/consultas.jpg", width: 60%),
  caption: [Escritura de las 5 consultas.],
)

== Measuring Performance Without and With Indexes

=== See all my posts

#figure(
  image("assets/q1.jpg", width: 60%),
  caption: [See all my posts query.],
)

=== How many posts have I made?

#figure(
  image("assets/q2.jpg", width: 60%),
  caption: [How many posts have I made? query.],
)

===  See all current posts for a Thread

#figure(
  image("assets/q3.jpg", width: 60%),
  caption: [See all current posts for a Thread query.],
)

=== How many posts have I made to a Thread?

#figure(
  image("assets/q4.jpg", width: 60%),
  caption: [How many posts have I made to a Thread? query.],
)

===  See all current posts for a Thread for this month, in order

#figure(
  image("assets/q5.jpg", width: 60%),
  caption: [See all current posts for a Thread for this month, in order query.],
)

= Performance of the queries with the best index implementation

#figure(
  image("assets/index.jpg", width: 60%),
  caption: [Comparación de tiempo de ejecución antes y después de Índices.],
)

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

= Autonomous Work

== MongoDB

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
  caption: [Índice que combina dos campos en orden ascendente: primero thread_id y luego visible.],
)

#figure(
  image("assets/i3.png", width: 60%),
  caption: [Índice que combina tres campos en orden ascendente: primero thread_id, luego account_id y visible.],
)

#figure(
  image("assets/i5.png", width: 60%),
  caption: [Crea un índice compuesto sobre thread_id y account_id, pero únicamente para los documentos donde visible: true.],
)

#figure(
  image("assets/i6.png", width: 60%),
  caption: [Crea un índice compuesto agrupando por thread_id y ordenando por la fecha de creación (created), aplicando también el filtro parcial para incluir solo los registros con visible: true.],
)

=== Comparación de Rendimiento MongoDB antes y después de índices

#figure(
  image("assets/mongo.jpg", width: 60%),
  caption: [Rendmiento mongoDB.],
)

  - *sql/create.sql*: Sentencias DDL para crear las tablas relacionales requeridas: accounts, threads y posts.
- *sql/load_words.sql*: Instrucciones para cargar el diccionario de palabras a una tabla de apoyo en PostgreSQL.
- *sql/random.sql*: Procedimiento en PL/pgSQL que genera de forma sintética cuentas, hilos y 100.000 publicaciones con fechas y textos aleatorios.
- *sql/consultas.sql*: Definición de las 5 consultas de prueba (Q1 a Q5: posts de usuario, conteo de posts de usuario, posts de hilo, conteo de posts de hilo y posts mensuales ordenados).
- *sql/indexes.sql*: Creación de los índices B-Tree en PostgreSQL (idx_posts_account_id, idx_posts_thread_id y el índice compuesto idx_posts_thread_id_date).

- *src/index.ts*: Script de benchmark para PostgreSQL con Bun. Ejecuta Q1-Q5 sin índices y con índices, extrayendo tiempos promedio, desviación estándar, nodos de plan (Seq Scan, Bitmap Heap Scan, etc.) y accesos a buffers mediante EXPLAIN (ANALYZE, BUFFERS).
- *src/mongo_index.ts*: Script de benchmark para MongoDB (componente de trabajo autónomo NoSQL). Evalúa las 5 consultas equivalentes con .explain("executionStats") antes y después de crear índices, midiendo latencias y documentos examinados vs escaneados.
- *src/seed_mongo.ts*: Script para sembrar o migrar los 100.000 registros a MongoDB (ya sea directamente desde PostgreSQL o de forma autónoma).
- *src/plot.py*: Script en Python (Matplotlib) para generar las gráficas comparativas de rendimiento en formato PNG a partir de los JSON de métricas.

- *mongo/seed.js*: Script para poblar las colecciones accounts, threads y posts directamente en la consola mongosh.
- *mongo/consultas.js*: Sintaxis MQL de las 5 consultas con explicaciones de ejecución.
- *mongo/indexes.js*: Definición de índices en MongoDB (account_id, thread_id, compuesto con date).


= Índices en postgresql vs mongo

#table(
  columns: (auto, 1fr, 1fr),
  inset: 10pt,
  align: (center + horizon, left, left),
  table.header(
    [*Característica*], [*PostgreSQL*], [*MongoDB*]
  ),
  [*Estructura Principal*],
  [Árboles B-Tree (además de GiST, GIN, BRIN y Hash).],
  [Árboles B-Tree por defecto para índices secundarios y único (\_id).],

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
    `EXPLAIN ANALYZE` (muestra nodos como Seq Scan, Bitmap Index Scan y costos).
  ],
  [
    `.explain("executionStats")` (muestra documentos examinados vs. devueltos y latencia).
  ]
)

= Conclusión

A lo largo de este laboratorio, se demostró de manera práctica el impacto crítico que tienen las estrategias de indexación en el rendimiento de los motores de bases de datos, abarcando tanto entornos relacionales (PostgreSQL) como no relacionales (MongoDB). A partir de la evaluación de consultas sobre un conjunto de datos sintético de 100,000 registros, se pueden extraer las siguientes conclusiones principales:

- *Mitigación del impacto del Seq Scan:* Sin índices, el motor de la base de datos se ve obligado a realizar un recorrido secuencial completo por toda la tabla o colección para resolver las consultas, lo que genera latencias elevadas y un consumo innecesario de recursos de E/S y memoria a medida que el volumen de datos crece.

- *Eficiencia de los índices B-Tree y compuestos:* La implementación de índices monocolumna y compuestos (como aquellos estructurados por `thread_id`, `account_id` y `visible`) permite reducir drásticamente los tiempos de ejecución de las consultas. En la mayoría de los casos evaluados (Q1 a Q5), el tiempo de respuesta disminuyó desde el rango de los milisegundos altos (6 ms - 50+ ms) hasta fracciones de milisegundo, transformando búsquedas costosas en accesos directos de tipo Index Scan.

- *Optimización mediante índices parciales y ordenamiento previo:* El uso de índices parciales (filtrados por condiciones como `visible = true`) no solo optimiza el espacio de almacenamiento y aumenta la densidad de claves en la memoria caché (buffer pool), sino que también permite la eliminación completa de fases de ordenamiento costosas (Sort Elimination), tal como se evidenció en la consulta Q5.

- *Paralelos conceptuales entre arquitecturas:* Aunque PostgreSQL y MongoDB manejan sintaxis y estructuras subyacentes distintas, comparten principios de optimización fundamentales. Mientras PostgreSQL aprovecha características avanzadas como Index Only Scans mediante mapas de visibilidad y planes analíticos detallados (`EXPLAIN ANALYZE`), MongoDB utiliza colecciones orientadas a documentos y colecciones indexadas con expresiones de filtros parciales (`partialFilterExpression`), logrando mejoras de rendimiento proporcionales y muy similares.

En resumen, una correcta planeación, diseño y aplicación de índices —alineados directamente con los patrones de acceso y las consultas más frecuentes de la aplicación— es una práctica indispensable para garantizar la escalabilidad, la eficiencia operativa y la reducción de la carga computacional en los sistemas gestores de bases de datos.