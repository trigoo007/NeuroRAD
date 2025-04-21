//
//  EstudioView.swift
//  NeuroRAD
//
//  Created for NeuroRAD Project
//

import SwiftUI

struct EstudioView: View {
    @ObservedObject var dataManager: NeuroDataManager
    @StateObject private var estudioManager = EstudioManager()
    @State private var modoEstudio: ModoEstudio = .tarjetas
    @State private var filtroSistema: SistemaNeurologico? = nil
    @State private var filtroCategoria: String? = nil
    
    var body: some View {
        NavigationView {
            VStack {
                // Selector de modo de estudio
                Picker("Modo de estudio", selection: $modoEstudio) {
                    Text("Tarjetas").tag(ModoEstudio.tarjetas)
                    Text("Cuestionario").tag(ModoEstudio.cuestionario)
                    Text("Asociaciones").tag(ModoEstudio.asociaciones)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Filtros
                HStack {
                    Menu {
                        Button("Todos los sistemas") {
                            filtroSistema = nil
                        }
                        
                        ForEach(SistemaNeurologico.allCases, id: \.self) { sistema in
                            Button(sistema.nombreCompleto) {
                                filtroSistema = sistema
                                // Reset de categoría al cambiar sistema
                                filtroCategoria = nil
                            }
                        }
                    } label: {
                        HStack {
                            Text(filtroSistema?.nombreCompleto ?? "Todos los sistemas")
                            Image(systemName: "chevron.down")
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    if let sistema = filtroSistema {
                        Menu {
                            Button("Todas las categorías") {
                                filtroCategoria = nil
                            }
                            
                            ForEach(obtenerCategorias(para: sistema), id: \.id) { categoria in
                                Button(categoria.nombre) {
                                    filtroCategoria = categoria.id
                                }
                            }
                        } label: {
                            HStack {
                                Text(nombreCategoria(filtroCategoria) ?? "Todas las categorías")
                                Image(systemName: "chevron.down")
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal)
                
                Divider()
                
                // Contenido según el modo de estudio
                switch modoEstudio {
                case .tarjetas:
                    TarjetasEstudioView(
                        dataManager: dataManager,
                        estudioManager: estudioManager,
                        estructuras: estructurasFiltradas()
                    )
                case .cuestionario:
                    CuestionarioView(
                        dataManager: dataManager,
                        estudioManager: estudioManager,
                        estructuras: estructurasFiltradas()
                    )
                case .asociaciones:
                    AsociacionesView(
                        dataManager: dataManager,
                        estudioManager: estudioManager,
                        estructuras: estructurasFiltradas()
                    )
                }
            }
            .navigationTitle("Estudio Neuroanatómico")
            .toolbar {
                #if os(macOS)
                ToolbarItem {
                    Button(action: {
                        estudioManager.reiniciarSesion()
                    }) {
                        Label("Reiniciar", systemImage: "arrow.clockwise")
                    }
                }
                #else
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        estudioManager.reiniciarSesion()
                    }) {
                        Label("Reiniciar", systemImage: "arrow.clockwise")
                    }
                }
                #endif
            }
        }
    }
    
    // Filtra las estructuras según los criterios seleccionados
    private func estructurasFiltradas() -> [NodoAnatomico] {
        var estructuras = Array(dataManager.nodos.values)
        
        // Filtrar por sistema
        if let sistema = filtroSistema {
            estructuras = estructuras.filter { $0.sistema == sistema }
            
            // Filtrar por categoría si está seleccionada
            if let categoria = filtroCategoria {
                estructuras = estructuras.filter { $0.categoria == categoria }
            }
        }
        
        // Ordenar por dificultad según el historial de estudio
        return estudioManager.ordenarPorPrioridad(estructuras)
    }
    
    // Obtiene las categorías disponibles para un sistema
    private func obtenerCategorias(para sistema: SistemaNeurologico) -> [CategoriaAnatomica] {
        var categoriasDelSistema: [CategoriaAnatomica] = []
        
        // Obtenemos categorías existentes en los datos
        let categoriasExistentes = Set(dataManager.nodos.values
            .filter { $0.sistema == sistema }
            .map { $0.categoria })
        
        // Creamos objetos CategoriaAnatomica para cada categoría existente
        for categoriaID in categoriasExistentes {
            categoriasDelSistema.append(
                CategoriaAnatomica(
                    id: categoriaID,
                    nombre: CategoriasAnatomicas.nombreDescriptivo(categoriaID),
                    sistema: sistema
                )
            )
        }
        
        return categoriasDelSistema.sorted { $0.nombre < $1.nombre }
    }
    
    // Obtiene el nombre descriptivo de una categoría
    private func nombreCategoria(_ categoriaID: String?) -> String? {
        guard let id = categoriaID else { return nil }
        return CategoriasAnatomicas.nombreDescriptivo(id)
    }
}

// Modos de estudio disponibles
enum ModoEstudio {
    case tarjetas
    case cuestionario
    case asociaciones
}

// Vista para el modo de tarjetas de estudio
struct TarjetasEstudioView: View {
    let dataManager: NeuroDataManager
    let estudioManager: EstudioManager
    let estructuras: [NodoAnatomico]
    
    @State private var tarjetaActual = 0
    @State private var mostrarRespuesta = false
    @State private var animarTarjeta = false
    @State private var offset = CGSize.zero
    
    var body: some View {
        ZStack {
            // Mensaje si no hay estructuras
            if estructuras.isEmpty {
                Text("No hay estructuras que coincidan con los filtros seleccionados")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack {
                    // Contador de progreso
                    Text("\(tarjetaActual + 1) de \(estructuras.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top)
                    
                    // La tarjeta actual
                    tarjetaView(for: estructuras[tarjetaActual])
                        .rotation3DEffect(
                            .degrees(mostrarRespuesta ? 180 : 0),
                            axis: (x: 0.0, y: 1.0, z: 0.0)
                        )
                        .offset(offset)
                        .gesture(
                            DragGesture()
                                .onChanged { gesture in
                                    self.offset = gesture.translation
                                }
                                .onEnded { gesture in
                                    withAnimation {
                                        if gesture.translation.width < -100 {
                                            self.siguienteTarjeta()
                                        } else if gesture.translation.width > 100 {
                                            self.tarjetaAnterior()
                                        }
                                        self.offset = .zero
                                    }
                                }
                        )
                    
                    // Botones de navegación
                    HStack(spacing: 40) {
                        Button(action: tarjetaAnterior) {
                            Image(systemName: "arrow.left.circle.fill")
                                .font(.title)
                                .foregroundColor(.blue)
                        }
                        .disabled(tarjetaActual == 0)
                        .opacity(tarjetaActual == 0 ? 0.5 : 1)
                        
                        Button(action: voltearTarjeta) {
                            Image(systemName: "arrow.2.squarepath")
                                .font(.title)
                                .foregroundColor(.blue)
                        }
                        
                        Button(action: siguienteTarjeta) {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.title)
                                .foregroundColor(.blue)
                        }
                        .disabled(tarjetaActual == estructuras.count - 1)
                        .opacity(tarjetaActual == estructuras.count - 1 ? 0.5 : 1)
                    }
                    .padding()
                    
                    // Botones de evaluación
                    if mostrarRespuesta {
                        HStack(spacing: 20) {
                            Button(action: { evaluarTarjeta(.dificil) }) {
                                EvaluacionButton(texto: "Difícil", color: .red)
                            }
                            
                            Button(action: { evaluarTarjeta(.medio) }) {
                                EvaluacionButton(texto: "Medio", color: .orange)
                            }
                            
                            Button(action: { evaluarTarjeta(.facil) }) {
                                EvaluacionButton(texto: "Fácil", color: .green)
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .animation(.default, value: mostrarRespuesta)
    }
    
    // Vista para una tarjeta individual
    @ViewBuilder
    private func tarjetaView(for estructura: NodoAnatomico) -> some View {
        ZStack {
            if mostrarRespuesta {
                // Cara trasera (respuesta)
                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading) {
                        Text(estructura.nombreEspanol)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(estructura.nombreLatin)
                            .font(.headline)
                            .italic()
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom)
                    
                    Group {
                        Text("Descripción:")
                            .font(.headline)
                        
                        Text(estructura.descripcion)
                            .font(.body)
                    }
                    
                    Divider()
                    
                    Group {
                        Text("Función:")
                            .font(.headline)
                        
                        ForEach(estructura.funciones, id: \.self) { funcion in
                            Text("• \(funcion)")
                                .padding(.vertical, 2)
                        }
                    }
                    
                    Spacer()
                    
                    HStack {
                        Text("Código: ")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Text(estructura.codigo)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .monospaced()
                    }
                }
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            } else {
                // Cara frontal (pregunta)
                VStack {
                    Spacer()
                    
                    Text("¿Qué es?")
                        .font(.title)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 20)
                    
                    Text(estructura.idCode)
                        .font(.title)
                        .fontWeight(.bold)
                        .padding()
                    
                    if let sistema = estructura.sistema {
                        HStack {
                            Circle()
                                .fill(colorSistema(sistema))
                                .frame(width: 12, height: 12)
                            Text(sistema.nombreCompleto)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 8)
                    }
                    
                    Spacer()
                    
                    Text("Toca para ver la respuesta")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom)
                }
            }
        }
        .padding()
        .frame(height: 450)
        #if os(macOS)
        .background(Color(NSColor.windowBackgroundColor))
        #else
        .background(Color(.systemBackground))
        #endif
        .cornerRadius(12)
        .shadow(radius: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal)
        .contentShape(Rectangle())
        .onTapGesture {
            voltearTarjeta()
        }
    }
    
    // Color específico para cada sistema
    private func colorSistema(_ sistema: SistemaNeurologico) -> Color {
        switch sistema {
        case .centralSC: return .blue
        case .perifericoSP: return .green
        case .vascularSV: return .red
        case .espaciosSE: return .purple
        }
    }
    
    // Acciones para las tarjetas
    private func voltearTarjeta() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            mostrarRespuesta.toggle()
        }
    }
    
    private func siguienteTarjeta() {
        if tarjetaActual < estructuras.count - 1 {
            withAnimation {
                tarjetaActual += 1
                mostrarRespuesta = false
            }
        }
    }
    
    private func tarjetaAnterior() {
        if tarjetaActual > 0 {
            withAnimation {
                tarjetaActual -= 1
                mostrarRespuesta = false
            }
        }
    }
    
    private func evaluarTarjeta(_ dificultad: DificultadTarjeta) {
        let estructura = estructuras[tarjetaActual]
        estudioManager.registrarEstudio(estructura.codigo, dificultad: dificultad)
        siguienteTarjeta()
    }
}

// Vista para botones de evaluación
struct EvaluacionButton: View {
    let texto: String
    let color: Color
    
    var body: some View {
        Text(texto)
            .fontWeight(.medium)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(8)
    }
}

// Vista básica para el modo de cuestionario
struct CuestionarioView: View {
    let dataManager: NeuroDataManager
    let estudioManager: EstudioManager
    let estructuras: [NodoAnatomico]
    
    @State private var preguntaActual = 0
    @State private var opcionesActuales: [NodoAnatomico] = []
    @State private var seleccionUsuario: String? = nil
    @State private var mostrarResultado = false
    @State private var puntuacion = 0
    
    var body: some View {
        VStack {
            if estructuras.isEmpty {
                Text("No hay suficientes estructuras para generar un cuestionario")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if preguntaActual >= 10 || preguntaActual >= estructuras.count {
                // Final del cuestionario
                VStack(spacing: 20) {
                    Text("¡Cuestionario completado!")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Tu puntuación: \(puntuacion) / \(preguntaActual)")
                        .font(.title2)
                    
                    Text("Acierto: \(Int((Double(puntuacion) / Double(preguntaActual)) * 100))%")
                        .font(.headline)
                        .foregroundColor(
                            puntuacion > preguntaActual / 2 ? .green : .orange
                        )
                    
                    Button(action: reiniciarCuestionario) {
                        Text("Comenzar Nuevo Cuestionario")
                            .fontWeight(.semibold)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.top, 30)
                }
            } else {
                // Contenido del cuestionario
                VStack(spacing: 20) {
                    // Progreso
                    ProgressView(value: Double(preguntaActual), total: Double(min(10, estructuras.count)))
                        .padding(.horizontal)
                    
                    Text("Pregunta \(preguntaActual + 1) de \(min(10, estructuras.count))")
                        .font(.callout)
                        .foregroundColor(.secondary)
                    
                    // La pregunta actual
                    VStack(alignment: .leading, spacing: 15) {
                        Text("¿Cuál estructura corresponde a esta descripción?")
                            .font(.headline)
                        
                        Text(opcionesActuales.first?.descripcion ?? "")
                            .padding()
                            #if os(macOS)
                            .background(Color(NSColor.controlBackgroundColor).opacity(0.8))
                            #else
                            .background(Color(.systemGray6))
                            #endif
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    
                    // Opciones
                    ForEach(opcionesActuales, id: \.id) { opcion in
                        Button(action: {
                            seleccionarOpcion(opcion.codigo)
                        }) {
                            HStack {
                                Text(opcion.nombreEspanol)
                                    .fontWeight(.medium)
                                Spacer()
                                
                                if mostrarResultado {
                                    if esRespuestaCorrecta(opcion.codigo) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                    } else if seleccionUsuario == opcion.codigo {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                            .padding()
                            .background(
                                colorFondo(para: opcion.codigo)
                            )
                            .foregroundColor(
                                seleccionUsuario == opcion.codigo && mostrarResultado ? .white : .primary
                            )
                            .cornerRadius(8)
                        }
                        .disabled(mostrarResultado)
                    }
                    .padding(.horizontal)
                    
                    // Botón para continuar
                    if mostrarResultado {
                        Button(action: siguientePregunta) {
                            Text("Siguiente")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                    }
                }
                .onAppear {
                    if opcionesActuales.isEmpty {
                        generarPregunta()
                    }
                }
            }
        }
    }
    
    // Genera una nueva pregunta con opciones
    private func generarPregunta() {
        // Asegurar que tengamos suficientes estructuras
        guard estructuras.count >= 4 else { return }
        
        // Seleccionar estructura para la pregunta
        let objetivo = estructuras[preguntaActual]
        
        // Generar opciones aleatorias
        var opciones = [objetivo]
        var estructurasRestantes = estructuras.filter { $0.codigo != objetivo.codigo }
        estructurasRestantes.shuffle()
        
        // Añadir 3 opciones adicionales
        for i in 0..<min(3, estructurasRestantes.count) {
            opciones.append(estructurasRestantes[i])
        }
        
        // Mezclar las opciones
        opciones.shuffle()
        opcionesActuales = opciones
        
        // Reiniciar estado
        seleccionUsuario = nil
        mostrarResultado = false
    }
    
    // Maneja la selección de una opción
    private func seleccionarOpcion(_ codigo: String) {
        seleccionUsuario = codigo
        mostrarResultado = true
        
        if esRespuestaCorrecta(codigo) {
            puntuacion += 1
            
            // Registrar como estudio fácil
            if let estructura = opcionesActuales.first {
                estudioManager.registrarEstudio(estructura.codigo, dificultad: .facil)
            }
        } else {
            // Registrar como estudio difícil
            if let estructura = opcionesActuales.first {
                estudioManager.registrarEstudio(estructura.codigo, dificultad: .dificil)
            }
        }
    }
    
    // Verifica si la opción seleccionada es correcta
    private func esRespuestaCorrecta(_ codigo: String) -> Bool {
        return codigo == opcionesActuales.first?.codigo
    }
    
    // Color de fondo para cada opción según el estado
    private func colorFondo(para codigo: String) -> Color {
        if !mostrarResultado {
            return seleccionUsuario == codigo ? Color.blue.opacity(0.3) :
            #if os(macOS)
            Color(NSColor.controlBackgroundColor)
            #else
            Color(.systemGray6)
            #endif
        } else {
            if esRespuestaCorrecta(codigo) {
                return Color.green.opacity(0.3)
            } else if seleccionUsuario == codigo {
                return Color.red.opacity(0.3)
            } else {
                #if os(macOS)
                return Color(NSColor.controlBackgroundColor)
                #else
                return Color(.systemGray6)
                #endif
            }
        }
    }
    
    // Avanza a la siguiente pregunta
    private func siguientePregunta() {
        preguntaActual += 1
        generarPregunta()
    }
    
    // Reinicia el cuestionario
    private func reiniciarCuestionario() {
        preguntaActual = 0
        puntuacion = 0
        opcionesActuales = []
        generarPregunta()
    }
}

// Vista básica para el modo de asociaciones
struct AsociacionesView: View {
    let dataManager: NeuroDataManager
    let estudioManager: EstudioManager
    let estructuras: [NodoAnatomico]
    
    @State private var itemsIzquierda: [Item] = []
    @State private var itemsDerecha: [Item] = []
    @State private var conexiones: [Conexion] = []
    @State private var itemSeleccionado: UUID? = nil
    @State private var ejercicioCompletado = false
    @State private var puntuacion = 0
    
    // Estructura para los ítems a conectar
    struct Item: Identifiable {
        let id = UUID()
        let codigo: String
        let texto: String
        let esNombre: Bool
    }
    
    // Estructura para las conexiones entre ítems
    struct Conexion: Identifiable {
        let id = UUID()
        let idIzquierda: UUID
        let idDerecha: UUID
        var correcta: Bool = false
    }
    
    var body: some View {
        VStack {
            if estructuras.isEmpty {
                Text("No hay suficientes estructuras para generar ejercicios de asociación")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if ejercicioCompletado {
                // Resultados finales
                VStack(spacing: 20) {
                    Text("¡Ejercicio completado!")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Tu puntuación: \(puntuacion) / \(itemsIzquierda.count)")
                        .font(.title2)
                    
                    Text("Acierto: \(Int((Double(puntuacion) / Double(itemsIzquierda.count)) * 100))%")
                        .font(.headline)
                        .foregroundColor(
                            puntuacion > itemsIzquierda.count / 2 ? .green : .orange
                        )
                    
                    Button(action: reiniciarEjercicio) {
                        Text("Nuevo Ejercicio")
                            .fontWeight(.semibold)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.top, 30)
                }
            } else {
                // Ejercicio de asociaciones
                VStack {
                    Text("Conecta cada estructura con su función")
                        .font(.headline)
                        .padding(.bottom)
                    
                    HStack(alignment: .top, spacing: 40) {
                        // Columna izquierda (nombres)
                        VStack(spacing: 10) {
                            ForEach(itemsIzquierda) { item in
                                ItemView(
                                    item: item,
                                    isSelected: itemSeleccionado == item.id,
                                    onTap: { itemTapped(item) }
                                )
                            }
                        }
                        .frame(width: 140)
                        
                        // Zona de conexiones
                        ZStack {
                            // Dibujar las conexiones
                            ForEach(conexiones) { conexion in
                                ConexionView(
                                    conexion: conexion,
                                    items: itemsIzquierda + itemsDerecha
                                )
                            }
                        }
                        .frame(width: 60)
                        
                        // Columna derecha (funciones)
                        VStack(spacing: 10) {
                            ForEach(itemsDerecha) { item in
                                ItemView(
                                    item: item,
                                    isSelected: itemSeleccionado == item.id,
                                    onTap: { itemTapped(item) }
                                )
                            }
                        }
                        .frame(width: 140)
                    }
                    .padding()
                    
                    // Botón para verificar respuestas
                    if conexiones.count == itemsIzquierda.count {
                        Button(action: verificarRespuestas) {
                            Text("Verificar")
                                .fontWeight(.semibold)
                                .frame(width: 200)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding(.top, 20)
                    }
                }
                .onAppear {
                    if itemsIzquierda.isEmpty {
                        generarEjercicio()
                    }
                }
            }
        }
    }
    
    // Vista para un ítem individual
    struct ItemView: View {
        let item: Item
        let isSelected: Bool
        let onTap: () -> Void
        
        var body: some View {
            Text(item.texto)
                .font(.footnote)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    isSelected ? Color.blue.opacity(0.3) :
                    #if os(macOS)
                    Color(NSColor.controlBackgroundColor)
                    #else
                    Color(.systemGray6)
                    #endif
                )
                .cornerRadius(8)
                .onTapGesture(perform: onTap)
        }
    }
    
    // Vista para una conexión entre ítems
    struct ConexionView: View {
        let conexion: Conexion
        let items: [Item]
        
        var body: some View {
            GeometryReader { geometry in
                Path { path in
                    guard let itemIzq = items.first(where: { $0.id == conexion.idIzquierda }),
                          let itemDer = items.first(where: { $0.id == conexion.idDerecha }),
                          let indexIzq = items.firstIndex(where: { $0.id == conexion.idIzquierda }),
                          let indexDer = items.firstIndex(where: { $0.id == conexion.idDerecha }) else {
                        return
                    }
                    
                    // Calcular posiciones
                    let startY = CGFloat(indexIzq) * 36 + 18
                    let endY = CGFloat(indexDer) * 36 + 18
                    
                    // Dibujar línea
                    path.move(to: CGPoint(x: 0, y: startY))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: endY))
                }
                .stroke(
                    conexion.correcta ? Color.green : Color.blue,
                    style: StrokeStyle(lineWidth: 2, lineCap: .round)
                )
            }
        }
    }
    
    // Genera un nuevo ejercicio de asociación
    private func generarEjercicio() {
        guard estructuras.count >= 5 else { return }
        
        // Seleccionar estructuras aleatorias (máximo 5)
        var estructurasEjercicio = estructuras.shuffled().prefix(5).map { $0 }
        
        // Crear ítems para ambas columnas
        itemsIzquierda = estructurasEjercicio.map { estructura in
            Item(codigo: estructura.codigo, texto: estructura.nombreEspanol, esNombre: true)
        }
        
        // Mezclar el orden de las funciones
        estructurasEjercicio.shuffle()
        
        itemsDerecha = estructurasEjercicio.map { estructura in
            Item(codigo: estructura.codigo, texto: estructura.funciones.first ?? "", esNombre: false)
        }
        
        // Reiniciar estado
        conexiones = []
        itemSeleccionado = nil
        ejercicioCompletado = false
        puntuacion = 0
    }
    
    // Maneja el tap en un ítem
    private func itemTapped(_ item: Item) {
        // Si no hay ítem seleccionado, seleccionar este
        if itemSeleccionado == nil {
            itemSeleccionado = item.id
            return
        }
        
        // Si el mismo ítem está seleccionado, deseleccionar
        if itemSeleccionado == item.id {
            itemSeleccionado = nil
            return
        }
        
        // Si ya hay un ítem seleccionado, intentar crear una conexión
        guard let idSeleccionado = itemSeleccionado else { return }
        
        // Verificar que un ítem es de la izquierda y otro de la derecha
        let itemSeleccionadoObj = (itemsIzquierda + itemsDerecha).first { $0.id == idSeleccionado }!
        
        if itemSeleccionadoObj.esNombre == item.esNombre {
            // No permitir conexiones dentro de la misma columna
            itemSeleccionado = item.id
            return
        }
        
        // Determinar qué ítem va a la izquierda y cuál a la derecha
        let idIzquierda = itemSeleccionadoObj.esNombre ? idSeleccionado : item.id
        let idDerecha = itemSeleccionadoObj.esNombre ? item.id : idSeleccionado
        
        // Verificar si ya existe una conexión para estos ítems
        let yaConectadoIzq = conexiones.contains { $0.idIzquierda == idIzquierda }
        let yaConectadoDer = conexiones.contains { $0.idDerecha == idDerecha }
        
        // Eliminar conexiones existentes si las hay
        if yaConectadoIzq {
            conexiones.removeAll { $0.idIzquierda == idIzquierda }
        }
        
        if yaConectadoDer {
            conexiones.removeAll { $0.idDerecha == idDerecha }
        }
        
        // Crear nueva conexión
        let nuevaConexion = Conexion(idIzquierda: idIzquierda, idDerecha: idDerecha)
        conexiones.append(nuevaConexion)
        
        // Deseleccionar
        itemSeleccionado = nil
    }
    
    // Verifica las respuestas y marca las correctas
    private func verificarRespuestas() {
        var aciertos = 0
        
        // Comprobar cada conexión
        for i in 0..<conexiones.count {
            let conexion = conexiones[i]
            
            // Obtener los códigos de ambos ítems
            let codigoIzquierda = itemsIzquierda.first { $0.id == conexion.idIzquierda }?.codigo ?? ""
            let codigoDerecha = itemsDerecha.first { $0.id == conexion.idDerecha }?.codigo ?? ""
            
            // Verificar si coinciden
            if codigoIzquierda == codigoDerecha {
                conexiones[i].correcta = true
                aciertos += 1
                
                // Registrar como estudio exitoso
                estudioManager.registrarEstudio(codigoIzquierda, dificultad: .facil)
            } else {
                // Registrar como estudio fallido
                estudioManager.registrarEstudio(codigoIzquierda, dificultad: .dificil)
            }
        }
        
        puntuacion = aciertos
        
        // Marcar ejercicio como completado después de un tiempo
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            ejercicioCompletado = true
        }
    }
    
    // Reinicia el ejercicio
    private func reiniciarEjercicio() {
        itemsIzquierda = []
        itemsDerecha = []
        conexiones = []
        generarEjercicio()
    }
}

// Manager para el sistema de estudio
class EstudioManager: ObservableObject {
    @Published var sesionesEstudio: [SesionEstudio] = []
    @Published var registroEstudio: [String: [RegistroEstudio]] = [:]
    
    // Estructura para una sesión de estudio
    struct SesionEstudio: Identifiable, Codable {
        let id = UUID()
        let fecha: Date
        var estructurasEstudiadas: Int
        var dificultadesPorEstructura: [String: DificultadTarjeta]
    }
    
    // Estructura para el registro de estudio de una estructura
    struct RegistroEstudio: Identifiable, Codable {
        let id = UUID()
        let fecha: Date
        let dificultad: DificultadTarjeta
        let intervalo: Int // Días para el próximo repaso
    }
    
    init() {
        cargarDatos()
    }
    
    // Registra el estudio de una estructura
    func registrarEstudio(_ codigoEstructura: String, dificultad: DificultadTarjeta) {
        // Crear sesión actual si no existe
        if sesionesEstudio.isEmpty || Calendar.current.isDateInToday(sesionesEstudio.last?.fecha ?? Date.distantPast) == false {
            sesionesEstudio.append(SesionEstudio(
                fecha: Date(),
                estructurasEstudiadas: 0,
                dificultadesPorEstructura: [:]
            ))
        }
        
        // Actualizar la sesión actual
        if var sesionActual = sesionesEstudio.last {
            if sesionActual.dificultadesPorEstructura[codigoEstructura] == nil {
                sesionActual.estructurasEstudiadas += 1
            }
            sesionActual.dificultadesPorEstructura[codigoEstructura] = dificultad
            
            // Actualizar en el array
            if let index = sesionesEstudio.count - 1 as? Int, index >= 0 {
                sesionesEstudio[index] = sesionActual
            }
        }
        
        // Calcular intervalo para el próximo repaso
        let intervalo = calcularIntervalo(codigoEstructura, dificultad: dificultad)
        
        // Registrar el estudio
        let nuevoRegistro = RegistroEstudio(
            fecha: Date(),
            dificultad: dificultad,
            intervalo: intervalo
        )
        
        // Actualizar registros
        if registroEstudio[codigoEstructura] == nil {
            registroEstudio[codigoEstructura] = []
        }
        registroEstudio[codigoEstructura]?.append(nuevoRegistro)
        
        // Guardar datos
        guardarDatos()
    }
    
    // Calcula el intervalo para el próximo repaso basado en el algoritmo SM-2 simplificado
    private func calcularIntervalo(_ codigoEstructura: String, dificultad: DificultadTarjeta) -> Int {
        // Si no hay registros previos
        guard let registros = registroEstudio[codigoEstructura], !registros.isEmpty else {
            // Intervalo inicial según dificultad
            switch dificultad {
            case .dificil: return 1
            case .medio: return 3
            case .facil: return 5
            }
        }
        
        // Obtener el último intervalo
        let ultimoIntervalo = registros.last?.intervalo ?? 1
        
        // Calcular nuevo intervalo según dificultad
        switch dificultad {
        case .dificil: return 1 // Resetear a 1 día
        case .medio: return ultimoIntervalo // Mantener el mismo intervalo
        case .facil: return ultimoIntervalo * 2 // Duplicar el intervalo
        }
    }
    
    // Ordena las estructuras por prioridad de estudio
    func ordenarPorPrioridad(_ estructuras: [NodoAnatomico]) -> [NodoAnatomico] {
        return estructuras.sorted { estructura1, estructura2 in
            let prioridad1 = calcularPrioridad(estructura1.codigo)
            let prioridad2 = calcularPrioridad(estructura2.codigo)
            return prioridad1 > prioridad2
        }
    }
    
    // Calcula la prioridad de una estructura para estudio
    private func calcularPrioridad(_ codigo: String) -> Double {
        // Si no hay registros, alta prioridad
        guard let registros = registroEstudio[codigo], !registros.isEmpty else {
            return 100.0
        }
        
        // Obtener último registro
        guard let ultimoRegistro = registros.last else {
            return 100.0
        }
        
        // Calcular días transcurridos desde el último estudio
        let diasTranscurridos = Calendar.current.dateComponents([.day], from: ultimoRegistro.fecha, to: Date()).day ?? 0
        
        // Si ha pasado el intervalo, alta prioridad
        if diasTranscurridos >= ultimoRegistro.intervalo {
            return Double(diasTranscurridos - ultimoRegistro.intervalo + 100)
        }
        
        // Si no ha pasado el intervalo, baja prioridad
        return Double(diasTranscurridos) / Double(ultimoRegistro.intervalo) * 100
    }
    
    // Reinicia la sesión actual
    func reiniciarSesion() {
        if !sesionesEstudio.isEmpty && Calendar.current.isDateInToday(sesionesEstudio.last?.fecha ?? Date.distantPast) {
            sesionesEstudio.removeLast()
        }
    }
    
    // Guarda los datos localmente
    private func guardarDatos() {
        // Esta implementación sería con UserDefaults, se podría expandir a usar persistencia más robusta
        // como Core Data o un archivo JSON
    }
    
    // Carga los datos guardados
    private func cargarDatos() {
        // Esta implementación sería con UserDefaults, se podría expandir a usar persistencia más robusta
    }
}

// Niveles de dificultad para las tarjetas
enum DificultadTarjeta: String, Codable {
    case dificil
    case medio
    case facil
}

// Vista previa
struct EstudioView_Previews: PreviewProvider {
    static var previews: some View {
        EstudioView(dataManager: NeuroDataManager())
    }
}
