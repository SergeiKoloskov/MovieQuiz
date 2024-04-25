import UIKit

final class MovieQuizViewController: UIViewController, QuestionFactoryDelegate {
    
    // MARK: - IBOutlets
    @IBOutlet private weak var yesButton: UIButton!
    @IBOutlet private weak var noButton: UIButton!
    
    @IBOutlet private weak var counterLabel: UILabel!
    @IBOutlet private weak var textLabel: UILabel!
    @IBOutlet private weak var imageView: UIImageView!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    //MARK: - Properties
    private var correctAnswers: Int = 0
    private var questionFactory: QuestionFactoryProtocol?
    private var alertPresenter: AlertPresenterProtocol?
    private var statisticService: StatisticService?
    private let presenter = MovieQuizPresenter()
    
    private let dateFormatter = DateFormatter()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        presenter.viewController = self
        dateFormatter.dateFormat = "dd.MM.yyyy HH:mm"
        
        uiAdjusments()
        
        let questionFactory = QuestionFactory(moviesLoader: MoviesLoader(), delegate: self)
        self.questionFactory = questionFactory
        
        showLoadingIndicator()
        questionFactory.loadData()
        questionFactory.setup(delegate: self)
        questionFactory.requestNextQuestion()
        
        alertPresenter = AlertPresenter(delegate: self)
        statisticService = StatisticServiceImplementation()
    }
    
    // MARK: - IBActions
    @IBAction private func yesButtonClicked(_ sender: UIButton) {
        presenter.yesButtonClicked()
    }
    
    @IBAction private func noButtonClicked(_ sender: Any) {
        presenter.noButtonClicked()
    }
    
    
    // MARK: - QuestionFactoryDelegate
    func didReceiveNextQuestion(question: QuizQuestion?) {
        presenter.didRecieveNextQuestion(question: question)
        activityIndicator.isHidden = true
    }
    
    func didLoadDataFromServer() {
        activityIndicator.isHidden = true
        questionFactory?.requestNextQuestion()
    }
    
    func didFailToLoadData(with error: Error) {
        showNetworkError(message: error.localizedDescription)
    }
    
    func didFailToLoadImage(with error: Error) {
        showNetworkError(message: error.localizedDescription)
    }
    
    
    // MARK: - Private Methods
    func showAnswerResult(isCorrect: Bool) {
        changeStateButton(isEnabled: false)
        if isCorrect {
            correctAnswers += 1
        }
        
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 8
        imageView.layer.borderColor = isCorrect ? UIColor.ypGreen.cgColor : UIColor.ypRed.cgColor
        imageView.layer.cornerRadius = 20
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            
            self.showNextQuestionOrResults()
            self.changeStateButton(isEnabled: true)
        }
    }
    
    private func show(quiz step: QuizStepViewModel) {
        imageView.image = step.image
        textLabel.text = step.question
        counterLabel.text = step.questionNumber
    }
    
    private func showNextQuestionOrResults() {
        imageView.layer.borderWidth = 0
        
        if presenter.isLastQuestion() {
            statisticService?.store(correct: correctAnswers, total: presenter.questionsAmount)
            let statisticsText = getStatisticsText()
            
            let text = correctAnswers == presenter.questionsAmount ?
            "Поздравляем, вы ответили на \(correctAnswers) из \(questionsAmount)!" :
            "Ваш результат: \(correctAnswers)/\(presenter.questionsAmount)"// 1
            
            let finalText = "\(text)\n\(statisticsText)"
            
            let alertModel = AlertModel(
                title: "Этот раунд окончен!",
                message: finalText,
                buttonText: "Сыграть еще раз") { [weak self] in
                    guard let self = self else { return }
                    self.currentQuestionIndex = 0
                    self.correctAnswers = 0
                    questionFactory?.requestNextQuestion()
                }
            alertPresenter?.show(quiz: alertModel)
        } else {
            currentQuestionIndex += 1
            self.questionFactory?.requestNextQuestion()
        }
    }
    
    // MARK: - Network Error
    private func showNetworkError(message: String) {
        DispatchQueue.main.async {
            self.activityIndicator.isHidden = true
            
            let viewModel = AlertModel(
                title: "Ошибка",
                message: message,
                buttonText: "Попробовать еще раз") { [weak self] in
                    guard let self = self else { return }
                    self.questionFactory?.loadData()
                    self.questionFactory?.requestNextQuestion()
                }
            self.alertPresenter?.show(quiz: viewModel)
        }
    }
    
    // MARK: - Helpers Private Methods
    private func uiAdjusments() {
        yesButton.layer.cornerRadius = 15.0
        noButton.layer.cornerRadius = 15.0
        imageView.layer.cornerRadius = 20
    }
    
    private func showLoadingIndicator() {
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
    }
    
    private func hideLoadingIndicator() {
        activityIndicator.isHidden = true
        activityIndicator.stopAnimating()
    }
    
    private func changeStateButton(isEnabled: Bool) {
        noButton.isEnabled = isEnabled
        yesButton.isEnabled = isEnabled
    }
    
    private func getStatisticsText() -> String {
        guard let statisticService = statisticService else {
            return "Возникла ошибка при загрузке статистики"
        }
        
        let gamePlayed = statisticService.gamesCount
        let bestGameScore = "\(statisticService.bestGame.correct)/\(statisticService.bestGame.total)"
        let bestGameDate = dateFormatter.string(from: statisticService.bestGame.date)
        let accuracy = String(format: "%.2f%%", statisticService.totalAccuracy * 100)
        
        return """
        Количество сыгранных квизов: \(gamePlayed)
        Рекорд: \(bestGameScore) (\(bestGameDate))
        Средняя точность: \(accuracy)
        """
    }
    
}
