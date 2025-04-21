//
//  MainTabView.swift
//  NeuroRAD
//
//  Created for NeuroRAD Project
//

import SwiftUI

struct MainTabView: View {
    @ObservedObject var dataManager: NeuroDataManager
    
    var body: some View {
        TabView {
            ExplorerView(dataManager: dataManager)
                .tabItem {
                    Label("Explorador", systemImage: "magnifyingglass")
                }
            
            EstudioView(dataManager: dataManager)
                .tabItem {
                    Label("Estudio", systemImage: "book")
                }
            
            RelacionesView(dataManager: dataManager)
                .tabItem {
                    Label("Relaciones", systemImage: "network")
                }
            
            ProgresoView(dataManager: dataManager)
                .tabItem {
                    Label("Progreso", systemImage: "chart.bar")
                }
        }
    }
}

// Vista para el modo de estudio (esqueleto básico para referencia)
struct EstudioViewPlaceholder: View {
    @ObservedObject var dataManager: NeuroDataManager
    
    var body: some View {
        NavigationView {
            Text("Aquí irá el sistema de tarjetas de estudio y ejercicios")
                .font(.title2)
                .navigationTitle("Modo Estudio")
        }
    }
}

// Vista para explorar relaciones anatómicas (esqueleto básico para referencia)
struct RelacionesViewPlaceholder: View {
    @ObservedObject var dataManager: NeuroDataManager
    
    var body: some View {
        NavigationView {
            Text("Aquí irán las visualizaciones de conexiones entre estructuras")
                .font(.title2)
                .navigationTitle("Relaciones Anatómicas")
        }
    }
}

// Vista para el seguimiento de progreso (esqueleto básico para referencia)
struct ProgresoViewPlaceholder: View {
    @ObservedObject var dataManager: NeuroDataManager
    
    var body: some View {
        NavigationView {
            Text("Aquí irán las estadísticas de progreso del usuario")
                .font(.title2)
                .navigationTitle("Tu Progreso")
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView(dataManager: NeuroDataManager())
    }
}
