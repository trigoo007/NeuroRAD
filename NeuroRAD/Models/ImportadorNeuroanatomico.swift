//
//  ImportadorNeuroanatomico.swift
//  NeuroRAD
//
//  Created by Rodrigo Munoz on 21-04-25.
//


// ImportadorNeuroanatomico.swift

import Foundation

class ImportadorNeuroanatomico {
    
    private let dataManager: NeuroDataManager
    
    // Mapeo de prefijos a sistemas neurológicos
    private let mapaSeccionesSistema: [String: String] = [
        // Corteza y estructuras corticales
        "CTX": "SC",      // Sistema Central
        "GYR": "SC",      // Giros
        "SUL": "SC",      // Surcos
        "FIS": "SC",      // Fisuras
        "LOB": "SC",      // Lóbulos
        "LOBPAR": "SC",   // Lobulillos parietales
        
        // Cerebelo y estructuras relacionadas
        "CB": "SC",       // Cerebelo
        "PED": "SC",      // Pedúnculos
        "NUC": "SC",      // Núcleos
        
        // Tronco encefálico
        "PONS": "SC",     // Puente
        "MES": "SC",      // Mesencéfalo
        "MED": "SC",      // Médula/Bulbo
        
        // Otras estructuras del SNC
        "CORP": "SC",     // Cuerpo calloso, etc.
        "HEM": "SC",      // Hemisferios
        "INS": "SC",      // Ínsula
        "AMYG": "SC",     // Amígdala
        "HIP": "SC",      // Hipocampo
        
        // Sistema vascular
        "ART": "SV",      // Arterias
        "VEN": "SV",      // Venas/Ventrículos (contexto)
        
        // Nervios (sistema periférico)
        "NERV": "SP",     // Nervios
        
        // Espacios
        "CIS": "SE"       // Cisternas
    ]
    
    // Mapeo de prefijos a categorías
    private let mapaSeccionesCategoria: [String: String] = [
        // Sustancia gris
        "CTX": "SG",      // Corteza
        "GYR": "SG",      // Giros
        "LOB": "SG",      // Lóbulos
        "LOBPAR": "SG",   // Lobulillos parietales
        "NUC": "NUC",     // Núcleos
        
        // Sustancia blanca
        "CORP": "SB",     // Cuerpo calloso
        "TRC": "SB",      // Tractos
        "FIMB": "SB",     // Fimbria
        "FORN": "SB",     // Fórnix
        "CING": "SB",     // Cíngulo
        
        // Surcos y fisuras
        "SUL": "SF",      // Surcos
        "FIS": "SF",      // Fisuras
        
        // Ventrículos
        "VEN": "VT",      // Ventrículos
        
        // Cerebelo
        "CB": "CRB",      // Cerebelo
        
        // Arterias y venas
        "ART": "AR",      // Arterias
        
        // Espacios
        "CIS": "CIS"      // Cisternas
    ]
    
    init(dataManager: NeuroDataManager) {
        self.dataManager = dataManager
    }
    
    // Función principal para importar datos JSON
    func importarDatosJSON(jsonString: String) throws -> [NodoAnatomico] {
        // Convertir el string a datos
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw NSError(domain: "ImportadorNeuroanatomico", code: 400,
                         userInfo: [NSLocalizedDescriptionKey: "Error al convertir string a datos JSON"])
        }
        
        // Decodificar el JSON
        let decoder = JSONDecoder()
        let estructuras: [EstructuraJSON]
        
        do {
            estructuras = try decoder.decode([EstructuraJSON].self, from: jsonData)
        } catch {
            print("Error decodificando JSON: \(error)")
            throw error
        }
        
        // Convertir cada estructura JSON en un nodo anatómico
        var nodosCreados: [NodoAnatomico] = []
        
        for estructura in estructuras {
            if let nodo = convertirEstructuraANodo(estructura) {
                nodosCreados.append(nodo)
                dataManager.agregarNodo(nodo)
            }
        }
        
