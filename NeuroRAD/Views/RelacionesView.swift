//
//  RelacionesView.swift
//  NeuroRAD
//
//  Created by Rodrigo Munoz on 21-04-25.
//


//
//  RelacionesView.swift
//  NeuroRAD
//
//  Created for NeuroRAD Project
//

import SwiftUI

struct RelacionesView: View {
    @ObservedObject var dataManager: NeuroDataManager
    @State private var estructuraSeleccionada: NodoAnatomico?
    @State private var tipoRelacion: TipoRelacion?
    @State private var busqueda: String = ""
    
    var body: some View {
        NavigationView {
            VStack {
                // Barra de búsqueda
                SearchBar(text: $busqueda)
                    .padding(.horizontal)
                
                // Selector de tipo de relación
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        RelacionFilterChip(
                            texto: "Todas",
                            isSelected: tipoRelacion == nil,
                            action: { tipoRelacion = nil }
                        )
                        
                        ForEach(TipoRelacion.allCases, id: \.self) { tipo in
                            RelacionFilterChip(
                                texto: tipo.descripcion,
                                isSelected: tipoRelacion == tipo,
                                action: { tipoRelacion = tipo }
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                
                if let estructura = estructuraSeleccionada {
                    // Vista detallada de una estructura y sus relaciones
                    ScrollView {
                        VStack(alignment: .leading, spacing: 15) {
                            // Encabezado con botón para volver
                            HStack {
                                Button(action: { estructuraSeleccionada = nil }) {
                                    HStack {
                                        Image(systemName: "chevron.left")
                                        Text("Volver")
                                    }
                                    .font(.callout)
                                    .foregroundColor(.blue)
                                }
                                
                                Spacer()
                            }
                            .padding(.bottom, 10)
                            
                            // Información de la estructura
                            EstructuraHeader(estructura: estructura)
                                .padding(.vertical)
                            
                            Divider()
                            
                            // Relaciones desde esta estructura
                            relacionesDesdeView(estructura)
                            
                            Divider()
                            
                            // Relaciones hacia esta estructura
                            relacionesHaciaView(estructura)
                        }
                        .padding()
                    }
                } else {
                    // Lista de estructuras
                    estructurasList
                }
            }
            .navigationTitle("Relaciones Anatómicas")
        }
    }
    
    // Vista para la lista de estructuras filtradas
    private var estructurasList: some View {
        List {
            ForEach(estructurasFiltradas(), id: \.id) { estructura in
                Button(action: { estructuraSeleccionada = estructura }) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(estructura.nombreEspanol)
                            .font(.headline)
                        
                        Text(estructura.nombreLatin)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .italic()
                        
                        // Mostrar cantidad de relaciones
                        HStack {
                            let relacionesDesde = dataManager.buscarRelacionesDesdeNodo(estructura.codigo)
                            let relacionesHacia = dataManager.buscarRelacionesHaciaNodo(estructura.codigo)
                            
                            if relacionesDesde.isEmpty && relacionesHacia.isEmpty {
                                Text("Sin relaciones")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("\(relacionesDesde.count + relacionesHacia.count) relaciones")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.top, 2)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
    
    // Vista para mostrar relaciones desde la estructura seleccionada
    @ViewBuilder
    private func relacionesDesdeView(_ estructura: NodoAnatomico) -> some View {
        let relacionesFiltradas = dataManager.buscarRelacionesDesdeNodo(estructura.codigo)
            .filter { tipoRelacion == nil || $0.tipo == tipoRelacion }
        
        VStack(alignment: .leading, spacing: 12) {
            Text("Esta estructura afecta a:")
                .font(.headline)
                .padding(.vertical, 4)
            
            if relacionesFiltradas.isEmpty {
                Text("No se han definido relaciones de salida" + (tipoRelacion != nil ? " de este tipo" : ""))
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(relacionesFiltradas, id: \.id) { relacion in
                    if let nodoDestino = dataManager.buscarNodo(codigo: relacion.idDestino) {
                        RelacionRow(
                            relacion: relacion,
                            nodoRelacionado: nodoDestino,
                            esDestino: true,
                            onTap: { estructuraSeleccionada = nodoDestino }
                        )
                    }
                }
            }
        }
    }
    
    // Vista para mostrar relaciones hacia la estructura seleccionada
    @ViewBuilder
    private func relacionesHaciaView(_ estructura: NodoAnatomico) -> some View {
        let relacionesFiltradas = dataManager.buscarRelacionesHaciaNodo(estructura.codigo)
            .filter { tipoRelacion == nil || $0.tipo == tipoRelacion }
        
        VStack(alignment: .leading, spacing: 12) {
            Text("Esta estructura es afectada por:")
                .font(.headline)
                .padding(.vertical, 4)
            
            if relacionesFiltradas.isEmpty {
                Text("No se han definido relaciones de entrada" + (tipoRelacion != nil ? " de este tipo" : ""))
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(relacionesFiltradas, id: \.id) { relacion in
                    if let nodoOrigen = dataManager.buscarNodo(codigo: relacion.idOrigen) {
                        RelacionRow(
                            relacion: relacion,
                            nodoRelacionado: nodoOrigen,
                            esDestino: false,
                            onTap: { estructuraSeleccionada = nodoOrigen }
                        )
                    }
                }
            }
        }
    }
    
    // Filtra las estructuras según los criterios
    private func estructurasFiltradas() -> [NodoAnatomico] {
        var estructuras = Array(dataManager.nodos.values)
        
        // Filtrar por texto de búsqueda
        if !busqueda.isEmpty {
            estructuras = estructuras.filter {
                $0.nombreEspanol.localizedCaseInsensitiveContains(busqueda) ||
                $0.nombreLatin.localizedCaseInsensitiveContains(busqueda) ||
                $0.idCode.localizedCaseInsensitiveContains(busqueda)
            }
        }
        
        // Filtrar por relaciones si se seleccionó un tipo
        if let tipo = tipoRelacion {
            let codigosConRelacion = Set(
                dataManager.relaciones.values
                    .filter { $0.tipo == tipo }
                    .flatMap { [$0.idOrigen, $0.idDestino] }
            )
            
            estructuras = estructuras.filter { codigosConRelacion.contains($0.codigo) }
        }
        
        return estructuras.sorted { $0.nombreEspanol < $1.nombreEspanol }
    }
}

// Componentes auxiliares
struct RelacionFilterChip: View {
    let texto: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(texto)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(15)
        }
    }
}

struct EstructuraHeader: View {
    let estructura: NodoAnatomico
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Título
            VStack(alignment: .leading, spacing: 4) {
                Text(estructura.nombreEspanol)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(estructura.nombreLatin)
                    .font(.title3)
                    .italic()
                    .foregroundColor(.secondary)
            }
            
            // Metadata
            HStack {
                if let sistema = estructura.sistema {
                    MetadataPill(text: sistema.nombreCompleto)
                }
                
                MetadataPill(text: CategoriasAnatomicas.nombreDescriptivo(estructura.categoria))
            }
            
            // Descripción
            Text(estructura.descripcion)
                .padding(.top, 8)
        }
    }
}

struct RelacionRow: View {
    let relacion: RelacionAnatomica
    let nodoRelacionado: NodoAnatomico
    let esDestino: Bool // true si el nodo relacionado es el destino
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top) {
                // Icono según tipo de relación
                Image(systemName: iconoTipoRelacion(relacion.tipo))
                    .foregroundColor(colorTipoRelacion(relacion.tipo))
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(nodoRelacionado.nombreEspanol)
                        .fontWeight(.medium)
                    
                    Text(nodoRelacionado.nombreLatin)
                        .font(.caption)
                        .italic()
                        .foregroundColor(.secondary)
                    
                    Text(descripcionRelacion(relacion.tipo, esDestino: esDestino))
                        .font(.caption)
                        .foregroundColor(colorTipoRelacion(relacion.tipo))
                        .padding(.top, 2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(Color(.systemGray6).opacity(0.5))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // Icono según tipo de relación
    private func iconoTipoRelacion(_ tipo: TipoRelacion) -> String {
        switch tipo {
        case .irriga: return "drop.fill"
        case .drena: return "arrow.down.heart.fill"
        case .conecta: return "link"
        case .inerva: return "bolt.fill"
        case .limita: return "square.and.line.vertical.and.square"
        case .asocia: return "arrow.triangle.2.circlepath"
        }
    }
    
    // Color según tipo de relación
    private func colorTipoRelacion(_ tipo: TipoRelacion) -> Color {
        switch tipo {
        case .irriga: return .red
        case .drena: return .blue
        case .conecta: return .green
        case .inerva: return .orange
        case .limita: return .purple
        case .asocia: return .gray
        }
    }
    
    // Descripción según dirección de la relación
    private func descripcionRelacion(_ tipo: TipoRelacion, esDestino: Bool) -> String {
        if esDestino {
            return tipo.descripcion
        } else {
            // Invertir la descripción
            switch tipo {
            case .irriga: return "Irriga a esta estructura"
            case .drena: return "Drena esta estructura"
            case .conecta: return "Se conecta con esta estructura"
            case .inerva: return "Inerva esta estructura"
            case .limita: return "Limita con esta estructura"
            case .asocia: return "Se asocia con esta estructura"
            }
        }
    }
}

struct RelacionesView_Previews: PreviewProvider {
    static var previews: some View {
        RelacionesView(dataManager: NeuroDataManager())
    }
}