//
//  NeuroIndexSystem.swift
//  NeuroRAD
//
//  Created for NeuroRAD Project
//

import Foundation

// MARK: - SISTEMAS PRINCIPALES

/// Define los sistemas neurológicos principales
enum SistemaNeurologico: String, Codable, CaseIterable {
    case centralSC = "SC"       // Sistema Nervioso Central
    case perifericoSP = "SP"    // Sistema Nervioso Periférico
    case vascularSV = "SV"      // Sistema Vascular
    case espaciosSE = "SE"      // Espacios y Cisternas
    
    var nombreCompleto: String {
        switch self {
        case .centralSC: return "Sistema Nervioso Central"
        case .perifericoSP: return "Sistema Nervioso Periférico"
        case .vascularSV: return "Sistema Vascular Neurológico"
        case .espaciosSE: return "Espacios y Cisternas"
        }
    }
}

// MARK: - CATEGORÍAS ANATÓMICAS GENÉRICAS

/// Define categorías principales dentro de cada sistema
struct CategoriasAnatomicas {
    // Sistema Central (SC)
    static let sustanciaGris = "SG"     // Sustancia Gris
    static let sustanciaBlanca = "SB"   // Sustancia Blanca
    static let ventricular = "VT"       // Sistema Ventricular
    static let nucleos = "NUC"          // Núcleos
    static let surcosFisuras = "SF"     // Surcos y Fisuras
    static let cerebelo = "CRB"         // Cerebelo
    static let troncoEncefalico = "BST" // Tronco Encefálico
    
    // Sistema Vascular (SV)
    static let arterias = "AR"          // Arterias
    static let venas = "VN"             // Venas
    static let senos = "SIN"            // Senos venosos
    
    // Sistema Periférico (SP)
    static let nerviosCraneales = "NC"  // Nervios Craneales
    static let nerviosEspinales = "NE"  // Nervios Espinales
    static let ganglios = "GNG"         // Ganglios
    
    // Espacios (SE)
    static let espaciosSubaracnoideos = "ESA" // Espacios Subaracnoideos
    static let cisternas = "CIS"             // Cisternas
    
    // Obtiene el nombre descriptivo para una categoría
    static func nombreDescriptivo(_ categoriaID: String) -> String {
        let mapaNombres: [String: String] = [
            "SG": "Sustancia Gris",
            "SB": "Sustancia Blanca",
            "VT": "Sistema Ventricular",
            "NUC": "Núcleos",
            "SF": "Surcos y Fisuras",
            "CRB": "Cerebelo",
            "BST": "Tronco Encefálico",
            "AR": "Arterias",
            "VN": "Venas",
            "SIN": "Senos Venosos",
            "NC": "Nervios Craneales",
            "NE": "Nervios Espinales",
            "GNG": "Ganglios",
            "ESA": "Espacios Subaracnoideos",
            "CIS": "Cisternas"
        ]
        
        return mapaNombres[categoriaID] ?? "Categoría \(categoriaID)"
    }
}

// MARK: - ESTRUCTURA DE NODO ANATÓMICO

/// Estructura base para representar un elemento anatómico
struct NodoAnatomico: Identifiable, Codable, Hashable {
    // Identificadores
    var id = UUID()
    var codigo: String                // NA-SC-SG-CT-MotorPrimaria-001
    var idCode: String                // Abreviatura (ej: LOB-PAR-SUP)
    var clasificacion: String         // Categoría XXXX (ej: CORT)
    
    // Metadatos descriptivos
    var nombreEspanol: String
    var nombreLatin: String
    var descripcion: String
    var funciones: [String]           // Lista de funciones principales
    var referencia: String            // Referencia bibliográfica
    var imagenReferencia: String?     // Nombre del archivo de imagen (opcional)
    
    // Propiedades computadas para extraer componentes del código
    var sistema: SistemaNeurologico? {
        let componentes = codigo.split(separator: "-")
        if componentes.count > 1 {
            return SistemaNeurologico(rawValue: String(componentes[1]))
        }
        return nil
    }
    
    var categoria: String {
        let componentes = codigo.split(separator: "-")
        return componentes.count > 2 ? String(componentes[2]) : ""
    }
    
    var region: String {
        let componentes = codigo.split(separator: "-")
        return componentes.count > 3 ? String(componentes[3]) : ""
    }
    
    var entidad: String {
        let componentes = codigo.split(separator: "-")
        return componentes.count > 4 ? String(componentes[4]) : ""
    }
    
    var numeroSecuencial: Int {
        let componentes = codigo.split(separator: "-")
        if componentes.count > 5, let numero = Int(componentes[5]) {
            return numero
        }
        return 0
    }
    
