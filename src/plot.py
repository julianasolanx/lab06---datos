import json
import math
import sys

import matplotlib.pyplot as plt
import numpy as np

# 1. Cargar los datos dinámicos generados por index.ts
json_file = "benchmark_results.json"

try:
    with open(json_file, "r") as f:
        data = json.load(f)
except Exception as e:
    print(f"Error cargando {json_file}: {e}")
    sys.exit(1)

queries = ["Q1", "Q2", "Q3", "Q4", "Q5"]
sin_indices = [data["baseline"][q]["avg"] for q in queries]
con_indices = [data["indexed"][q]["avg"] for q in queries]

print(f"Graficando datos desde {json_file}:")
for q, b, idx in zip(queries, sin_indices, con_indices):
    print(f"   {q} -> Base: {b:.2f} ms | Con Índices: {idx:.3f} ms")

# 2. Configurar gráfico simple de barras
x = np.arange(len(queries))
width = 0.35

fig, ax = plt.subplots(figsize=(8.5, 4.5))

rects1 = ax.bar(
    x - width / 2,
    sin_indices,
    width,
    label="Sin Índices",
    color="#e74c3c",
    edgecolor="black",
    linewidth=0.5,
)
rects2 = ax.bar(
    x + width / 2,
    con_indices,
    width,
    label="Con Índices",
    color="#2ecc71",
    edgecolor="black",
    linewidth=0.5,
)

# 3. Escala y ejes con números reales
max_val = max(sin_indices)
y_max = math.ceil(max_val + 2)
ax.set_ylim(0, y_max)
step = 2 if y_max <= 12 else 4
y_ticks = list(range(0, y_max + 1, step))
ax.set_yticks(y_ticks)
ax.set_yticklabels([f"{t} ms" for t in y_ticks], fontsize=10)

ax.set_ylabel("Tiempo de Ejecución (ms)", fontsize=11, fontweight="bold")
ax.set_title(
    "Comparación de Tiempo de Ejecución Antes y Después de Índices",
    fontsize=12,
    fontweight="bold",
)
ax.set_xticks(x)
ax.set_xticklabels(queries, fontsize=11, fontweight="bold")
ax.legend(fontsize=10, loc="upper left")
ax.grid(axis="y", linestyle="--", alpha=0.5)

# 4. Valores reales legibles encima de cada barra
for rect in rects1:
    h = rect.get_height()
    ax.annotate(
        f"{h:.2f} ms",
        xy=(rect.get_x() + rect.get_width() / 2, h),
        xytext=(0, 4),
        textcoords="offset points",
        ha="center",
        va="bottom",
        fontsize=9,
        fontweight="bold",
        color="#c0392b",
    )

for rect in rects2:
    h = rect.get_height()
    txt = f"{h:.2f} ms" if h >= 0.1 else f"{h:.3f} ms"
    ax.annotate(
        txt,
        xy=(rect.get_x() + rect.get_width() / 2, h),
        xytext=(0, 4),
        textcoords="offset points",
        ha="center",
        va="bottom",
        fontsize=9,
        fontweight="bold",
        color="#27ae60",
    )

# 5. Guardar únicamente en PNG
plt.tight_layout()
plt.savefig("assets/benchmark_comparison.png", dpi=300)
plt.close()
print("✓ Gráfica simple generada en assets/benchmark_comparison.png")
