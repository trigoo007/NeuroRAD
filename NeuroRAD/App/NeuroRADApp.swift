//
//  NeuroRADApp.swift
//  NeuroRAD
//
//  Created for NeuroRAD Project
//

import SwiftUI

@main
struct NeuroRADApp: App {
    @StateObject private var dataManager = NeuroDataManager()
    
    var body: some Scene {
        WindowGroup {
            MainTabView(dataManager: dataManager)
                .onAppear {
                    cargarDatosIniciales()
                }
        }
    }
    
    func cargarDatosIniciales() {
        // Primero intentar cargar datos guardados localmente
        if dataManager.cargarDatosDesdeJSON(nombreArchivo: "neurodata_cache") {
            print("Datos cargados desde caché local")
            return
        }
        
        // Si no hay caché, cargar desde el archivo base
        guard let url = Bundle.main.url(forResource: "estructuras_anatomicas", withExtension: "json"),
              let jsonData = try? Data(contentsOf: url),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            print("Error al cargar el archivo JSON de estructuras anatómicas")
            return
        }
        
        let importador = ImportadorNeuroanatomico(dataManager: dataManager)
        
        do {
            let nodosImportados = try importador.importarDatosJSON(jsonString: jsonString)
            print("Se importaron \(nodosImportados.count) estructuras neuroanatómicas")
            
            // Generar relaciones automáticas basadas en descripciones
            generarRelacionesAutomaticas()
            
            // Guardar los datos procesados para uso futuro
            _ = dataManager.guardarDatosEnJSON(nombreArchivo: "neurodata_cache")
        } catch {
            print("Error en la importación: \(error.localizedDescription)")
        }
    }
    
    // Método para generar relaciones basadas en el análisis de texto
    func generarRelacionesAutomaticas() {
        // Para cada nodo, buscar menciones de otras estructuras en su descripción
        for nodoOrigen in dataManager.nodos.values {
            // Texto combinado para buscar menciones
            let textoCompleto = [nodoOrigen.descripcion, nodoOrigen.funciones.joined(separator: " ")].joined(separator: " ")
            
            // Buscar menciones de otros nodos
            for nodoPotencial in dataManager.nodos.values {
                // Evitar auto-relaciones
                if nodoOrigen.codigo == nodoPotencial.codigo {
                    continue
                }
                
                // Si el nombre de otro nodo aparece en la descripción
                if textoCompleto.localizedCaseInsensitiveContains(nodoPotencial.nombreEspanol) ||
                   textoCompleto.localizedCaseInsensitiveContains(nodoPotencial.nombreLatin) {
                    
                    // Determinar el tipo de relación basado en contexto
                    let tipoRelacion = determinarTipoRelacion(texto: textoCompleto,
                                                             nodoOrigen: nodoOrigen,
                                                             nodoDestino: nodoPotencial)
                    
                    // Crear la relación
                    _ = dataManager.crearRelacion(
                        tipo: tipoRelacion,
                        idOrigen: nodoOrigen.codigo,
                        idDestino: nodoPotencial.codigo,
                        descripcion: "Relación detectada automáticamente"
                    )
                }
            }
        }
        
        print("Se generaron \(dataManager.relaciones.count) relaciones anatómicas automáticas")
    }
    
    // Análisis simple de contexto para determinar el tipo de relación
    func determinarTipoRelacion(texto: String, nodoOrigen: NodoAnatomico, nodoDestino: NodoAnatomico) -> TipoRelacion {
        // Palabras clave para diferentes tipos de relaciones
        let palabrasIrriga = ["irriga", "irrigada", "irrigación", "vasculariza", "suministra sangre"]
        let palabrasDrena = ["drena", "drenaje", "recibe sangre"]
        let palabrasConecta = ["conecta", "conexión", "unido", "une", "comunica"]
        let palabrasInerva = ["inerva", "inervación", "nervio"]
        let palabrasLimita = ["limita", "límite", "borde", "separa", "adyacente"]
        
        // Verificar si las palabras clave aparecen cerca del nombre del nodo destino
        for palabra in palabrasIrriga {
            if texto.localizedCaseInsensitiveContains("\(palabra) \(nodoDestino.nombreEspanol)") ||
               texto.localizedCaseInsensitiveContains("\(nodoDestino.nombreEspanol) \(palabra)") {
                return .irriga
            }
        }
        
        for palabra in palabrasDrena {
            if texto.localizedCaseInsensitiveContains("\(palabra) \(nodoDestino.nombreEspanol)") ||
               texto.localizedCaseInsensitiveContains("\(nodoDestino.nombreEspanol) \(palabra)") {
                return .drena
            }
        }
        
        for palabra in palabrasConecta {
            if texto.localizedCaseInsensitiveContains("\(palabra) \(nodoDestino.nombreEspanol)") ||
               texto.localizedCaseInsensitiveContains("\(nodoDestino.nombreEspanol) \(palabra)") {
                return .conecta
            }
        }
        
        for palabra in palabrasInerva {
            if texto.localizedCaseInsensitiveContains("\(palabra) \(nodoDestino.nombreEspanol)") ||
               texto.localizedCaseInsensitiveContains("\(nodoDestino.nombreEspanol) \(palabra)") {
                return .inerva
            }
        }
        
        for palabra in palabrasLimita {
            if texto.localizedCaseInsensitiveContains("\(palabra) \(nodoDestino.nombreEspanol)") ||
               texto.localizedCaseInsensitiveContains("\(nodoDestino.nombreEspanol) \(palabra)") {
                return .limita
            }
        }
        
        // Por defecto, establecer una asociación general
        return .asocia
    }
}
