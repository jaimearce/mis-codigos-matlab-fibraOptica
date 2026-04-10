import graphviz

# Crear el objeto de diagrama de bloques
# Usamos 'dot' y rankdir='LR' para que fluya de Izquierda a Derecha
dot = graphviz.Digraph('Receptor_Coherente', format='pdf', engine='dot')

# Configuración de estilo global (compatible con el formato IEEE)
dot.attr(rankdir='LR', nodesep='0.6', ranksep='0.8')
dot.attr('node', fontname='Helvetica', fontsize='10', style='filled')
dot.attr('edge', fontname='Helvetica', fontsize='9')

# 1. Nodos de Entrada y Salida (Sin borde)
dot.node('RF', 'Señal RF\nRecibida r(t)', shape='plaintext', fillcolor='white')
dot.node('I_out', 'Rama en Fase\nI(t)', shape='plaintext', fillcolor='white')
dot.node('Q_out', 'Rama en Cuad.\nQ(t)', shape='plaintext', fillcolor='white')

# Punto de división de la señal
dot.node('Split', '', shape='point', width='0.05')

# 2. Mezcladores / Multiplicadores (Círculos)
dot.node('Mix_I', 'X', shape='circle', fillcolor='#FCE5CD', width='0.5', fixedsize='true', fontsize='14')
dot.node('Mix_Q', 'X', shape='circle', fillcolor='#FCE5CD', width='0.5', fixedsize='true', fontsize='14')

# 3. Filtros Pasa Bajas (Rectángulos)
dot.node('LPF_I', 'Filtro Paso Bajo\n(LPF)', shape='box', fillcolor='#D9EAD3', width='1.2', height='0.5')
dot.node('LPF_Q', 'Filtro Paso Bajo\n(LPF)', shape='box', fillcolor='#D9EAD3', width='1.2', height='0.5')

# 4. Oscilador Local y Desfasador
dot.node('LO', 'Oscilador\nLocal (Fc)', shape='circle', fillcolor='#C9DAF8', width='0.8', fixedsize='true')
dot.node('Phase', 'Desfasador\n-90°', shape='box', fillcolor='#EAD1DC', height='0.4')

# --- CONEXIONES ---

# Entrada de señal
dot.edge('RF', 'Split', dir='none')
dot.edge('Split', 'Mix_I')
dot.edge('Split', 'Mix_Q')

# Rama Superior (In-Phase)
dot.edge('Mix_I', 'LPF_I', label=' I(t)/2 + Alta Frec. ')
dot.edge('LPF_I', 'I_out')

# Rama Inferior (Quadrature)
dot.edge('Mix_Q', 'LPF_Q', label=' Q(t)/2 + Alta Frec. ')
dot.edge('LPF_Q', 'Q_out')

# Conexiones del Oscilador Local
dot.edge('LO', 'Mix_I', label=' cos(2πf_c t)')
dot.edge('LO', 'Phase')
dot.edge('Phase', 'Mix_Q', label=' sin(2πf_c t)')

# Forzar alineación vertical para mejorar la estética
with dot.subgraph() as s:
    s.attr(rank='same')
    s.node('Split')
    s.node('LO')

# Renderizar el diagrama y guardar como 'diagrama_mezclador.pdf'
ruta_salida = dot.render(filename='diagrama_mezclador', cleanup=True)
print(f"¡Diagrama de bloques generado con éxito!")
print(f"Archivo guardado en: {ruta_salida}")