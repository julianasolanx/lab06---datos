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

== Measuring Performance Without and With Indexes

=== See all my posts

=== How many posts have I made?

===  See all current posts for a Thread

=== How many posts have I made to a Thread?

===  See all current posts for a Thread for this month, in order

= Autonomous Work

= Conlusión
