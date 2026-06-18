import SwiftUI
import Foundation
import Combine

struct ContentView: View {
    
    @StateObject private var rfid = RFIDViewModel()
    
    var body: some View {
        
        NavigationStack {
            
            VStack(spacing: 25) {
                
                Image(systemName: rfid.acessoLiberado ? "lock.open.fill" : "lock.fill")
                    .font(.system(size: 90))
                    .foregroundStyle(rfid.acessoLiberado ? .green : .red)
                
                Text(rfid.acessoLiberado ? "CasaGuard" : "Acesso bloqueado")
                    .font(.largeTitle)
                    .bold()
                
                Text(rfid.status)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                
                
            }
            .padding()
            .onAppear {
                rfid.conectar()
            }
            .onDisappear {
                rfid.desconectar()
            }
        }
    }
}

#Preview {
    ContentView()
}