    // Para conformar con Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: NodoAnatomico, rhs: NodoAnatomico) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - RELACIONES ENTRE NODOS

/// Tipos de relaciones entre estructuras anatómicas
enum TipoRelacion: String, Codable, CaseIterable {
    case irriga = "IRRIGA"
    case drena = "DRENA"
    case conecta = "CONECTA"
    case inerva = "INERVA"
    case limita = "LIMITA"
    case asocia = "ASOCIA"
    
    var descripcion: String {
        switch self {
        case .irriga: return "Suministra sangre a"
        case .drena: return "Recibe sangre desde"
        case .conecta: return "Se conecta con"
        case .inerva: return "Proporciona inervación a"
        case .limita: return "Define el límite de"
        case .asocia: return "Se asocia funcionalmente con"
        }
    }
}

/// Representa una relación entre dos estructuras anatómicas
struct RelacionAnatomica: Identifiable, Codable, Hashable {
    var id = UUID()
    var codigo: String                // RE-TIPO-ID1-ID2-001
    var tipo: TipoRelacion
    var idOrigen: String              // Código del nodo origen
    var idDestino: String             // Código del nodo destino
    var descripcion: String?          // Descripción opcional de la relación
    
    // Para conformar con Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: RelacionAnatomica, rhs: RelacionAnatomica) -> Bool {
        return lhs.id == rhs.id
    }
}

/// Modelo que agrupa las categorías de estructuras anatómicas
struct CategoriaAnatomica: Identifiable, Hashable {
    var id: String                    // Identificador de la categoría (ej: "SG")
    var nombre: String                // Nombre descriptivo (ej: "Sustancia Gris")
    var sistema: SistemaNeurologico   // Sistema al que pertenece
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: CategoriaAnatomica, rhs: CategoriaAnatomica) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - GENERADOR DE CÓDIGOS

/// Clase para generar códigos válidos según el formato definido
class GeneradorCodigos {
    
    /// Genera un código de nodo basado en sus componentes
    static func generarCodigoNodo(
        sistema: String,
        categoria: String,
        region: String,
        entidad: String,
        numero: Int
    ) -> String {
        return "NA-\(sistema)-\(categoria)-\(region)-\(entidad)-\(String(format: "%03d", numero))"
    }
    
    /// Genera un código de relación basado en sus componentes
    static func generarCodigoRelacion(
        tipo: TipoRelacion,
        idOrigen: String,
        idDestino: String,
        numero: Int
    ) -> String {
        return "RE-\(tipo.rawValue)-\(idOrigen)-\(idDestino)-\(String(format: "%03d", numero))"
    }
    
    /// Analiza un código de nodo para extraer sus componentes
    static func analizarCodigoNodo(_ codigo: String) -> (sistema: String, categoria: String, region: String, entidad: String, numero: Int)? {
        let componentes = codigo.split(separator: "-")
        
        // Un código válido debe tener al menos 6 componentes: NA-SC-SG-REG-ENT-001
        guard componentes.count >= 6,
              String(componentes[0]) == "NA" else {
            return nil
        }
        
        let sistema = String(componentes[1])
        let categoria = String(componentes[2])
        let region = String(componentes[3])
        let entidad = String(componentes[4])
        let numeroStr = String(componentes[5])
        
        guard let numero = Int(numeroStr) else {
            return nil
        }
        
        return (sistema, categoria, region, entidad, numero)
    }
    
    /// Analiza un código de relación para extraer sus componentes
    static func analizarCodigoRelacion(_ codigo: String) -> (tipo: TipoRelacion, idOrigen: String, idDestino: String, numero: Int)? {
        let componentes = codigo.split(separator: "-")
        
        // Un código válido debe comenzar con "RE" y tener al menos 4 componentes
        guard componentes.count >= 4,
              String(componentes[0]) == "RE",
              let tipo = TipoRelacion(rawValue: String(componentes[1])) else {
            return nil
        }
        
        // Los componentes intermedios representan los IDs de origen y destino
        // Como estos IDs pueden contener guiones, necesitamos reconstruir apropiadamente
        let tipoStr = String(componentes[1])
        let resto = codigo.replacingOccurrences(of: "RE-\(tipoStr)-", with: "")
        let posicionUltimoGuion = resto.lastIndex(of: "-")
        
        guard let posUltimoGuion = posicionUltimoGuion else {
            return nil
        }
        
        let idsCombinados = resto[..<posUltimoGuion]
        let numeroStr = resto[resto.index(after: posUltimoGuion)...]
        
        // Encontrar el punto donde termina el primer ID y comienza el segundo
        let posicionSeparador = idsCombinados.lastIndex(of: "-")
        
        guard let posSeparador = posicionSeparador else {
            return nil
        }
        
        let idOrigen = String(idsCombinados[..<posSeparador])
        let idDestino = String(idsCombinados[idsCombinados.index(after: posSeparador)...])
        
        guard let numero = Int(numeroStr) else {
            return nil
        }
        
        return (tipo, idOrigen, idDestino, numero)
    }
}

