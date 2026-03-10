#!/usr/bin/env python3
"""Generate a stacked horizontal bar chart from a bktec bin-packing plan JSON."""

import json
import os
import sys

try:
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
except ImportError:
    os.system("pip install matplotlib --quiet")
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt

plan_file = sys.argv[1] if len(sys.argv) > 1 else 'bin-packing-plan-pretty.json'
output_file = sys.argv[2] if len(sys.argv) > 2 else 'bin-packing-plan-chart.png'

with open(plan_file) as f:
    plan = json.load(f)

tasks = plan.get('tasks', {})
if not tasks:
    print("No tasks found in plan, skipping chart generation")
    sys.exit(0)

sorted_tasks = sorted(tasks.items(), key=lambda x: int(x[0]))

# Collect all unique files in order of first appearance across nodes
all_files = []
seen = set()
for _, task in sorted_tasks:
    for test in task.get('tests', []):
        path = test.get('path', '')
        if path and path not in seen:
            all_files.append(path)
            seen.add(path)

if not all_files:
    print("No test files found in plan, skipping chart generation")
    sys.exit(0)

# Assign a colour per file, cycling through tab20 + tab20b palettes
palette = (
    [plt.get_cmap('tab20')(i) for i in range(20)] +
    [plt.get_cmap('tab20b')(i) for i in range(20)] +
    [plt.get_cmap('tab20c')(i) for i in range(20)]
)
file_color = {f: palette[i % len(palette)] for i, f in enumerate(all_files)}
file_index = {f: i + 1 for i, f in enumerate(all_files)}

n_nodes = len(sorted_tasks)
fig, (ax, ax_leg) = plt.subplots(
    1, 2,
    figsize=(18, max(5, n_nodes * 0.7 + 2)),
    gridspec_kw={'width_ratios': [2, 1]}
)

for i, (_, task) in enumerate(sorted_tasks):
    left = 0.0
    for test in task.get('tests', []):
        path = test.get('path', '')
        # estimated_duration is in milliseconds; convert to seconds
        duration = test.get('estimated_duration', 0) / 1000.0
        ax.barh(i, duration, left=left,
                color=file_color.get(path, '#cccccc'),
                edgecolor='white', linewidth=0.5, height=0.65)
        # Label the segment with the file index number if wide enough
        if duration >= 0.5:
            ax.text(left + duration / 2, i, str(file_index[path]),
                    ha='center', va='center',
                    fontsize=7, color='white', fontweight='bold')
        left += duration

ax.set_yticks(range(n_nodes))
ax.set_yticklabels([f'Node {t["node_number"]}' for _, t in sorted_tasks])
ax.invert_yaxis()
ax.set_xlabel('Duration (seconds)')
ax.set_title('Bin Packing Plan', fontweight='bold', pad=12)
ax.grid(axis='x', alpha=0.3, linestyle='--')
ax.spines['top'].set_visible(False)
ax.spines['right'].set_visible(False)

# Right-hand index: number → full file path
ax_leg.axis('off')
lines = ['#   File\n' + '─' * 60]
for path in all_files:
    idx = file_index[path]
    # Strip common spec/ prefix to save space
    label = path.removeprefix('spec/')
    lines.append(f'{idx:>3}.  {label}')

ax_leg.text(
    0.02, 0.98, '\n'.join(lines),
    transform=ax_leg.transAxes,
    fontsize=7, verticalalignment='top', fontfamily='monospace',
    bbox=dict(boxstyle='round,pad=0.5', facecolor='#f5f5f5', alpha=0.8)
)

plt.tight_layout()
plt.savefig(output_file, dpi=150, bbox_inches='tight', facecolor='white')
print(f"Chart saved to {output_file}")
