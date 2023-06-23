//
//  NetworkManager.swift
//  Tabby
//
//  Created by ilya.kuznetsov on 26.08.2021.
//

import Foundation

final class Api {
    static let shared = Api()
    
    private let createSessionUrlProd = "https://api.tabby.ai/api/v2/checkout"
    private let createSessionUrlStage = "https://api.tabby.dev/api/v2/checkout"
    
    private init() {}
    
    func createSession(payload: TabbyCheckoutPayload, apiKey: String, env: Env) async throws -> CheckoutSession {
        
        let createSessionUrl = env == .prod ? createSessionUrlProd : createSessionUrlStage
        guard let url = URL(string: createSessionUrl) else {
            throw CheckoutError.invalidUrl
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        var jsonBody: String = ""
        do {
            let jsonData = try JSONEncoder().encode(payload)
            jsonBody = String(data: jsonData, encoding: .utf8)!
        } catch {
            throw CheckoutError.invalidData
        }
        request.httpBody = jsonBody.data(using: String.Encoding.utf8)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                throw CheckoutError.invalidResponse
            }
            do {
                let decoder = JSONDecoder()
                let decodedResponse = try decoder.decode(CheckoutSession.self, from: data)
                return decodedResponse
            } catch {
                throw CheckoutError.unableToDecode
            }
        } catch {
            throw CheckoutError.unableToComplete
        }
    }
}
