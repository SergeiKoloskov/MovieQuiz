//
//  QuestionFactoryDelegate.swift
//  MovieQuiz
//
//  Created by MacBookPro on 20.04.2024.
//

import Foundation

protocol QuestionFactoryDelegate: AnyObject {
    func didRecieveNextQuestion(question: QuizQuestion?)
    func didLoadDataFromServer()
    func didFailToLoadData(with error: Error)
}
