import graphviz

# Crear el objeto de diagrama de flujo
# format='pdf' asegura que sea vectorizado
# engine='dot' es el estándar para diagramas jerárquicos de arriba hacia abajo
dot = graphviz.Digraph('Flowchart_QPSK', format='pdf', engine='dot')

# Configuraciones globales para estilo IEEE (fuentes limpias, tamaño adecuado)
dot.attr(rankdir='TB', bgcolor='white', fontname='Helvetica', fontsize='10')
dot.attr('node', fontname='Helvetica', fontsize='9', style='filled')
dot.attr('edge', fontname='Helvetica', fontsize='8')

# 1. Nodos de Inicio y Fin (Ovalados)
dot.node('Start', 'INICIO', shape='oval', fillcolor='#D9EAD3')
dot.node('End', 'FIN', shape='oval', fillcolor='#D9EAD3')

# 2. Nodos de Proceso (Rectángulos con bordes redondeados)
proceso_color = '#C9DAF8' # Azul claro
dot.node('PRBS', 'Generar secuencia PRBS\n(N = 20,000 símbolos)', shape='box', fillcolor=proceso_color)
dot.node('QPSK_Mod', 'Modulación QPSK\n(M = 4)', shape='box', fillcolor=proceso_color)
dot.node('Pulse', 'Conformación de pulso\n(Rectangular, Nsamp = 40)', shape='box', fillcolor=proceso_color)

# 3. Nodo de Decisión (Diamante)
dot.node('Decision', 'Evaluar\nEscenario', shape='diamond', fillcolor='#FCE5CD')

# --- RAMA BANDA BASE ---
bb_color = '#FFF2CC' # Amarillo claro
dot.node('Ch_BB', 'Canal Ideal\n(h = 1)', shape='box', fillcolor=bb_color)
dot.node('AWGN_BB', 'Sumar AWGN\n(SNR = 30 dB)', shape='box', fillcolor=bb_color)
dot.node('Demod_BB', 'Demodulación QPSK', shape='box', fillcolor=bb_color)
dot.node('BER_BB', 'Calcular BER\n(Banda Base)', shape='box', fillcolor=bb_color)

# --- RAMA PASO BANDA ---
pb_color = '#EAD1DC' # Rosa claro
dot.node('UpConv', 'Conversión Ascendente\n(Fc = 5 GHz)', shape='box', fillcolor=pb_color)
dot.node('AWGN_PB', 'Sumar AWGN\n(SNR = 30 dB)', shape='box', fillcolor=pb_color)
dot.node('DownConv', 'Conversión Descendente\n(Oscilador Local)', shape='box', fillcolor=pb_color)
dot.node('LPF', 'Filtro Pasa Bajas\n(Chebyshev Tipo II)', shape='box', fillcolor=pb_color)
dot.node('Delay', 'Compensación de\nRetardo', shape='box', fillcolor=pb_color)
dot.node('Downsamp', 'Decimación\n(Downsampling)', shape='box', fillcolor=pb_color)
dot.node('Demod_PB', 'Demodulación QPSK', shape='box', fillcolor=pb_color)
dot.node('BER_PB', 'Calcular BER\n(Paso Banda)', shape='box', fillcolor=pb_color)

# 4. Nodo de Resultados
dot.node('Results', 'Análisis de Resultados:\nConstelaciones y Espectros', shape='box', fillcolor='#D0E0E3')

# 5. Conexiones (Edges)
dot.edge('Start', 'PRBS')
dot.edge('PRBS', 'QPSK_Mod')
dot.edge('QPSK_Mod', 'Pulse')
dot.edge('Pulse', 'Decision')

# Ramas desde la decisión
dot.edge('Decision', 'Ch_BB', label=' Banda Base ')
dot.edge('Decision', 'UpConv', label=' Paso Banda ')

# Flujo Banda Base
dot.edge('Ch_BB', 'AWGN_BB')
dot.edge('AWGN_BB', 'Demod_BB')
dot.edge('Demod_BB', 'BER_BB')
dot.edge('BER_BB', 'Results')

# Flujo Paso Banda
dot.edge('UpConv', 'AWGN_PB')
dot.edge('AWGN_PB', 'DownConv')
dot.edge('DownConv', 'LPF')
dot.edge('LPF', 'Delay')
dot.edge('Delay', 'Downsamp')
dot.edge('Downsamp', 'Demod_PB')
dot.edge('Demod_PB', 'BER_PB')
dot.edge('BER_PB', 'Results')

# Salida
dot.edge('Results', 'End')

# Renderizar el diagrama y guardar como 'flowchart.pdf'
ruta_salida = dot.render(filename='flowchart', cleanup=True)
print(f"¡Diagrama generado con éxito!")
print(f"Archivo guardado en: {ruta_salida}")