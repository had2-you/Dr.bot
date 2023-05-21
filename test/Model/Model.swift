import UIKit
import MessageKit
import InputBarAccessoryView
import OpenAISwift


struct Sender: SenderType {
    var senderId: String
    var displayName: String
}

struct Message: MessageType {
    var sender: SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKind

    init(sender: SenderType, messageId: String, sentDate: Date, kind: MessageKind) {
        self.sender = sender
        self.messageId = messageId
        self.sentDate = sentDate
        self.kind = kind
    }

    init(text: String, sender: SenderType, messageId: String, date: Date) {
        self.init(sender: sender, messageId: messageId, sentDate: date, kind: .text(text))
    }
}
