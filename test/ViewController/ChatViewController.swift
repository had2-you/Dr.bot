import UIKit
import MessageKit
import InputBarAccessoryView
import OpenAISwift
import FirebaseFirestore
import Firebase

class ChatViewController: MessagesViewController, UISearchBarDelegate {
    
    private var messages: [MessageType] = []
    private let botSender = Sender(senderId: "bot_id", displayName: "Bot")
    private let openAI = OpenAISwift(authToken: "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")
    
    // MARK: - searchBar
    private let searchBar: UISearchBar = {
        let bounds = UIScreen.main.bounds
        let width = bounds.size.width // 화면 너비
        let searchBar = UISearchBar(frame: CGRect(x: 0, y: 0, width: width - 28, height: 0))
        searchBar.placeholder = "이전 대화를 검색하세요"
        searchBar.showsCancelButton = true
        
        return searchBar
    }()
    
    // MARK: - loadingIndicator
    private var isLoading = false
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .gray
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self
        
        loadPreviousMessages()

        // MARK: - loadingIndicator

        view.addSubview(loadingIndicator)
        loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        // MARK: - messageInputBar
        messagesCollectionView.backgroundColor = .white

        // 메세지 바 초기화
        messageInputBar.inputTextView.placeholder = "질문하실 내용을 입력하세요."
        messageInputBar.sendButton.setTitleColor(.systemBlue, for: .normal)
        messageInputBar.sendButton.setTitleColor(
            UIColor.systemBlue.withAlphaComponent(0.3),
            for: .highlighted
        )
        messageInputBar.sendButton.isEnabled = false
        
        // 여백제거
        messageInputBar.inputTextView.textContainerInset = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        messageInputBar.backgroundView.backgroundColor = .white
        messageInputBar.separatorLine.isHidden = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        messagesCollectionView.addGestureRecognizer(tapGesture)
        
        // MARK: - searchBar

        // 네비게이션 바 오른쪽에 돋보기 버튼 추가
        let searchButton = UIBarButtonItem(image: UIImage(systemName: "magnifyingglass"), style: .plain, target: self, action: #selector(searchButtonTapped))
        navigationItem.rightBarButtonItem = searchButton
        
        // 써치바 초기화
        searchBar.delegate = self
        searchBar.isHidden = true
        searchBar.showsCancelButton = true
        
        // 써치바를 네비게이션 바의 타이틀 뷰로 설정
        navigationItem.titleView = searchBar
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.isHidden = true
        searchBar.text = ""
        searchBar.resignFirstResponder()
        navigationItem.title = "Dr.Bot" // 안됨
        loadPreviousMessages()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let searchText = searchBar.text, !searchText.isEmpty else {
            return
        }
        
        searchBar.resignFirstResponder()
        
        // 이전 메시지 중 검색어를 포함하는 메시지 필터링
        let filteredMessages = messages.filter { message in
            if case let .text(text) = message.kind {
                return text.localizedCaseInsensitiveContains(searchText)
            }
            return false
        }
        
        messages = filteredMessages
        
        messagesCollectionView.reloadData()
        messagesCollectionView.scrollToLastItem(animated: false)
    }


    
    // MARK: - objc func

    @objc private func dismissKeyboard(){
        view.endEditing(true)
    }
    
    @objc private func searchButtonTapped() {
        searchBar.isHidden = false
        searchBar.becomeFirstResponder()
        navigationItem.titleView = searchBar
    }
}


// MARK: - 확장

