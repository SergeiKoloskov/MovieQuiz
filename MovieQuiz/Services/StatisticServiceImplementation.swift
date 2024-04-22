//
//  StatisticServiceImplementation.swift
//  MovieQuiz
//
//  Created by MacBookPro on 21.04.2024.
//

import Foundation

final class StatisticServiceImplementation: StatisticService {
    // MARK: - Keys Enum
    private enum Keys: String {
        case correct, total, bestGame, gamesCount, totalAccuracy
    }
    
    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    
    private var correct: Int {
        get {
            return userDefaults.integer(forKey: Keys.correct.rawValue)
        }
        set {
            userDefaults.set(newValue, forKey: Keys.correct.rawValue)
        }
    }
    
    private var total: Int {
        get {
            return userDefaults.integer(forKey: Keys.total.rawValue)
        }
        set {
            userDefaults.set(newValue, forKey: Keys.total.rawValue)
        }
    }
    
    var gamesCount: Int {
        get {
            return userDefaults.integer(forKey: Keys.gamesCount.rawValue)
        }
        set {
            userDefaults.set(newValue, forKey: Keys.gamesCount.rawValue)
        }
    }
    
    var bestGame: GameRecord {
        get {
            guard let data = userDefaults.data(forKey: Keys.bestGame.rawValue),
                  let record = try? JSONDecoder().decode(GameRecord.self, from: data) else {
                return .init(correct: 0, total: 0, date: Date())
            }
            return record
        }
        set {
            guard let data = try? JSONEncoder().encode(newValue) else {
                print("Невозможно сохранить результат")
                return
            }
            userDefaults.set(data, forKey: Keys.bestGame.rawValue)
        }
    }
    
    var totalAccuracy: Double {
        get {
            return Double(correct) / Double(total)
        }
        set {
            userDefaults.set(newValue, forKey: Keys.totalAccuracy.rawValue)
        }
    }
    
    // MARK: - Functions
    func store(correct count: Int, total amount: Int) {
        let newCorrect = self.correct + count
        let newTotal = self.total + amount
        let newGamesCount = gamesCount + 1
        
        let potentialRecord = GameRecord(correct: count, total: amount, date: Date())
        if potentialRecord.isBetterThan(bestGame) {
            bestGame = potentialRecord
        }
        
        userDefaults.set(newCorrect, forKey: Keys.correct.rawValue)
        userDefaults.set(newTotal, forKey: Keys.total.rawValue)
        userDefaults.set(newGamesCount, forKey: Keys.gamesCount.rawValue)
    }
}
