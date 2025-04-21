//
//  ProgresoView.swift
//  NeuroRAD
//
//  Created by Rodrigo Munoz on 21-04-25.
//


//
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
                    
                    // Estadísticas generales
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
                }
                .padding(.vertical)
            }
            .navigationTitle("Tu Progreso")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Aquí se implementaría la exportación de datos
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
    }
    
    // MARK: - Componentes de la vista
    
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
                            .foregroundColor(Color(.systemGray5))
                        
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
                                .frame(width: (geometry.size.width - CGFloat(datos.count) * 5) / CGFloat(datos.count),
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
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Estructuras de datos
    
    enum PeriodoAnalisis {
        case semana
        case mes
        case todo
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
    
    // MARK: - Métodos para cálculos
    
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
}

struct ProgresoView_Previews: PreviewProvider {
    static var previews: some View {
        ProgresoView(dataManager: NeuroDataManager())
    }
}