extension ChatViewController: MessagesDataSource {
    var currentSender: SenderType {
        return Sender(senderId: Auth.auth().currentUser?.uid ?? "", displayName: "User")
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
    
    func messageContainerSize(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGSize {
        let maxWidth = messagesCollectionView.bounds.width // 최대 가로 길이 설정
        let maxHeight: CGFloat = 200 // 최대 세로 길이 설정
        let contentInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        
        // 메시지 내용에 따라서 최대 길이 조정
        if case let .text(text) = message.kind {
            let messageLabel = UILabel()
            messageLabel.text = text
            messageLabel.numberOfLines = 0
            messageLabel.lineBreakMode = .byWordWrapping
            messageLabel.font = UIFont.systemFont(ofSize: 17)
            
            let messageContainerWidth = maxWidth - contentInsets.left - contentInsets.right
            let messageSize = messageLabel.sizeThatFits(CGSize(width: messageContainerWidth, height: .greatestFiniteMagnitude))
            
            return CGSize(width: min(messageSize.width, messageContainerWidth), height: min(messageSize.height, maxHeight))
        }        
        return CGSize(width: 0, height: 0)
        
    }
    
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
    
    func loadPreviousMessages() {
        guard let currentUser = Auth.auth().currentUser else {
            return
        }
        
        let database = Firestore.firestore()
        let query = database.collection("chats")
            .whereField("senderId", isEqualTo: currentUser.uid)
            .order(by: "sentDate")
        
        query.getDocuments { [weak self] (snapshot, error) in
            guard let self = self, let snapshot = snapshot else {
                if let error = error {
                    print("Error messages: \(error)")
                }
                return
            }
            
            self.messages.removeAll() // 기존 메시지 삭제
            
            for document in snapshot.documents {
                let data = document.data()
                
                guard let senderId = data["senderId"] as? String,
                      let senderName = data["senderName"] as? String,
                      let messageId = data["messageId"] as? String,
                      let sentDateTimestamp = data["sentDate"] as? TimeInterval,
                      let text = data["text"] as? String,
                      let botResponse = data["botResponse"] as? String else {
                    continue
                }
                
                let sender: Sender
                if senderId == currentUser.uid {
                    sender = Sender(senderId: senderId, displayName: "User")
                } else {
                    sender = Sender(senderId: senderId, displayName: "Bot")
                }
                
                let sentDate = Date(timeIntervalSince1970: sentDateTimestamp)
                let message = Message(text: text, sender: sender, messageId: messageId, date: sentDate)
                let botMessage = Message(text: botResponse, sender: self.botSender, messageId: UUID().uuidString, date: sentDate)
                
                self.messages.append(message)
                self.messages.append(botMessage)
            }
            
            DispatchQueue.main.async {
                self.messagesCollectionView.reloadData()
                self.messagesCollectionView.scrollToLastItem()
            }
        }
    }


    
    // 동적 말풍선 너비 조절
//    func messageContainerSize(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGSize {
//        let maxWidth = messagesCollectionView.bounds.width * 0.7 // 최대 너비 설정
//        let contentInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8) // 여백 설정
//
//        let messageContent: String
//        switch message.kind {
//        case .text(let text):
//            messageContent = text
//        default:
//            messageContent = ""
//        }
//
//        let label = MessageLabel()
//        label.numberOfLines = 0
//        label.text = messageContent
//        label.font = UIFont.preferredFont(forTextStyle: .body)
//        label.lineBreakMode = .byWordWrapping // 단어 래핑 설정 추가
//
//        let estimatedSize = label.sizeThatFits(CGSize(width: maxWidth - contentInsets.left - contentInsets.right, height: .greatestFiniteMagnitude))
//        return CGSize(width: estimatedSize.width + contentInsets.left + contentInsets.right, height: estimatedSize.height + contentInsets.top + contentInsets.bottom)
//    }
}



extension ChatViewController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        if isLoading {
            return // 이미 로딩 중인 경우 중복 요청 방지
        }
        
        isLoading = true
        loadingIndicator.startAnimating()
        
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
                        self.loadingIndicator.stopAnimating()
                        self.isLoading = false
                    }
                }
            } catch {
                print(error.localizedDescription)
                DispatchQueue.main.async {
                    self.loadingIndicator.stopAnimating()
                    self.isLoading = false
                }
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
