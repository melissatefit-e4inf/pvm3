#!/usr/bin/env python3
"""Graphiques de speedup pour le rapport (données : logs/perf.log analysé, logs/machines_synthese.csv)."""
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

COUL = {500: "#2a78d6", 1000: "#eb6834", 5000: "#1baf7a", 10000: "#eda100"}
MARQ = {500: "o", 1000: "s", 5000: "^", 10000: "D"}
INK, MUTED, GRID = "#1f1f1e", "#6b6a64", "#e4e3de"

def style(ax, xl, yl):
    ax.set_xlabel(xl, color=INK); ax.set_ylabel(yl, color=INK)
    ax.grid(True, color=GRID, lw=0.8); ax.set_axisbelow(True)
    for s in ("top", "right"): ax.spines[s].set_visible(False)
    for s in ("left", "bottom"): ax.spines[s].set_color(MUTED)
    ax.tick_params(colors=MUTED)

def trace(ax, data, xmax, pos_ideal=None):
    ax.plot([1, xmax], [1, xmax], ls="--", lw=1.2, color=MUTED, zorder=1)
    px, py = pos_ideal or (xmax * 0.97, xmax * 0.97)
    ax.text(px, py, "idéal S = x", color=MUTED, ha="right", va="bottom", fontsize=8)
    for n, pts in data.items():
        x, y = zip(*pts)
        ax.plot(x, y, color=COUL[n], lw=2, marker=MARQ[n], ms=7, mec="white", mew=1.5, zorder=3, label=f"N = {n}")
        ax.annotate(f"N = {n}", (x[-1], y[-1]), xytext=(6, 0), textcoords="offset points",
                    color=INK, fontsize=8, va="center")
    ax.legend(frameon=False, fontsize=8, loc="upper left")

# 1) une machine, P tâches (médianes, logs/perf.log)
une = {500: [(1, 1.12), (2, 1.67), (4, 2.52), (10, 2.35), (20, 1.47)],
       1000: [(1, 1.13), (2, 1.78), (4, 2.98), (8, 3.65), (10, 3.64), (20, 2.81)],
       5000: [(4, 4.13), (10, 5.47), (20, 5.75)],
       10000: [(4, 4.16), (10, 5.42)]}
fig, ax = plt.subplots(figsize=(6.4, 4.0), dpi=150)
trace(ax, une, 20, pos_ideal=(7.6, 7.3)); ax.set_xlim(0, 23); ax.set_ylim(0, 8)
style(ax, "Nombre de tâches P (une seule machine, pc5201l)", "Speedup S(P) = T_seq / T_par")
fig.tight_layout(); fig.savefig("figures/speedup_une_machine.png")

# 2) plusieurs machines, 1 tâche par machine (logs/machines_synthese.csv)
mach = {500: [(1, 1.11), (2, 0.32), (4, 0.25)],
        1000: [(1, 1.13), (2, 0.60), (4, 0.49)],
        5000: [(1, 1.15), (2, 1.52), (4, 1.99)],
        10000: [(2, 1.83), (4, 2.85)]}
fig, ax = plt.subplots(figsize=(6.4, 4.0), dpi=150)
trace(ax, mach, 4); ax.set_xlim(0.8, 4.6); ax.set_ylim(0, 4.3); ax.set_xticks([1, 2, 4])
style(ax, "Nombre de machines (1 tâche par machine)", "Speedup S = T_seq / T_par")
fig.tight_layout(); fig.savefig("figures/speedup_machines.png")