// MARK: - GESTOR DE BASE DE DATOS

/// Clase para gestionar la colección de nodos y relaciones
class NeuroDataManager: ObservableObject {
    // Colecciones de datos
    @Published var nodos: [String: NodoAnatomico] = [:]         // Clave: código del nodo
    @Published var relaciones: [String: RelacionAnatomica] = [:] // Clave: código de la relación
    
    // Contadores para generación de IDs secuenciales
    private var contadoresNodos: [String: Int] = [:]
    private var contadoresRelaciones: [String: Int] = [:]
    
    /// Añade un nuevo nodo a la colección
    func agregarNodo(_ nodo: NodoAnatomico) {
        nodos[nodo.codigo] = nodo
    }
    
    /// Añade una nueva relación a la colección
    func agregarRelacion(_ relacion: RelacionAnatomica) {
        relaciones[relacion.codigo] = relacion
    }
    
    /// Genera un número secuencial para un nuevo nodo
    func siguienteNumeroNodo(sistema: String, categoria: String, region: String, entidad: String) -> Int {
        let clave = "\(sistema)-\(categoria)-\(region)-\(entidad)"
        let contador = contadoresNodos[clave] ?? 0
        let siguiente = contador + 1
        contadoresNodos[clave] = siguiente
        return siguiente
    }
    
    /// Genera un número secuencial para una nueva relación
    func siguienteNumeroRelacion(tipo: TipoRelacion, idOrigen: String, idDestino: String) -> Int {
        let clave = "\(tipo.rawValue)-\(idOrigen)-\(idDestino)"
        let contador = contadoresRelaciones[clave] ?? 0
        let siguiente = contador + 1
        contadoresRelaciones[clave] = siguiente
        return siguiente
    }
    
    /// Crea un nuevo nodo con un código generado automáticamente
    func crearNodo(
        sistema: SistemaNeurologico,
        categoria: String,
        region: String,
        entidad: String,
        idCode: String,
        clasificacion: String,
        nombreEspanol: String,
        nombreLatin: String,
        descripcion: String,
        funciones: [String],
        referencia: String,
        imagenReferencia: String? = nil
    ) -> NodoAnatomico {
        let numero = siguienteNumeroNodo(
            sistema: sistema.rawValue,
            categoria: categoria,
            region: region,
            entidad: entidad
        )
        
        let codigo = GeneradorCodigos.generarCodigoNodo(
            sistema: sistema.rawValue,
            categoria: categoria,
            region: region,
            entidad: entidad,
            numero: numero
        )
        
        let nodo = NodoAnatomico(
            codigo: codigo,
            idCode: idCode,
            clasificacion: clasificacion,
            nombreEspanol: nombreEspanol,
            nombreLatin: nombreLatin,
            descripcion: descripcion,
            funciones: funciones,
            referencia: referencia,
            imagenReferencia: imagenReferencia
        )
        
        agregarNodo(nodo)
        return nodo
    }
    
    /// Crea una nueva relación con un código generado automáticamente
    func crearRelacion(
        tipo: TipoRelacion,
        idOrigen: String,
        idDestino: String,
        descripcion: String? = nil
    ) -> RelacionAnatomica {
        let numero = siguienteNumeroRelacion(
            tipo: tipo,
            idOrigen: idOrigen,
            idDestino: idDestino
        )
        
        let codigo = GeneradorCodigos.generarCodigoRelacion(
            tipo: tipo,
            idOrigen: idOrigen,
            idDestino: idDestino,
            numero: numero
        )
        
        let relacion = RelacionAnatomica(
            codigo: codigo,
            tipo: tipo,
            idOrigen: idOrigen,
            idDestino: idDestino,
            descripcion: descripcion
        )
        
        agregarRelacion(relacion)
        return relacion
    }
    
    /// Busca nodos por sistema
    func buscarNodosPorSistema(_ sistema: SistemaNeurologico) -> [NodoAnatomico] {
        return nodos.values.filter { nodo in
            nodo.sistema == sistema
        }.sorted { $0.nombreEspanol < $1.nombreEspanol }
    }
    
