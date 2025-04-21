//
//  ExplorerView.swift
//  NeuroRAD
//
//  Created for NeuroRAD Project
//

import SwiftUI

struct ExplorerView: View {
    @ObservedObject var dataManager: NeuroDataManager
    @State private var sistemaSeleccionado: SistemaNeurologico?
    @State private var categoriaSeleccionada: String?
    @State private var busqueda: String = ""
    
    var body: some View {
        NavigationView {
            VStack {
                // Barra de búsqueda
                SearchBar(text: $busqueda)
                    .padding(.horizontal)
                
                // Selector de sistemas
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(SistemaNeurologico.allCases, id: \.self) { sistema in
                            SistemaButton(
                                sistema: sistema,
                                isSelected: sistema == sistemaSeleccionado,
                                action: {
                                    self.sistemaSeleccionado = sistema
                                    self.categoriaSeleccionada = nil
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                
                // Selector de categorías (si hay sistema seleccionado)
                if let sistema = sistemaSeleccionado {
                    categoriasList(for: sistema)
                }
                
                // Lista de estructuras
                estructurasList()
                    .animation(.default, value: sistemaSeleccionado)
                    .animation(.default, value: categoriaSeleccionada)
                    .animation(.default, value: busqueda)
            }
            .navigationTitle("Explorador Neuroanatómico")
        }
    }
    
    // Vista de categorías para el sistema seleccionado
    @ViewBuilder
    private func categoriasList(for sistema: SistemaNeurologico) -> some View {
        let categorias = obtenerCategorias(para: sistema)
        
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(categorias, id: \.id) { categoria in
                    CategoriaChip(
                        categoria: categoria,
                        isSelected: categoria.id == categoriaSeleccionada,
                        action: {
                            self.categoriaSeleccionada = categoria.id
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 5)
    }
    
    // Lista de estructuras filtradas
    @ViewBuilder
    private func estructurasList() -> some View {
        let estructuras = estructurasFiltradas()
        
        if estructuras.isEmpty {
            EmptyResultsView()
        } else {
            List {
                ForEach(estructuras, id: \.id) { estructura in
                    NavigationLink(destination: EstructuraDetailView(estructura: estructura, dataManager: dataManager)) {
                        EstructuraRow(estructura: estructura)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
        }
    }
    
    // Obtiene las categorías disponibles para un sistema
    private func obtenerCategorias(para sistema: SistemaNeurologico) -> [CategoriaAnatomica] {
        // Esta función obtiene las categorías por sistema desde el dataManager
        // o desde una lista predefinida
        
        var categoriasDelSistema: [CategoriaAnatomica] = []
        
        switch sistema {
        case .centralSC:
            categoriasDelSistema = [
                CategoriaAnatomica(id: CategoriasAnatomicas.sustanciaGris, nombre: "Sustancia Gris", sistema: sistema),
                CategoriaAnatomica(id: CategoriasAnatomicas.sustanciaBlanca, nombre: "Sustancia Blanca", sistema: sistema),
                CategoriaAnatomica(id: CategoriasAnatomicas.nucleos, nombre: "Núcleos", sistema: sistema),
                CategoriaAnatomica(id: CategoriasAnatomicas.surcosFisuras, nombre: "Surcos y Fisuras", sistema: sistema),
                CategoriaAnatomica(id: CategoriasAnatomicas.ventricular, nombre: "Sistema Ventricular", sistema: sistema),
                CategoriaAnatomica(id: CategoriasAnatomicas.cerebelo, nombre: "Cerebelo", sistema: sistema),
                CategoriaAnatomica(id: CategoriasAnatomicas.troncoEncefalico, nombre: "Tronco Encefálico", sistema: sistema)
            ]
        case .vascularSV:
            categoriasDelSistema = [
                CategoriaAnatomica(id: CategoriasAnatomicas.arterias, nombre: "Arterias", sistema: sistema),
                CategoriaAnatomica(id: CategoriasAnatomicas.venas, nombre: "Venas", sistema: sistema),
                CategoriaAnatomica(id: CategoriasAnatomicas.senos, nombre: "Senos Venosos", sistema: sistema)
            ]
        case .perifericoSP:
            categoriasDelSistema = [
                CategoriaAnatomica(id: CategoriasAnatomicas.nerviosCraneales, nombre: "Nervios Craneales", sistema: sistema),
                CategoriaAnatomica(id: CategoriasAnatomicas.nerviosEspinales, nombre: "Nervios Espinales", sistema: sistema),
                CategoriaAnatomica(id: CategoriasAnatomicas.ganglios, nombre: "Ganglios", sistema: sistema)
            ]
        case .espaciosSE:
            categoriasDelSistema = [
                CategoriaAnatomica(id: CategoriasAnatomicas.espaciosSubaracnoideos, nombre: "Espacios Subaracnoideos", sistema: sistema),
                CategoriaAnatomica(id: CategoriasAnatomicas.cisternas, nombre: "Cisternas", sistema: sistema)
            ]
        }
        
        return categoriasDelSistema
    }
    
    // Filtra las estructuras según los criterios seleccionados
    private func estructurasFiltradas() -> [NodoAnatomico] {
        var estructuras: [NodoAnatomico] = []
        
        // Filtrar por sistema
        if let sistema = sistemaSeleccionado {
            estructuras = dataManager.buscarNodosPorSistema(sistema)
            
            // Filtrar por categoría si está seleccionada
            if let categoria = categoriaSeleccionada {
                estructuras = estructuras.filter { $0.categoria == categoria }
            }
        } else {
            // Si no hay sistema seleccionado, mostrar todas
            estructuras = Array(dataManager.nodos.values)
        }
        
        // Filtrar por texto de búsqueda
        if !busqueda.isEmpty {
            estructuras = estructuras.filter {
                $0.nombreEspanol.localizedCaseInsensitiveContains(busqueda) ||
                $0.nombreLatin.localizedCaseInsensitiveContains(busqueda) ||
                $0.descripcion.localizedCaseInsensitiveContains(busqueda)
            }
        }
        
        return estructuras.sorted { $0.nombreEspanol < $1.nombreEspanol }
    }
}

// Componentes auxiliares
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Buscar estructuras...", text: $text)
                .disableAutocorrection(true)
            
            if !text.isEmpty {
                Button(action: {
                    self.text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct SistemaButton: View {
    let sistema: SistemaNeurologico
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: iconoSistema(sistema))
                    .font(.system(size: 22))
                Text(nombreCorto(sistema))
                    .font(.caption)
            }
            .padding()
            .frame(width: 90, height: 90)
            .background(isSelected ? Color.blue.opacity(0.2) : Color(.systemGray6))
            .foregroundColor(isSelected ? .blue : .primary)
            .cornerRadius(12)
        }
    }
    
    private func iconoSistema(_ sistema: SistemaNeurologico) -> String {
        switch sistema {
        case .centralSC: return "brain"
        case .perifericoSP: return "network"
        case .vascularSV: return "waveform.path.ecg"
        case .espaciosSE: return "cube.transparent"
        }
    }
    
    private func nombreCorto(_ sistema: SistemaNeurologico) -> String {
        switch sistema {
        case .centralSC: return "Central"
        case .perifericoSP: return "Periférico"
        case .vascularSV: return "Vascular"
        case .espaciosSE: return "Espacios"
        }
    }
}

struct CategoriaChip: View {
    let categoria: CategoriaAnatomica
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(categoria.nombre)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(15)
        }
    }
}

struct EstructuraRow: View {
    let estructura: NodoAnatomico
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(estructura.nombreEspanol)
                .font(.headline)
            
            Text(estructura.nombreLatin)
                .font(.subheadline)
                .italic()
                .foregroundColor(.secondary)
            
            Text(estructura.clasificacion)
                .font(.caption)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(4)
        }
        .padding(.vertical, 4)
    }
}

struct EmptyResultsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No se encontraron estructuras")
                .font(.title2)
                .foregroundColor(.gray)
            
            Text("Intenta con otros criterios de búsqueda")
                .foregroundColor(.gray)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

struct ExplorerView_Previews: PreviewProvider {
    static var previews: some View {
        ExplorerView(dataManager: NeuroDataManager())
    }
}
