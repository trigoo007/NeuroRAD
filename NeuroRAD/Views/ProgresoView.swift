///
//  ProgresoView.swift
//  NeuroRAD
//
//  Created for NeuroRAD Project
//

import SwiftUI

struct ProgresoView: View {
    @ObservedObject var dataManager: NeuroDataManager
    @State private var estudioManager = EstudioManager()
    @State private var periodoSeleccionado: PeriodoAnalisis = .semana
    @State private var filtroSistema: SistemaNeurologico? = nil
    @State private var filtroCategoria: String? = nil
    @State private var textoFiltro: String = ""
    @State private var showingFilterSheet = false
    @State private var mostrarSoloCompletados = false
    
    // Colores para los niveles de progreso
    private let colorEstado: [EstadoEstudio: Color] = [
        .noIniciado: .red,
        .enProgreso: .orange,
        .completado: .green
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Selector de período
                    Picker("Período", selection: $periodoSeleccionado) {
                        Text("Última semana").tag(PeriodoAnalisis.semana)
                        Text("Último mes").tag(PeriodoAnalisis.mes)
                        Text("Todo").tag(PeriodoAnalisis.todo)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    // Barra de búsqueda
                    SearchBar(text: $textoFiltro, placeholder: "Buscar estructura...")
                        .padding(.horizontal)
                    
                    // Filtros activos
                    HStack {
                        if filtroSistema != nil || filtroCategoria != nil || mostrarSoloCompletados {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    if let sistema = filtroSistema {
                                        FilterChip(text: sistema.nombreCompleto) {
                                            withAnimation { filtroSistema = nil }
                                        }
                                    }
                                    
                                    if let categoria = filtroCategoria {
                                        FilterChip(text: CategoriasAnatomicas.nombreDescriptivo(categoria)) {
                                            withAnimation { filtroCategoria = nil }
                                        }
                                    }
                                    
                                    if mostrarSoloCompletados {
                                        FilterChip(text: "Completados") {
                                            withAnimation { mostrarSoloCompletados = false }
                                        }
                                    }
                                    
                                    Button(action: {
                                        withAnimation {
                                            filtroSistema = nil
                                            filtroCategoria = nil
                                            mostrarSoloCompletados = false
                                        }
                                    }) {
                                        Text("Limpiar filtros")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                    }
                                    .padding(.leading, 4)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal)
                            }
                        } else {
                            HStack {
                                Text("Sin filtros activos")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal)
                        }
                    }
                    
                    // Estadísticas generales
                    if !filtradoActivo() {
                        ProgresoStatsView(dataManager: dataManager)
                            .padding(.horizontal)
                            .padding(.vertical, 12)
                    }
                    
                    VStack(spacing: 15) {
                        HStack(spacing: 20) {
                            EstadisticaView(
                                valor: "\(sesionesEnPeriodo().count)",
                                titulo: "Sesiones",
                                icono: "calendar",
                                color: .blue
                            )
                            
                            EstadisticaView(
                                valor: "\(estructurasEstudiadasEnPeriodo())",
                                titulo: "Estructuras",
                                icono: "brain",
                                color: .purple
                            )
                        }
                        
                        HStack(spacing: 20) {
                            EstadisticaView(
                                valor: "\(porcentajeCobertura())%",
                                titulo: "Cobertura",
                                icono: "chart.pie",
                                color: .green
                            )
                            
                            EstadisticaView(
                                valor: "\(promedioRetencionEstimada())%",
                                titulo: "Retención",
                                icono: "brain.head.profile",
                                color: .orange
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    Divider()
                    
                    // Gráfico de actividad diaria
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Actividad diaria")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ActividadChart(datos: datosActividadDiaria())
                            .frame(height: 150)
                            .padding(.horizontal, 10)
                    }
                    
                    Divider()
                    
                    // Distribución por sistemas
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Distribución por sistemas")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(datosDistribucionSistemas(), id: \.sistema) { dato in
                            BarraProgresoView(
                                titulo: dato.sistema.nombreCompleto,
                                progreso: dato.porcentaje,
                                color: colorSistema(dato.sistema)
                            )
                            .padding(.horizontal)
                        }
                    }
                    
                    Divider()
                    
