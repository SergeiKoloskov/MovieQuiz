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
    private var currentQuestionIndex: Int = 0
    private var correctAnswers: Int = 0
    private let questionsAmount: Int = 10
    private var questionFactory: QuestionFactoryProtocol?
    private var currentQuestion: QuizQuestion?
    private var alertPresenter: AlertPresenterProtocol?
    private var statisticService: StatisticService?
    
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
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
    
    func uiAdjusments() {
        yesButton.layer.cornerRadius = 15.0
        noButton.layer.cornerRadius = 15.0
        imageView.layer.cornerRadius = 20
    }
    
    // MARK: - IBActions
    @IBAction private func yesButtonClicked(_ sender: Any) {
        guard let currentQuestion = currentQuestion else {
            return
        }
        let givenAnswer = true
        showAnswerResult(isCorrect: givenAnswer == currentQuestion.correctAnswer)
    }
    
    @IBAction private func noButtonClicked(_ sender: Any) {
        guard let currentQuestion = currentQuestion else {
            return
        }
        let givenAnswer = false
        showAnswerResult(isCorrect: givenAnswer == currentQuestion.correctAnswer)
    }
    
    
    // MARK: - QuestionFactoryDelegate
    func didReceiveNextQuestion(question: QuizQuestion?) {
        guard let question = question else { return }

        currentQuestion = question
        let viewModel = convert(model: question)
        DispatchQueue.main.async { [weak self] in
            self?.show(quiz: viewModel)
        }
        activityIndicator.isHidden = true
    }
    
    
    // MARK: - Private functions
    private func showAnswerResult(isCorrect: Bool) {
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
    
    private func changeStateButton(isEnabled: Bool) {
        noButton.isEnabled = isEnabled
        yesButton.isEnabled = isEnabled
    }
    
    private func convert(model: QuizQuestion) -> QuizStepViewModel {
        return QuizStepViewModel(
            image: UIImage(data: model.image) ?? UIImage(),
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)")
    }
    
    private func show(quiz step: QuizStepViewModel) {
        imageView.image = step.image
        textLabel.text = step.question
        counterLabel.text = step.questionNumber
    }
    
    private func showNextQuestionOrResults() {
        imageView.layer.borderWidth = 0
        
        if currentQuestionIndex == questionsAmount - 1 {
            statisticService?.store(correct: correctAnswers, total: questionsAmount)
            let statisticsText = getStatisticsText()
            
            let text = correctAnswers == questionsAmount ?
            "Поздравляем, вы ответили на \(correctAnswers) из \(questionsAmount)!" :
            "Ваш результат: \(correctAnswers)/\(questionsAmount)"// 1
            
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
    
    private func getStatisticsText() -> String {
        guard let statisticService = statisticService else {
            return "Возникла ошибка при загрузке статистики"
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy HH:mm"
        
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
    private func showLoadingIndicator() {
        activityIndicator.isHidden = false // говорим, что индикатор загрузки не скрыт
        activityIndicator.startAnimating() // включаем анимацию
    }
    
    private func hideLoadingIndicator() {
        activityIndicator.isHidden = true
        activityIndicator.stopAnimating()
    }
    
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
    
    func didLoadDataFromServer() {
        activityIndicator.isHidden = true
        questionFactory?.requestNextQuestion()
    }

    func didFailToLoadData(with error: Error) {
        showNetworkError(message: error.localizedDescription) // возьмём в качестве сообщения описание ошибки
    }
    
    func didFailToLoadImage(with error: Error) {
        showNetworkError(message: error.localizedDescription)
    }
    
    
}
