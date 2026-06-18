//
//  webSocket.swift
//  projetoFinal websocket
//
//  Created by Turma02-18 on 18/06/26.
//

import SwiftUI
import Foundation
import Combine

struct LeituraRFID: Identifiable {
    let id = UUID()
    let data = Date()
    let uid: String
    let autorizado: Bool
}

class RFIDViewModel: ObservableObject {
    
    @Published var uidAtual = ""
    @Published var acessoLiberado = false
    @Published var status = "Aguardando tag RFID..."
    
    private var webSocketTask: URLSessionWebSocketTask?
    
    // IP da sua ESP
    let url = URL(string: "ws://192.168.128.88:81")!
    
    // Coloque aqui o UID da sua tag autorizada
    let tagAutorizada = "F3 1C 40 14"
    func conectar() {
        guard webSocketTask == nil else { return }
        
        webSocketTask = URLSession.shared.webSocketTask(with: url)
        webSocketTask?.resume()
        
        status = "Conectado. Aproxime a tag..."
        
        receber()
    }
    
    func desconectar() {
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
    }
    
    private func receber() {
        webSocketTask?.receive { [weak self] result in
            
            guard let self = self else { return }
            
            switch result {
                
            case .success(let message):
                
                switch message {
                    
                case .string(let texto):
                    self.processarMensagem(texto)
                    
                case .data(let data):
                    if let texto = String(data: data, encoding: .utf8) {
                        self.processarMensagem(texto)
                    }
                    
                @unknown default:
                    break
                }
                
                self.receber()
                
            case .failure(let erro):
                print("Erro WebSocket:", erro)
                
                DispatchQueue.main.async {
                    self.status = "Erro na conexão. Tentando reconectar..."
                    self.webSocketTask = nil
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.conectar()
                }
            }
        }
    }
    
    private func processarMensagem(_ texto: String) {
        
        print("Mensagem recebida:", texto)
        
        var uidRecebido = ""
        var autorizado = false
        
        // Caso a ESP envie JSON
        if let data = texto.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            
            uidRecebido = json["uid"] as? String ?? ""
            
            if let auth = json["autorizado"] as? Bool {
                autorizado = auth
            } else {
                autorizado = uidRecebido == tagAutorizada
            }
            
        } else {
            // Caso a ESP envie só o UID puro
            uidRecebido = texto.trimmingCharacters(in: .whitespacesAndNewlines)
            autorizado = uidRecebido == tagAutorizada
        }
        
        DispatchQueue.main.async {
            self.uidAtual = uidRecebido
            self.acessoLiberado = autorizado
            
            if autorizado {
                self.status = "Acesso liberado"
            } else {
                self.status = "Tag não autorizada"
            }
            
        }
    }
}
