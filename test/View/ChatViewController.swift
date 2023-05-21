
import UIKit
import MessageKit
import InputBarAccessoryView
import OpenAISwift



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

        // Send message to OpenAI API for processing
        openAI.sendCompletion(with: text) { result in // Result<OpenAI, OpenAIError>
            switch result {
            case .success(let success):
                print(success.choices?.first?.text ?? "")
            case .failure(let failure):
                print(failure.localizedDescription)
            }
        }
    }
}


