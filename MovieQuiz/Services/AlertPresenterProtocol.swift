//
//  AlertPresenterDelegate.swift
//  MovieQuiz
//
//  Created by MacBookPro on 20.04.2024.
//

import Foundation

protocol AlertPresenterProtocol: AnyObject {
    func show(quiz model: AlertModel)
}
