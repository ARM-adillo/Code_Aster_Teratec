#
import numpy as np
import matplotlib.pyplot as plt


# Data
refine = [1, 3, 6]
time = [1.94, 4.92, 45.5]


# Plot weak scalability
fig, ax = plt.subplots()
ax.plot(refine, time, linestyle='--', marker='*', color='#ff6c4d')

ax.set_title('Sequential result for different refinement values', fontweight='bold')
ax.set_xlabel("Refine")
ax.set_ylabel('Time (in s)')

ax.set_ylim([0, 50])
ax.grid(True)

plt.savefig(f'sequential_result.pdf')
