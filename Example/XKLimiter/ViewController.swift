//
//  ViewController.swift
//  XKLimiter
//
//  Created by kunhum on 05/03/2026.
//  Copyright (c) 2026 kunhum. All rights reserved.
//

import UIKit
import XKLimiter

final class ViewController: UIViewController {
    private let limiter = XKLimiter()
    private let numberLimiter = XKLimiter()

    private lazy var textField: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .roundedRect
        textField.placeholder = "只允许数字，最多 6 位"
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()

    private lazy var textView: UITextView = {
        let textView = UITextView()
        textView.layer.borderWidth = 1
        textView.layer.borderColor = Self.borderColor.cgColor
        textView.layer.cornerRadius = 10
        textView.font = .systemFont(ofSize: 16)
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()

    private lazy var countLabel: UILabel = {
        let label = UILabel()
        label.textColor = Self.secondaryTextColor
        label.font = .systemFont(ofSize: 14)
        label.text = "当前长度: 0"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Self.backgroundColor
        title = "XKLimiter"
        setupViews()
        setupLimiter()
    }

    private static var borderColor: UIColor {
        if #available(iOS 13.0, *) {
            return .systemGray4
        }
        return .lightGray
    }

    private static var secondaryTextColor: UIColor {
        if #available(iOS 13.0, *) {
            return .secondaryLabel
        }
        return .gray
    }

    private static var backgroundColor: UIColor {
        if #available(iOS 13.0, *) {
            return .systemBackground
        }
        return .white
    }

    private func setupViews() {
        view.addSubview(textField)
        view.addSubview(textView)
        view.addSubview(countLabel)

        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            textField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            textField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            textView.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 20),
            textView.leadingAnchor.constraint(equalTo: textField.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: textField.trailingAnchor),
            textView.heightAnchor.constraint(equalToConstant: 160),

            countLabel.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 12),
            countLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor)
        ])
    }

    private func setupLimiter() {
        limiter.maxLength = 12
        limiter.filterOptions = [.emoji]
        limiter.getCurrentLength = { [weak self] object, length in
            guard object is UITextView else { return }
            self?.countLabel.text = "当前长度: \(length)"
        }
        limiter.starLimitingTextView(textView)

        numberLimiter.maxLength = 6
        numberLimiter.filterOptions = [.numberOnly]
        numberLimiter.starLimitingTextField(textField)
    }
}