        print("Se importaron \(nodosCreados.count) estructuras neuroanatómicas")
        return nodosCreados
    }
    
    // Estructura que refleja el formato JSON
    private struct EstructuraJSON: Codable {
        let id_code: String
        let nombre_espanol: String
        let nombre_latin: String
        let descripcion: String
        let funcion: String
        let referencia: String
    }
    
    // Convierte una estructura JSON en un nodo anatómico
    private func convertirEstructuraANodo(_ estructura: EstructuraJSON) -> NodoAnatomico? {
        // Analizar el id_code para determinar sistema, categoría, etc.
        let componentes = estructura.id_code.split(separator: "-")
        let prefijo = String(componentes.first ?? "")
        
        // Determinar sistema, categoría, región y entidad
        let sistema = determinarSistema(prefijo: prefijo, idCode: estructura.id_code)
        let categoria = determinarCategoria(prefijo: prefijo, idCode: estructura.id_code)
        let region = determinarRegion(componentes: componentes, idCode: estructura.id_code)
        let entidad = determinarEntidad(componentes: componentes, idCode: estructura.id_code)
        
        // Generar número secuencial
        let numeroSecuencial = dataManager.siguienteNumeroNodo(
            sistema: sistema,
            categoria: categoria,
            region: region,
            entidad: entidad
        )
        
        // Generar código jerárquico completo
        let codigo = GeneradorCodigos.generarCodigoNodo(
            sistema: sistema,
            categoria: categoria,
            region: region,
            entidad: entidad,
            numero: numeroSecuencial
        )
        
        // Crear clasificación basada en la estructura
        let clasificacion = determinarClasificacion(prefijo: prefijo, idCode: estructura.id_code)
        
        // Dividir el texto de función en un array
        let funciones = estructura.funcion.components(separatedBy: ". ")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        // Crear y devolver el nodo anatómico
        return NodoAnatomico(
            codigo: codigo,
            idCode: estructura.id_code,
            clasificacion: clasificacion,
            nombreEspanol: estructura.nombre_espanol,
            nombreLatin: estructura.nombre_latin,
            descripcion: estructura.descripcion,
            funciones: funciones.isEmpty ? [estructura.funcion] : funciones,
            referencia: estructura.referencia
        )
    }
    
    // Determina el sistema neurológico basado en el prefijo del id_code
    private func determinarSistema(prefijo: String, idCode: String) -> String {
        // Si existe en el mapa, usar ese valor
        if let sistema = mapaSeccionesSistema[prefijo] {
            return sistema
        }
        
        // Casos especiales por contextualización
        if idCode.contains("VERM") || idCode.contains("FLOC") {
            return "SC" // Estructuras cerebelosas
        }
        
        // Casos específicos para estructuras vasculares vs. ventrículos
        if idCode.starts(with: "VEN-") {
            return "SC" // Ventrículos (Sistema Central)
        }
        
        // Por defecto, sistema central
        return "SC"
    }
    
    // Determina la categoría anatómica
    private func determinarCategoria(prefijo: String, idCode: String) -> String {
        // Si existe en el mapa, usar ese valor
        if let categoria = mapaSeccionesCategoria[prefijo] {
            return categoria
        }
        
        // Casos especiales
        if idCode.starts(with: "VEN-") {
            return "VT" // Ventrículos
        }
        
        if idCode.contains("VERM") || idCode.contains("FLOC") || idCode.contains("CB-") {
            return "CRB" // Cerebelo
        }
        
        // Sustancia gris por defecto
        return "SG"
    }
    
    // Determina la región anatómica
    private func determinarRegion(componentes: [Substring], idCode: String) -> String {
        if componentes.count > 1 {
            // Para códigos como CB-VERM, usar VERM como región
            return String(componentes[1])
        }
        
        // Algunos casos especiales
        if idCode.starts(with: "GYR") {
            return "GYR" // Giros
        } else if idCode.starts(with: "SUL") {
            return "SUL" // Surcos
        } else if idCode.starts(with: "LOB") {
            return "LOB" // Lóbulos
        }
        
        // Región genérica por defecto
        return "GEN"
    }
    
    // Determina la entidad específica
    private func determinarEntidad(componentes: [Substring], idCode: String) -> String {
        // Para códigos como CB-VERM-LING, combinar componentes después del primero
        if componentes.count > 2 {
            return componentes[1...].joined(separator: "-")
        } else if componentes.count > 1 {
            return String(componentes[1])
        }
        
        // Si solo hay un componente, usar el id_code completo
        return idCode
    }
    
    // Determina la clasificación basada en el tipo de estructura
    private func determinarClasificacion(prefijo: String, idCode: String) -> String {
        // Mapeo de prefijos a clasificaciones
        let clasificaciones: [String: String] = [
            "CTX": "CORT",  // Corteza
            "GYR": "CORT",  // Giros (cortical)
            "LOB": "CORT",  // Lóbulos (cortical)
            "SUL": "SULC",  // Surcos
            "FIS": "SULC",  // Fisuras
            "NUC": "NUCL",  // Núcleos
            "CB": "CRBM",   // Cerebelo
            "VEN": "VENT",  // Ventrículos
            "CORP": "SBST", // Sustancia blanca
            "TRC": "SBST",  // Tractos
            "PONS": "BSTM", // Tronco encefálico
            "MES": "BSTM",  // Mesencéfalo
            "MED": "BSTM",  // Bulbo/Médula
            "INS": "CORT",  // Ínsula (cortical)
            "PED": "CONN",  // Conexiones/Pedúnculos
            "HIP": "LIMC",  // Sistema límbico
            "AMYG": "LIMC"  // Sistema límbico
        ]
        
        // Si existe en el mapa, usar ese valor
        if let clasificacion = clasificaciones[prefijo] {
            return clasificacion
        }
        
        // Casos especiales
        if idCode.contains("VERM") || idCode.contains("FLOC") || idCode.contains("CB-") {
            return "CRBM" // Cerebelo
        }
        
        // Clasificación anatómica general por defecto
        return "ANAT"
    }
}
