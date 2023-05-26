
import UIKit
import MessageKit
import InputBarAccessoryView
import OpenAISwift
import FirebaseFirestore
import Firebase


class ChatViewController: MessagesViewController {
    
    
    private var messages: [Message] = []
    private let apiKey = "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"
    private let botSender = Sender(senderId: "bot_id", displayName: "Bot")
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        messagesCollectionView.dataSource = self
        messagesCollectionView.delegate = self
        messageInputBar.delegate = self
        
        // Initialize messagesCollectionView
        messagesCollectionView.backgroundColor = .white
        
        // Register MessageCell
        messagesCollectionView.register(CustomMessageCollectionViewCell.self, forCellWithReuseIdentifier: "CustomMessageCell")
        
        
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
    
    func customCell(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UICollectionViewCell? {
        if let customMessage = message as? CustomMessageCollectionViewCell {
            let cell = messagesCollectionView.dequeueReusableCell(withReuseIdentifier: "CustomMessageCell", for: indexPath) as! CustomMessageCollectionViewCell
            // 커스텀 메시지 셀의 속성 설정
            cell.messageLabel.text = customMessage.messageLabel.text
            // 추가적인 커스터마이징 작업
            return cell
        }
        return nil
    }
    
    
    
    
}

// Message Layout 구현부
extension ChatViewController: MessagesDisplayDelegate, MessagesLayoutDelegate {}


let openAI = OpenAISwift(authToken: "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")

extension ChatViewController: InputBarAccessoryViewDelegate {

    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        let message = Message(text: text, sender: currentSender, messageId: UUID().uuidString, date: Date())
        messages.append(message)
        messagesCollectionView.reloadData()
        inputBar.inputTextView.text = ""

        async {
            do {
                let result = try await openAI.sendChat(with: [ChatMessage(role: .system, content: text)])
                if let botResponse = result.choices?.first?.message.content {
                    self.saveMessageToFirebase(message: message, botResponse: botResponse)
                    print("사용자 : " + text)
                    print("챗봇 : " + botResponse)
                }
            } catch {
                print(error.localizedDescription)
            }

            DispatchQueue.main.async {
                self.messagesCollectionView.reloadData()
            }
        }
    }
    
    // Save message to Firebase Realtime Database
    func saveMessageToFirebase(message: Message, botResponse: String) {
        let database = Database.database()
        let ref = database.reference()

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

        ref.child("chats").childByAutoId().setValue(chatData) { (error, _) in
            if let error = error {
                print("Error saving message to Firebase: \(error)")
            } else {
                print("Message saved to Firebase")
            }
        }
    }
}

