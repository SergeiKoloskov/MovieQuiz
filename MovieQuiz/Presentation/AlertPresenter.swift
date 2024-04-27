import UIKit

// MARK: - AlertPresenter Declaration

final class AlertPresenter: AlertPresenterProtocol {
    
    weak var delegate: UIViewController?
    
    // MARK: - Initializer
    
    init(delegate: UIViewController) {
        self.delegate = delegate
    }

    func show(quiz model: AlertModel) {
        let alert = UIAlertController(
            title: model.title,
            message: model.message,
            preferredStyle: .alert)
        let action = UIAlertAction(title: model.buttonText, style: .default) { _ in
            model.copmpletion()
        }
        
        alert.addAction(action)
        delegate?.present(alert, animated: true, completion: nil)
    }
}