                    // Estructuras pendientes de repaso
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Estructuras a repasar")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if estructurasParaRepasar().isEmpty {
                            Text("¡Estás al día con tus repasos!")
                                .foregroundColor(.secondary)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    ForEach(estructurasParaRepasar(), id: \.id) { estructura in
                                        TarjetaRepasoView(estructura: estructura)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    // Lista de estructuras (si hay filtros activos)
                    if filtradoActivo() {
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Estructuras filtradas")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(nodosFiltrados(), id: \.id) { nodo in
                                NavigationLink(destination: EstructuraDetailView(estructura: nodo, dataManager: dataManager)) {
                                    EstadoEstudioRow(nodo: nodo, dataManager: dataManager)
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Tu Progreso")
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingFilterSheet = true }) {
                        Label("Filtrar", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
                #else
                ToolbarItem(placement: .automatic) {
                    Button(action: { showingFilterSheet = true }) {
                        Label("Filtrar", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
                #endif
            }
            .sheet(isPresented: $showingFilterSheet) {
                FiltrosView(
                    filtroSistema: $filtroSistema,
                    filtroCategoria: $filtroCategoria,
                    mostrarSoloCompletados: $mostrarSoloCompletados
                )
                .environmentObject(dataManager)
            }
        }
    }
    
    // MARK: - Enumeraciones y tipos
    
    enum EstadoEstudio {
        case noIniciado, enProgreso, completado
    }
    
    enum PeriodoAnalisis {
        case semana, mes, todo
    }
    
    struct DatoActividad: Identifiable {
        let id = UUID()
        let etiqueta: String
        let valor: Int
        let fecha: Date
    }
    
    struct DatoDistribucion: Identifiable {
        let id = UUID()
        let sistema: SistemaNeurologico
        let porcentaje: Double
    }
    
    // MARK: - Métodos auxiliares
    
    // Determina si hay filtros activos
    private func filtradoActivo() -> Bool {
        return filtroSistema != nil || filtroCategoria != nil || !textoFiltro.isEmpty || mostrarSoloCompletados
    }
    
    // Filtra los nodos según los criterios
    private func nodosFiltrados() -> [NodoAnatomico] {
        var nodos = Array(dataManager.nodos.values)
        
        // Filtro por texto
        if !textoFiltro.isEmpty {
            nodos = nodos.filter {
                $0.nombreEspanol.localizedCaseInsensitiveContains(textoFiltro) ||
                $0.nombreLatin.localizedCaseInsensitiveContains(textoFiltro) ||
                $0.idCode.localizedCaseInsensitiveContains(textoFiltro)
            }
        }
        
        // Filtro por sistema
        if let sistema = filtroSistema {
            nodos = nodos.filter { $0.sistema == sistema }
        }
        
        // Filtro por categoría
        if let categoria = filtroCategoria {
            nodos = nodos.filter { $0.categoria == categoria }
        }
        
        // Filtro por completados
        if mostrarSoloCompletados {
            nodos = nodos.filter { dataManager.estadoEstudio(codigo: $0.codigo) == .completado }
        }
        
        return nodos.sorted { $0.nombreEspanol < $1.nombreEspanol }
    }
    
    // Obtiene las sesiones dentro del período seleccionado
    private func sesionesEnPeriodo() -> [EstudioManager.SesionEstudio] {
        let sesiones = estudioManager.sesionesEstudio
        
        switch periodoSeleccionado {
        case .semana:
            let fechaInicio = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            return sesiones.filter { $0.fecha >= fechaInicio }
        case .mes:
            let fechaInicio = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
            return sesiones.filter { $0.fecha >= fechaInicio }
        case .todo:
            return sesiones
        }
    }
    
    // Calcula el número de estructuras estudiadas en el período
    private func estructurasEstudiadasEnPeriodo() -> Int {
        let sesiones = sesionesEnPeriodo()
        let codigosEstudiados = Set(sesiones.flatMap { $0.dificultadesPorEstructura.keys })
        return codigosEstudiados.count
    }
    
    // Calcula el porcentaje de cobertura (estructuras estudiadas / total)
    private func porcentajeCobertura() -> Int {
        let total = dataManager.nodos.count
        if total == 0 { return 0 }
        
        let estudiadas = estructurasEstudiadasEnPeriodo()
        return Int((Double(estudiadas) / Double(total)) * 100)
    }
    
    // Estima el porcentaje de retención basado en dificultades
    private func promedioRetencionEstimada() -> Int {
        let registros = estudioManager.registroEstudio
        if registros.isEmpty { return 0 }
        
        var totalPuntos = 0
        var totalEstructuras = 0
        
        for (_, estudios) in registros {
            if let ultimo = estudios.last {
                switch ultimo.dificultad {
                case .facil: totalPuntos += 100
                case .medio: totalPuntos += 70
                case .dificil: totalPuntos += 30
                }
                totalEstructuras += 1
            }
        }
        
        if totalEstructuras == 0 { return 0 }
        return totalPuntos / totalEstructuras
    }
    
    // Genera datos para el gráfico de actividad diaria
    private func datosActividadDiaria() -> [DatoActividad] {
        let calendar = Calendar.current
        var resultado: [DatoActividad] = []
        
        // Determinar número de días según período
        let numDias: Int
        switch periodoSeleccionado {
        case .semana: numDias = 7
        case .mes: numDias = 30
        case .todo: numDias = 90 // Limitamos a 90 días para todo el histórico
        }
        
        // Generar datos para cada día
        for i in 0..<numDias {
            let fecha = calendar.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            let dia = calendar.component(.day, from: fecha)
            
            // Contar estructuras estudiadas este día
            let estructurasHoy = estudioManager.sesionesEstudio.filter {
                calendar.isDate($0.fecha, inSameDayAs: fecha)
            }.flatMap { $0.dificultadesPorEstructura.keys }
            
            resultado.append(DatoActividad(
                etiqueta: "\(dia)",
                valor: estructurasHoy.count,
                fecha: fecha
            ))
        }
        
        return resultado.reversed()
    }
    
    // Genera datos de distribución por sistemas
    private func datosDistribucionSistemas() -> [DatoDistribucion] {
        var resultado: [DatoDistribucion] = []
        
        for sistema in SistemaNeurologico.allCases {
            // Total de estructuras del sistema
            let estructurasSistema = dataManager.buscarNodosPorSistema(sistema)
            if estructurasSistema.isEmpty { continue }
            
            // Estructuras estudiadas de este sistema
            let codigosEstudiadosSistema = estudioManager.registroEstudio.keys.filter { codigo in
                if let nodo = dataManager.buscarNodo(codigo: codigo) {
                    return nodo.sistema == sistema
                }
                return false
            }
            
            // Calcular porcentaje
            let porcentaje = (Double(codigosEstudiadosSistema.count) / Double(estructurasSistema.count)) * 100
            
            resultado.append(DatoDistribucion(
                sistema: sistema,
                porcentaje: porcentaje
            ))
        }
        
        return resultado.sorted { $0.porcentaje > $1.porcentaje }
    }
    
    // Devuelve estructuras que necesitan repaso
    private func estructurasParaRepasar() -> [NodoAnatomico] {
        var estructuras: [NodoAnatomico] = []
        
        for (codigo, registros) in estudioManager.registroEstudio {
            if let ultimoRegistro = registros.last,
               let estructura = dataManager.buscarNodo(codigo: codigo) {
                
                // Calcular días transcurridos desde el último estudio
                let diasTranscurridos = Calendar.current.dateComponents([.day], from: ultimoRegistro.fecha, to: Date()).day ?? 0
                
                // Si ha pasado el intervalo, añadir a la lista
                if diasTranscurridos >= ultimoRegistro.intervalo {
                    estructuras.append(estructura)
                }
            }
        }
        
        // Limitar a 10 estructuras y ordenar por prioridad
        return estructuras
            .sorted { e1, e2 in
                let r1 = estudioManager.registroEstudio[e1.codigo]?.last
                let r2 = estudioManager.registroEstudio[e2.codigo]?.last
                
                let d1 = Calendar.current.dateComponents([.day], from: r1?.fecha ?? Date.distantPast, to: Date()).day ?? 0
                let d2 = Calendar.current.dateComponents([.day], from: r2?.fecha ?? Date.distantPast, to: Date()).day ?? 0
                
                return d1 > d2
            }
            .prefix(10)
            .map { $0 }
    }
    
    // Color para cada sistema
    private func colorSistema(_ sistema: SistemaNeurologico) -> Color {
        switch sistema {
        case .centralSC: return .blue
        case .perifericoSP: return .green
        case .vascularSV: return .red
        case .espaciosSE: return .purple
        }
    }
    
    // MARK: - Componentes de la vista
    
    // Vista con estadísticas de progreso
    struct ProgresoStatsView: View {
        @ObservedObject var dataManager: NeuroDataManager
        
        var body: some View {
            VStack(spacing: 12) {
                // Progreso general
                HStack {
                    Text("Progreso general")
                        .font(.headline)
                    
                    Spacer()
                    
                    Text("\(porcentajeProgreso())%")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
                
                // Barra de progreso
                GeometryReader { geometry in
                    HStack(spacing: 3) {
                        // Completados
                        Rectangle()
                            .fill(Color.green)
                            .frame(width: calcularAnchoBar(count: contarPorEstado(.completado), totalWidth: geometry.size.width))
                        
                        // En progreso
                        Rectangle()
                            .fill(Color.orange)
                            .frame(width: calcularAnchoBar(count: contarPorEstado(.enProgreso), totalWidth: geometry.size.width))
                        
                        // No iniciados
                        Rectangle()
                            .fill(Color.systemGray5)
                            .frame(width: calcularAnchoBar(count: contarPorEstado(.noIniciado), totalWidth: geometry.size.width))
                    }
                }
                .frame(height: 12)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                
                // Leyenda
                HStack(spacing: 16) {
                    LeyendaItem(color: .green, text: "Completados: \(contarPorEstado(.completado))")
                    LeyendaItem(color: .orange, text: "En progreso: \(contarPorEstado(.enProgreso))")
                    LeyendaItem(color: .red, text: "No iniciados: \(contarPorEstado(.noIniciado))")
                }
                .font(.caption)
                .padding(.top, 4)
            }
            .padding()
            .background(Color.systemGray6)
            .cornerRadius(12)
        }
        
        // Calcula el porcentaje de progreso
        private func porcentajeProgreso() -> Int {
            let total = dataManager.nodos.count
            if total == 0 { return 0 }
            
            let completados = contarPorEstado(.completado)
            let enProgreso = contarPorEstado(.enProgreso)
            
            // Cada en progreso cuenta como medio completado
            let ponderado = completados + (enProgreso / 2)
            return Int((Double(ponderado) / Double(total)) * 100)
        }
        
        // Cuenta los nodos por estado
        private func contarPorEstado(_ estado: EstadoEstudio) -> Int {
            return dataManager.nodos.values.filter {
                // Implementación real
                dataManager.estadoEstudio(codigo: $0.codigo) == estado
            }.count
        }
        
        // Calcula el ancho proporcional de cada segmento de la barra
        private func calcularAnchoBar(count: Int, totalWidth: CGFloat) -> CGFloat {
            let total = dataManager.nodos.count
            if total == 0 { return 0 }
            
            let proporcion = CGFloat(count) / CGFloat(total)
            return totalWidth * proporcion
        }
    }
    
    // Item de leyenda para las estadísticas
    struct LeyendaItem: View {
        let color: Color
        let text: String
        
        var body: some View {
            HStack(spacing: 4) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                
                Text(text)
            }
        }
    }
    
    // Vista para mostrar una estadística individual
    struct EstadisticaView: View {
        let valor: String
        let titulo: String
        let icono: String
        let color: Color
        
        var body: some View {
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: icono)
                        .font(.title3)
                        .foregroundColor(color)
                    
                    Spacer()
                }
                
                Text(valor)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(titulo)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(color.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    // Vista para mostrar una barra de progreso
    struct BarraProgresoView: View {
        let titulo: String
        let progreso: Double // 0-100
        let color: Color
        
        var body: some View {
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(titulo)
                        .font(.callout)
                    
                    Spacer()
                    
                    Text("\(Int(progreso))%")
                        .font(.callout)
                        .fontWeight(.medium)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Barra de fondo
                        Rectangle()
                            .frame(width: geometry.size.width, height: 10)
                            .opacity(0.3)
                            .foregroundColor(Color.systemGray5)
                        
                        // Barra de progreso
                        Rectangle()
                            .frame(width: min(CGFloat(progreso) * geometry.size.width / 100, geometry.size.width), height: 10)
                            .foregroundColor(color)
                    }
                    .cornerRadius(5)
                }
                .frame(height: 10)
            }
        }
    }
    
    // Vista para el gráfico de actividad
    struct ActividadChart: View {
        let datos: [DatoActividad]
        
        var body: some View {
            GeometryReader { geometry in
                HStack(alignment: .bottom, spacing: 5) {
                    ForEach(datos) { dato in
                        VStack {
                            // Barra
                            Rectangle()
                                .fill(dato.valor > 0 ? Color.blue : Color.clear)
                                .frame(width: (geometry.size.width - CGFloat(datos.count) * 5) / CGFloat(max(1, datos.count)),
                                       height: calculateHeight(dato.valor, geometry: geometry))
                            
                            // Etiqueta
                            Text(dato.etiqueta)
                                .font(.system(size: 8))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        
        // Calcular altura proporcional
        private func calculateHeight(_ valor: Int, geometry: GeometryProxy) -> CGFloat {
            let maxValor = datos.map { $0.valor }.max() ?? 1
            let maxHeight = geometry.size.height - 20 // Espacio para etiquetas
            
            if maxValor == 0 {
                return 0
            }
            
            return CGFloat(valor) / CGFloat(maxValor) * maxHeight
        }
    }
    
    // Fila para mostrar estado de estudio de un nodo
    struct EstadoEstudioRow: View {
        let nodo: NodoAnatomico
        @ObservedObject var dataManager: NeuroDataManager
        
        var body: some View {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(nodo.nombreEspanol)
                        .font(.system(size: 16, weight: .medium))
                    
                    Text(nodo.nombreLatin)
                        .font(.system(size: 14, weight: .regular))
                        .italic()
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                EstadoIndicator(estado: dataManager.estadoEstudio(codigo: nodo.codigo))
            }
            .padding(.vertical, 4)
            .background(Color.systemBackground)
            .cornerRadius(8)
        }
    }
    
    // Indicador visual de estado de estudio
    struct EstadoIndicator: View {
        let estado: EstadoEstudio
        
        var body: some View {
            HStack {
                Image(systemName: iconoEstado)
                    .foregroundColor(.white)
                    .padding(4)
                    .background(
                        Circle()
                            .fill(colorEstado)
                            .frame(width: 24, height: 24)
                    )
                
                Text(textoEstado)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
        
        private var iconoEstado: String {
            switch estado {
            case .noIniciado: return "xmark"
            case .enProgreso: return "ellipsis"
            case .completado: return "checkmark"
            }
        }
        
        private var colorEstado: Color {
            switch estado {
            case .noIniciado: return .red
            case .enProgreso: return .orange
            case .completado: return .green
            }
        }
        
        private var textoEstado: String {
            switch estado {
            case .noIniciado: return "No iniciado"
            case .enProgreso: return "En progreso"
            case .completado: return "Completado"
            }
        }
    }
    
    // Vista para una tarjeta de repaso
    struct TarjetaRepasoView: View {
        let estructura: NodoAnatomico
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text(estructura.nombreEspanol)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(estructura.nombreLatin)
                    .font(.caption)
                    .italic()
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: {
                    // Navegar a la vista de estudio
                }) {
                    Text("Repasar")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding()
            .frame(width: 160, height: 140)
            .background(Color.systemGray6)
            .cornerRadius(12)
        }
    }
    
    // Vista para filtros
    struct FiltrosView: View {
        @Environment(\.presentationMode) var presentationMode
        @EnvironmentObject var dataManager: NeuroDataManager
        @Binding var filtroSistema: SistemaNeurologico?
        @Binding var filtroCategoria: String?
        @Binding var mostrarSoloCompletados: Bool
        
        var body: some View {
            NavigationView {
                List {
                    // Sección de filtro por sistemas
                    Section(header: Text("Sistemas anatómicos")) {
                        Button("Todos los sistemas") {
                            filtroSistema = nil
                            presentationMode.wrappedValue.dismiss()
                        }
                        
                        ForEach(SistemaNeurologico.allCases, id: \.self) { sistema in
                            Button(action: {
                                filtroSistema = sistema
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                HStack {
                                    Text(sistema.nombreCompleto)
                                    Spacer()
                                    if filtroSistema == sistema {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Sección de filtro por categorías
                    Section(header: Text("Categorías anatómicas")) {
                        Button("Todas las categorías") {
                            filtroCategoria = nil
                            presentationMode.wrappedValue.dismiss()
                        }
                        
                        ForEach(obtenerCategorias(), id: \.id) { categoria in
                            Button(action: {
                                filtroCategoria = categoria.id
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                HStack {
                                    Text(categoria.nombre)
                                    Spacer()
                                    if filtroCategoria == categoria.id {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Sección de filtro por estado
                    Section(header: Text("Estado de estudio")) {
                        Toggle("Mostrar solo completados", isOn: $mostrarSoloCompletados)
                    }
                }
                .listStyle(InsetListStyle())
                .navigationTitle("Filtros")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Cerrar") {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
            }
        }
        
        // Obtiene las categorías disponibles para filtrar
        private func obtenerCategorias() -> [CategoriaAnatomica] {
            var categorias: [CategoriaAnatomica] = []
            
            // Si hay un sistema seleccionado, mostrar solo sus categorías
            if let sistema = filtroSistema {
                // Obtener categorías existentes en los datos para este sistema
                let categoriasExistentes = Set(dataManager.nodos.values
                    .filter { $0.sistema == sistema }
                    .map { $0.categoria })
                
                // Crear objetos CategoriaAnatomica para cada categoría existente
                for categoriaID in categoriasExistentes {
                    categorias.append(
                        CategoriaAnatomica(
                            id: categoriaID,
                            nombre: CategoriasAnatomicas.nombreDescriptivo(categoriaID),
                            sistema: sistema
                        )
                    )
                }
            } else {
                // Sin sistema seleccionado, mostrar todas las categorías
                // Por simplicidad, usamos una lista predefinida
                categorias = [
                    CategoriaAnatomica(id: "SG", nombre: "Sustancia Gris", sistema: .centralSC),
                    CategoriaAnatomica(id: "SB", nombre: "Sustancia Blanca", sistema: .centralSC),
                    CategoriaAnatomica(id: "NUC", nombre: "Núcleos", sistema: .centralSC),
                    CategoriaAnatomica(id: "SF", nombre: "Surcos y Fisuras", sistema: .centralSC),
                    CategoriaAnatomica(id: "VT", nombre: "Sistema Ventricular", sistema: .centralSC),
                    CategoriaAnatomica(id: "CRB", nombre: "Cerebelo", sistema: .centralSC),
                    CategoriaAnatomica(id: "AR", nombre: "Arterias", sistema: .vascularSV),
                    CategoriaAnatomica(id: "VN", nombre: "Venas", sistema: .vascularSV)
                ]
            }
            
            return categorias.sorted { $0.nombre < $1.nombre }
        }
    }
    
    // Componente de filtro en forma de chip
    struct FilterChip: View {
        let text: String
        let onRemove: () -> Void
        
        var body: some View {
            HStack(spacing: 4) {
                Text(text)
                    .font(.caption)
                    .padding(.leading, 8)
                
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                }
                .padding(.trailing, 6)
            }
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color.blue.opacity(0.15))
            )
        }
    }
    
    // Componente de barra de búsqueda
    struct SearchBar: View {
        @Binding var text: String
        var placeholder: String = "Buscar..."
        
        var body: some View {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField(placeholder, text: $text)
                    .disableAutocorrection(true)
                
                if !text.isEmpty {
                    Button(action: {
                        text = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.systemGray6)
            )
        }
    }
}

// Extensión para el manejo de estado de estudio en NeuroDataManager
extension NeuroDataManager {
    func estadoEstudio(codigo: String) -> ProgresoView.EstadoEstudio {
        // Esta es una implementación para el ejemplo
        // En un caso real, se evaluaría el historial de estudio del nodo
        
        // Si existe algún registro para el nodo
        if let registros = estudioManager.registroEstudio[codigo], !registros.isEmpty {
            // Si tiene más de 3 registros y el último es "fácil", está completado
            if registros.count > 3 && registros.last?.dificultad == .facil {
                return .completado
            }
            return .enProgreso
        }
        
        return .noIniciado
    }
    
    // Propiedad para acceder al estudioManager
    private var estudioManager: EstudioManager {
        // Esto es simplificado para fines del ejemplo
        // En una implementación real, este manager debería ser accesible de otra manera
        return EstudioManager()
    }
}
