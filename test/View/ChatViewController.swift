

import UIKit
import MessageKit
import InputBarAccessoryView
import OpenAISwift
import FirebaseFirestore
import Firebase

class ChatViewController: MessagesViewController {
    
    private var messages: [MessageType] = []
    private let apiKey = "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"
    private let botSender = Sender(senderId: "bot_id", displayName: "Bot")
    private let openAI = OpenAISwift(authToken: "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")
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self
        
        // Initialize messagesCollectionView
        messagesCollectionView.backgroundColor = .white

        // Set up messageInputBar
        messageInputBar.inputTextView.placeholder = "질문하실 내용을 입력하세요."
        messageInputBar.sendButton.setTitleColor(.systemBlue, for: .normal)
        messageInputBar.sendButton.setTitleColor(
            UIColor.systemBlue.withAlphaComponent(0.3),
            for: .highlighted
        )
        messageInputBar.sendButton.isEnabled = false
        
        // Remove the padding around the textView
        messageInputBar.inputTextView.textContainerInset = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        messageInputBar.backgroundView.backgroundColor = .white
        messageInputBar.separatorLine.isHidden = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        messagesCollectionView.addGestureRecognizer(tapGesture)
    }
    
    @objc private func dismissKeyboard(){
        view.endEditing(true)
    }
}


extension ChatViewController: MessagesDataSource {
    var currentSender: SenderType {
        return Sender(senderId: "user_id", displayName: "User")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, h:mm a"
        let dateString = dateFormatter.string(from: message.sentDate)
        return NSAttributedString(string: dateString, attributes: [.font: UIFont.boldSystemFont(ofSize: 12), .foregroundColor: UIColor.darkGray])
    }
    
    func messageBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        return nil
    }
    
    func messageTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        return nil
    }
}

extension ChatViewController: MessagesLayoutDelegate, MessagesDisplayDelegate {
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        let avatar: Avatar
        
        if message.sender.senderId == botSender.senderId {
            let botImage = UIImage(named: "bot_profile")
            avatar = Avatar(image: botImage)
            avatarView.backgroundColor = UIColor(hex: "#F2F8FF")

        } else {
            let userImage = UIImage(named: "user_profile")
            avatar = Avatar(image: userImage)
        }
        
        avatarView.set(avatar: avatar)
    }
    
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        // Check if the message is from the bot
        if message.sender.senderId == botSender.senderId {
            // Return the desired bot message style
            return MessageStyle.bubbleTail(.bottomLeft, .pointedEdge)

        } else {
            // Return the desired user message style
            return MessageStyle.bubbleTail(.bottomRight, .pointedEdge)
                
        }
    }
    
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        // Check if the message is from the bot
        if message.sender.senderId == botSender.senderId {
            // Return the desired bot bubble color
            return UIColor(hex: "#F2F4F5")
        } else {
            // Return the desired user bubble color
            return UIColor(hex: "#0070F0")
        }
    }

    
    
}


extension ChatViewController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        let message = Message(text: text, sender: currentSender, messageId: UUID().uuidString, date: Date())
        messages.append(message)
        inputBar.inputTextView.text = ""
        messagesCollectionView.reloadData()
        
        async {
            do {
                let result = try await self.openAI.sendChat(with: [ChatMessage(role: .system, content: text)])
                if let botResponse = result.choices?.first?.message.content {
                    self.saveMessageToFirebase(message: message, botResponse: botResponse)
                    print("사용자: " + text)
                    print("챗봇: " + botResponse)
                    DispatchQueue.main.async {
                        self.messagesCollectionView.reloadData()
                        self.messagesCollectionView.scrollToLastItem()
                    }
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    // Save message to Firestore
    func saveMessageToFirebase(message: Message, botResponse: String) {
        let botMessage = Message(text: botResponse, sender: botSender, messageId: UUID().uuidString, date: Date())
        messages.append(botMessage)
        
        let database = Firestore.firestore()
        let chatData: [String: Any] = [
            "senderId": message.sender.senderId,
            "senderName": message.sender.displayName,
            "messageId": message.messageId,
            "sentDate": message.sentDate.timeIntervalSince1970,
            "text": {
                if case let .text(text) = message.kind {
                    return text
                } else {
                    return ""
                }
            }(),
            "botResponse": botResponse
        ]
        
        database.collection("chats").addDocument(data: chatData) { error in
            if let error = error {
                print("Error saving message to Firestore: \(error)")
            } else {
                print("Message saved to Firestore")
            }
        }
    }
}

extension UIColor {
    convenience init(hex: String, alpha: CGFloat = 1.0) {
        let hexString = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var intValue: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&intValue)

        let red = CGFloat((intValue & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((intValue & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(intValue & 0x0000FF) / 255.0

        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
