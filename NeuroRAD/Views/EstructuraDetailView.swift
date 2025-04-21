//
//  EstructuraDetailView.swift
//  NeuroRAD
//
//  Created for NeuroRAD Project
//

import SwiftUI

struct EstructuraDetailView: View {
    let estructura: NodoAnatomico
    let dataManager: NeuroDataManager
    @State private var selectedTab = 0
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Encabezado con nombres
                VStack(alignment: .leading, spacing: 4) {
                    Text(estructura.nombreEspanol)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(estructura.nombreLatin)
                        .font(.title2)
                        .italic()
                        .foregroundColor(.secondary)
                    
                    HStack {
                        MetadataPill(text: "Sistema: \(estructura.sistema?.nombreCompleto ?? "Desconocido")")
                        MetadataPill(text: "Cat: \(CategoriasAnatomicas.nombreDescriptivo(estructura.categoria))")
                    }
                }
                .padding(.bottom)
                
                // Selector de pestañas
                Picker("Información", selection: $selectedTab) {
                    Text("Descripción").tag(0)
                    Text("Funciones").tag(1)
                    Text("Relaciones").tag(2)
                    Text("Referencias").tag(3)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.bottom)
                
                // Contenido según pestaña seleccionada
                VStack(alignment: .leading, spacing: 15) {
                    switch selectedTab {
                    case 0:
                        // Descripción
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader(title: "Descripción Anatómica")
                            Text(estructura.descripcion)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                    case 1:
                        // Funciones
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader(title: "Funciones")
                            ForEach(estructura.funciones, id: \.self) { funcion in
                                HStack(alignment: .top) {
                                    Image(systemName: "circle.fill")
                                        .font(.system(size: 8))
                                        .padding(.top, 6)
                                    Text(funcion)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(.bottom, 5)
                            }
                        }
                        
                    case 2:
                        // Relaciones anatómicas
                        VStack(alignment: .leading, spacing: 15) {
                            SectionHeader(title: "Relaciones Anatómicas")
                            relacionesView()
                        }
                        
                    case 3:
                        // Referencias
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader(title: "Referencias")
                            Text(estructura.referencia)
                                .foregroundColor(.secondary)
                                .font(.footnote)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(estructura.codigo)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // Vista para mostrar las relaciones anatómicas
    @ViewBuilder
    private func relacionesView() -> some View {
        let relacionesDesde = dataManager.buscarRelacionesDesdeNodo(estructura.codigo)
        let relacionesHacia = dataManager.buscarRelacionesHaciaNodo(estructura.codigo)
        
        if relacionesDesde.isEmpty && relacionesHacia.isEmpty {
            Text("No hay relaciones anatómicas registradas para esta estructura.")
                .foregroundColor(.secondary)
                .padding()
        } else {
            if !relacionesDesde.isEmpty {
                // Relaciones desde esta estructura
                VStack(alignment: .leading, spacing: 10) {
                    Text("Esta estructura:")
                        .font(.headline)
                        .padding(.top, 5)
                    
                    ForEach(relacionesDesde, id: \.id) { relacion in
                        if let nodoDestino = dataManager.buscarNodo(codigo: relacion.idDestino) {
                            HStack {
                                Text("• \(relacion.tipo.descripcion)")
                                    .foregroundColor(.secondary)
                                NavigationLink(destination: EstructuraDetailView(estructura: nodoDestino, dataManager: dataManager)) {
                                    Text(nodoDestino.nombreEspanol)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
            }
            
            if !relacionesHacia.isEmpty {
                // Relaciones hacia esta estructura
                VStack(alignment: .leading, spacing: 10) {
                    Text("Otras estructuras que afectan a esta:")
                        .font(.headline)
                        .padding(.top, 10)
                    
                    ForEach(relacionesHacia, id: \.id) { relacion in
                        if let nodoOrigen = dataManager.buscarNodo(codigo: relacion.idOrigen) {
                            HStack {
                                NavigationLink(destination: EstructuraDetailView(estructura: nodoOrigen, dataManager: dataManager)) {
                                    Text(nodoOrigen.nombreEspanol)
                                        .foregroundColor(.blue)
                                }
                                Text("• \(relacion.tipo.descripcion)")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }
}

// Componentes auxiliares
struct SectionHeader: View {
    let title: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.headline)
            
            Divider()
                .background(Color.blue.opacity(0.5))
        }
    }
}

struct MetadataPill: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
    }
}

struct EstructuraDetailView_Previews: PreviewProvider {
    static var previews: some View {
        // Crear una estructura de prueba para la vista previa
        let estructuraPrueba = NodoAnatomico(
            codigo: "NA-SC-SG-CTX-CerebralCortex-001",
            idCode: "CTX-CRB",
            clasificacion: "CORT",
            nombreEspanol: "Corteza Cerebral",
            nombreLatin: "Cortex cerebri",
            descripcion: "Parte del telencéfalo que cubre las estructuras diencefálicas más profundas del prosencéfalo en cada hemisferio cerebral.",
            funciones: ["Base para la localización de lesiones y comprensión de implicaciones funcionales en neuroimagen.",
                       "Implicada en funciones cognitivas, emocionales y conductuales de orden superior."],
            referencia: "Anatomy of the Cerebral Cortex, Lobes, and Cerebellum"
        )
        
        return NavigationView {
            EstructuraDetailView(estructura: estructuraPrueba, dataManager: NeuroDataManager())
        }
    }
}