    /// Busca nodos por categoría
    func buscarNodosPorCategoria(_ categoria: String) -> [NodoAnatomico] {
        return nodos.values.filter { nodo in
            nodo.categoria == categoria
        }.sorted { $0.nombreEspanol < $1.nombreEspanol }
    }
    
    /// Busca nodos por región
    func buscarNodosPorRegion(_ region: String) -> [NodoAnatomico] {
        return nodos.values.filter { nodo in
            nodo.region == region
        }.sorted { $0.nombreEspanol < $1.nombreEspanol }
    }
    
    /// Busca relaciones por tipo
    func buscarRelacionesPorTipo(_ tipo: TipoRelacion) -> [RelacionAnatomica] {
        return relaciones.values.filter { relacion in
            relacion.tipo == tipo
        }
    }
    
    /// Busca relaciones que tienen como origen un nodo específico
    func buscarRelacionesDesdeNodo(_ codigoNodo: String) -> [RelacionAnatomica] {
        return relaciones.values.filter { relacion in
            relacion.idOrigen == codigoNodo
        }
    }
    
    /// Busca relaciones que tienen como destino un nodo específico
    func buscarRelacionesHaciaNodo(_ codigoNodo: String) -> [RelacionAnatomica] {
        return relaciones.values.filter { relacion in
            relacion.idDestino == codigoNodo
        }
    }
    
    /// Busca un nodo por su código
    func buscarNodo(codigo: String) -> NodoAnatomico? {
        return nodos[codigo]
    }
    
    /// Busca un nodo por su idCode
    func buscarNodoPorIdCode(idCode: String) -> NodoAnatomico? {
        return nodos.values.first { $0.idCode == idCode }
    }
    
    /// Guarda los datos en un archivo JSON
    func guardarDatosEnJSON(nombreArchivo: String) -> Bool {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        // Preparamos las estructuras para guardar
        struct DatosExportados: Codable {
            var nodos: [NodoAnatomico]
            var relaciones: [RelacionAnatomica]
        }
        
        let datos = DatosExportados(
            nodos: Array(nodos.values),
            relaciones: Array(relaciones.values)
        )
        
        do {
            let jsonData = try encoder.encode(datos)
            
            // Obtenemos la ruta de documentos
            guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                return false
            }
            
            let fileURL = documentsDirectory.appendingPathComponent("\(nombreArchivo).json")
            
            // Escribimos el archivo
            try jsonData.write(to: fileURL)
            return true
        } catch {
            print("Error guardando datos: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Carga datos desde un archivo JSON
    func cargarDatosDesdeJSON(nombreArchivo: String) -> Bool {
        // Obtenemos la ruta de documentos
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return false
        }
        
        let fileURL = documentsDirectory.appendingPathComponent("\(nombreArchivo).json")
        
        do {
            // Leemos el archivo
            let jsonData = try Data(contentsOf: fileURL)
            
            // Preparamos las estructuras para cargar
            struct DatosImportados: Codable {
                var nodos: [NodoAnatomico]
                var relaciones: [RelacionAnatomica]
            }
            
            let decoder = JSONDecoder()
            let datos = try decoder.decode(DatosImportados.self, from: jsonData)
            
            // Limpiamos las colecciones actuales
            nodos.removeAll()
            relaciones.removeAll()
            
            // Añadimos los nodos y relaciones cargados
            for nodo in datos.nodos {
                nodos[nodo.codigo] = nodo
            }
            
            for relacion in datos.relaciones {
                relaciones[relacion.codigo] = relacion
            }
            
            // Actualizamos los contadores
            actualizarContadores()
            
            return true
        } catch {
            print("Error cargando datos: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Actualiza los contadores basándose en los datos cargados
    private func actualizarContadores() {
        // Reiniciamos los contadores
        contadoresNodos.removeAll()
        contadoresRelaciones.removeAll()
        
        // Actualizamos contadores de nodos
        for nodo in nodos.values {
            if let componentes = GeneradorCodigos.analizarCodigoNodo(nodo.codigo) {
                let clave = "\(componentes.sistema)-\(componentes.categoria)-\(componentes.region)-\(componentes.entidad)"
                let contador = max(contadoresNodos[clave] ?? 0, componentes.numero)
                contadoresNodos[clave] = contador
            }
        }
        
        // Actualizamos contadores de relaciones
        for relacion in relaciones.values {
            if let componentes = GeneradorCodigos.analizarCodigoRelacion(relacion.codigo) {
                let clave = "\(componentes.tipo.rawValue)-\(componentes.idOrigen)-\(componentes.idDestino)"
                let contador = max(contadoresRelaciones[clave] ?? 0, componentes.numero)
                contadoresRelaciones[clave] = contador
            }
        }
    }
}
