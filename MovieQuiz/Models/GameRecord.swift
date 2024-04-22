//
//  GameRecord.swift
//  MovieQuiz
//
//  Created by MacBookPro on 21.04.2024.
//

import Foundation

struct GameRecord: Codable {
    let correct: Int
    let total: Int
    let date: Date
    
    func isBetterThan(_ another: GameRecord) -> Bool {
        correct > another.correct
    }
}
