//
//  StatisticService.swift
//  MovieQuiz
//
//  Created by MacBookPro on 21.04.2024.
//

import Foundation

protocol StatisticService {
    func store(correct count: Int, total amount: Int)
    var gamesCount: Int { get }
    var bestGame: GameRecord { get }
    var totalAccuracy: Double { get }
}
