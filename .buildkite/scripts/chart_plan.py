#!/usr/bin/env python3
"""Generate a stacked horizontal bar chart from a bktec bin-packing plan JSON."""

import json
import os
import subprocess
import sys

try:
    import matplotlib
except ImportError:
    install_dir = '/tmp/bk_py_deps'
    os.makedirs(install_dir, exist_ok=True)
    subprocess.check_call([
        sys.executable, '-m', 'pip', 'install', 'matplotlib',
        '--target', install_dir, '--quiet'
    ])
    sys.path.insert(0, install_dir)
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

# Assign a colour per file, cycling through tab20 + tab20b + tab20c palettes
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
    figsize=(18, max(5, n_nodes * 0.9 + 2)),
    gridspec_kw={'width_ratios': [2, 1]}
)

# Minimum visual width so tiny segments are always visible (2% of max node duration)
max_duration = max(
    sum(t.get('estimated_duration', 0) for t in task.get('tests', []))
    for _, task in sorted_tasks
) / 1_000_000
min_visual_width = max_duration * 0.02

for i, (_, task) in enumerate(sorted_tasks):
    left = 0.0
    for test in task.get('tests', []):
        path = test.get('path', '')
        # estimated_duration is in microseconds; convert to seconds
        duration = test.get('estimated_duration', 0) / 1_000_000
        draw_width = max(duration, min_visual_width)
        ax.barh(i, draw_width, left=left,
                color=file_color.get(path, '#cccccc'),
                edgecolor='white', linewidth=0.5, height=0.65)
        # Label the segment with the file index number if wide enough to fit
        if draw_width >= 0.05:
            ax.text(left + draw_width / 2, i, str(file_index[path]),
                    ha='center', va='center',
                    fontsize=8, color='white', fontweight='bold')
        left += draw_width

ax.set_yticks(range(n_nodes))
ax.set_yticklabels([f'Node {t["node_number"]}' for _, t in sorted_tasks])
ax.invert_yaxis()
ax.set_xlabel('Duration (seconds)')
ax.set_title('Bin Packing Plan', fontweight='bold', pad=12)
ax.grid(axis='x', alpha=0.3, linestyle='--')
ax.spines['top'].set_visible(False)
ax.spines['right'].set_visible(False)

# Right-hand index: coloured swatch + number + full file path
ax_leg.axis('off')
y = 0.98
line_height = 0.062
header_props = dict(fontsize=8, fontfamily='monospace', fontweight='bold',
                    transform=ax_leg.transAxes, verticalalignment='top')
ax_leg.text(0.02, y, '#    File', **header_props)
y -= line_height
ax_leg.text(0.02, y, '─' * 55, fontsize=8, fontfamily='monospace',
            transform=ax_leg.transAxes, verticalalignment='top', color='#888888')
y -= line_height

for path in all_files:
    idx = file_index[path]
    color = file_color[path]
    label = path.lstrip('./')
    # Coloured square swatch
    ax_leg.add_patch(plt.Rectangle(
        (0.02, y - 0.025), 0.04, 0.04,
        transform=ax_leg.transAxes, color=color, clip_on=False
    ))
    ax_leg.text(0.08, y, f'{idx:>3}.  {label}',
                transform=ax_leg.transAxes, fontsize=8,
                fontfamily='monospace', verticalalignment='top')
    y -= line_height

plt.tight_layout()
plt.savefig(output_file, dpi=150, bbox_inches='tight', facecolor='white')
print(f"Chart saved to {output_file}")
