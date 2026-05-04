//
//  XKLimiter.swift
//  XKLimiter
//
//  Created by Kenneth Tse on 2026/5/3.
//

import UIKit

public enum XKLimiterFilterOption: Equatable {
    case emoji
    case excludeChinese
    case numberOnly
    case chineseOnly
    case numberAndDecimal
}

@objcMembers
public final class XKLimiter: NSObject {
    private static let chineseRegex = #"[\u{4E00}-\u{9FA5}]"#

    private var validCharacters: String?
    private var regex: String?
    private var observers: [NSObjectProtocol] = []

    public var maxLength: Int = 0
    public var filterOptions: [XKLimiterFilterOption] = []

    public var getCurrentLength: CurrentLengthHandler?
    public var textCallback: ((String?) -> Void)?
    
    public override init() {
        super.init()
    }

    deinit {
        stopLimiting()
    }
}

public extension XKLimiter {
    typealias CurrentLengthHandler = (AnyObject, Int) -> Void

    func starLimitingTextField(_ textField: UITextField) {
        startLimiting(textField)
    }

    func starLimitingTextView(_ textView: UITextView) {
        startLimiting(textView)
    }

    func stopLimitingObserver() {
        stopLimiting()
    }

    func fliterWithValidCharacters(_ validCharacters: String) {
        filterWithValidCharacters(validCharacters)
    }

    func fliterWithRegex(_ regex: String) {
        filterWithRegex(regex)
    }

    func setFilterOptions(_ options: [XKLimiterFilterOption]) {
        filterOptions = options
    }

    func filterWithValidCharacters(_ validCharacters: String) {
        self.validCharacters = validCharacters
    }

    func filterWithRegex(_ regex: String) {
        self.regex = regex
    }
}

private extension XKLimiter {
    func startLimiting(_ limitedObject: AnyObject) {
        if let textField = limitedObject as? UITextField {
            let observer = NotificationCenter.default.addObserver(
                forName: UITextField.textDidChangeNotification,
                object: textField,
                queue: .main
            ) { [weak self] notification in
                self?.textFieldEditChanged(notification)
            }
            observers.append(observer)
            return
        }

        if let textView = limitedObject as? UITextView {
            let observer = NotificationCenter.default.addObserver(
                forName: UITextView.textDidChangeNotification,
                object: textView,
                queue: .main
            ) { [weak self] notification in
                self?.textViewEditChanged(notification)
            }
            observers.append(observer)
        }
    }

    func stopLimiting() {
        observers.forEach(NotificationCenter.default.removeObserver)
        observers.removeAll()
    }

    func textViewEditChanged(_ notification: Notification) {
        guard let textView = notification.object as? UITextView else { return }
        guard !hasMarkedText(in: textView) else { return }

        textView.text = handleFilterCase(with: textView)
        getCurrentLength?(textView, textView.text.count)
    }

    func textFieldEditChanged(_ notification: Notification) {
        guard let textField = notification.object as? UITextField else { return }
        guard !hasMarkedText(in: textField) else { return }

        textField.text = handleFilterCase(with: textField)
        getCurrentLength?(textField, textField.text?.count ?? 0)
        textCallback?(textField.text)
    }

    func handleFilterCase(with limitedObject: AnyObject) -> String {
        var validText = text(from: limitedObject)

        if maxLength > 0 {
            validText = handleLengthLimit(for: limitedObject, validText: validText)
        }

        validText = applyFilterOptions(to: validText)

        if let validCharacters {
            validText = validText.filter { validCharacters.contains($0) }
        }

        if let regex {
            validText = filter(validText, keepingMatchesFor: regex)
        }

        return validText
    }

    func handleLengthLimit(for limitedObject: AnyObject, validText: String) -> String {
        guard !hasMarkedText(in: limitedObject) else {
            return validText
        }

        guard validText.count > maxLength else {
            return validText
        }

        return String(validText.prefix(maxLength))
    }

    func applyFilterOptions(to text: String) -> String {
        var validText = text

        if filterOptions.contains(.emoji) {
            validText = filterEmoji(in: validText)
        }

        if filterOptions.contains(.chineseOnly) {
            validText = filter(validText, keepingMatchesFor: Self.chineseRegex)
        } else if filterOptions.contains(.excludeChinese) {
            validText = filter(validText, removingMatchesFor: Self.chineseRegex)
        }

        if filterOptions.contains(.numberOnly) {
            validText = validText.filter { "0123456789".contains($0) }
        } else if filterOptions.contains(.numberAndDecimal) {
            validText = validText.filter { "0123456789.".contains($0) }
        }

        return validText
    }

    func filter(_ text: String, removingMatchesFor regex: String) -> String {
        text.filter { !matchesRegex(String($0), regex: regex) }
    }

    func filter(_ text: String, keepingMatchesFor regex: String) -> String {
        text.filter { matchesRegex(String($0), regex: regex) }
    }

    func filterEmoji(in text: String) -> String {
        text.filter { !isEmoji($0) }
    }

    func matchesRegex(_ string: String, regex: String) -> Bool {
        string.range(of: regex, options: .regularExpression) != nil
    }

    func isEmoji(_ character: Character) -> Bool {
        let scalars = String(character).unicodeScalars

        for scalar in scalars {
            let value = scalar.value

            if (0xFE00...0xFE0F).contains(value) || value == 0x200D {
                return true
            }

            if (0x1D000...0x1F9FF).contains(value) || (0x2100...0x27BF).contains(value) {
                return true
            }
        }

        return false
    }

    func text(from limitedObject: AnyObject) -> String {
        if let textField = limitedObject as? UITextField {
            return textField.text ?? ""
        }

        if let textView = limitedObject as? UITextView {
            return textView.text
        }

        return ""
    }

    func hasMarkedText(in limitedObject: AnyObject) -> Bool {
        if let textField = limitedObject as? UITextField {
            guard let selectedRange = textField.markedTextRange else { return false }
            return textField.text(in: selectedRange)?.isEmpty == false
        }

        if let textView = limitedObject as? UITextView {
            guard let selectedRange = textView.markedTextRange else { return false }
            return textView.text(in: selectedRange)?.isEmpty == false
        }

        return false
    }
}
