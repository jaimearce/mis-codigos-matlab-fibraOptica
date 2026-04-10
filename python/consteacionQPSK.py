import matplotlib.pyplot as plt
import numpy as np

# Ángulos para QPSK (fases: pi/4, 3pi/4, 5pi/4, 7pi/4)
fases = np.array([np.pi/4, 3*np.pi/4, 5*np.pi/4, 7*np.pi/4])
I = np.cos(fases)
Q = np.sin(fases)

# Crear la figura
plt.figure(figsize=(5, 5))

# Dibujar los puntos ideales
plt.scatter(I, Q, color='#1f77b4', s=150, zorder=3, label='Símbolos ideales')

# Dibujar los ejes (Umbrales de decisión)
plt.axhline(0, color='black', linewidth=1.5, zorder=1)
plt.axvline(0, color='black', linewidth=1.5, zorder=1)

# Etiquetas de los bits (Mapeo Gray clásico)
etiquetas = ['11', '01', '00', '10']
for i, txt in enumerate(etiquetas):
    # Desplazar un poco el texto para que no se superponga con el punto
    plt.text(I[i] + 0.1, Q[i] + 0.1, txt, fontsize=12, fontweight='bold')

# Configuración estética
plt.grid(True, linestyle='--', alpha=0.6, zorder=2)
plt.xlim(-1.5, 1.5)
plt.ylim(-1.5, 1.5)
plt.xlabel('En Fase (I)', fontsize=12)
plt.ylabel('En Cuadratura (Q)', fontsize=12)
plt.title('Constelación Teórica Ideal (QPSK)', fontsize=14, pad=15)

# Guardar como PDF sin bordes blancos excesivos
plt.savefig('qpsk_ideal.pdf', format='pdf', bbox_inches='tight')
print("¡Constelación generada y guardada como qpsk_ideal.pdf!")