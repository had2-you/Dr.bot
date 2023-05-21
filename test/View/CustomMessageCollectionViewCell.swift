import UIKit
import MessageKit



class CustomMessageCollectionViewCell: UICollectionViewCell, MessageType {

    
    var messageLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.textColor = .white
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    var messageContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.blue
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupSubviews()
    }

    private func setupSubviews() {
        contentView.addSubview(messageContainer)
        messageContainer.addSubview(messageLabel)

        NSLayoutConstraint.activate([
            messageContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            messageContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            messageContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            messageContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            messageLabel.topAnchor.constraint(equalTo: messageContainer.topAnchor, constant: 8),
            messageLabel.leadingAnchor.constraint(equalTo: messageContainer.leadingAnchor, constant: 8),
            messageLabel.trailingAnchor.constraint(equalTo: messageContainer.trailingAnchor, constant: -8),
            messageLabel.bottomAnchor.constraint(equalTo: messageContainer.bottomAnchor, constant: -8)
        ])
    }

    // MessageType protocol properties

    var sender: SenderType {
        return Sender(senderId: "user_id", displayName: "User")
    }

    var messageId: String {
        return UUID().uuidString
    }

    var sentDate: Date {
        return Date()
    }

    var kind: MessageKind {
        return .custom(self)
    }
}

