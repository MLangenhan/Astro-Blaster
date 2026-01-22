//
//  PlayerService.swift
//  Astro Blaster
//
//  Created by Moritz Langenhan on 20.01.26.
//

import Foundation
final class BackendService {
    private let baseURL = URL(string: "http://192.168.0.205:3000")!
    
    func fetchArenaHighscores(arenaId: String) async throws -> [ScoreEntry] {
        let url = baseURL.appendingPathComponent("/scores/arena/\(arenaId)")
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([ScoreEntry].self, from: data)
    }
    
    func submitScore(score: ScoreEntry) async throws {
        let url = baseURL.appendingPathComponent("scores")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(score)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }

}
