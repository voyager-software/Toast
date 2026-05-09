//  Toast.swift
//
//  Created by Gabor Sajo on 2020-05-29.
//  Copyright © 2020 Voyager. All rights reserved.

import Foundation
import UIKit
import NVActivityIndicatorView

public final class Toast: UIView {
    // MARK: Lifecycle

    public init(
        text: String,
        imageName: String,
        color: UIColor? = nil,
        withSpinner: Bool = false
    ) {
        super.init(frame: .zero)
        self.label.text = text
        self.color = color
        self.setup(imageName: imageName, withSpinner: withSpinner)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Public

    public static var iconTint: UIColor = .label
    public static var textColor: UIColor = .label
    public static var font: UIFont = .preferredFont(forTextStyle: .callout)

    public var text: String? {
        get { self.label.text }
        set { self.label.text = newValue }
    }

    public var color: UIColor? {
        get { self.effectView.backgroundColor }
        set { self.effectView.backgroundColor = newValue }
    }

    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if self.traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass ||
            self.traitCollection.verticalSizeClass != previousTraitCollection?.verticalSizeClass
        {
            self.updateConstraintsForCurrentSizeClass()
            self.updateTabBarPositionForOrientation()
        }
    }

    public func setImage(imageName: String) {
        self.imageView.image = UIImage(systemName: imageName)
    }

    // MARK: Internal

    var compactConstraints: [NSLayoutConstraint] = []
    var regularConstraints: [NSLayoutConstraint] = []
    var position: Position?
    var isAnchoredToTabBar = false

    func updateConstraintsForCurrentSizeClass() {
        NSLayoutConstraint.deactivate(self.compactConstraints + self.regularConstraints)

        if traitCollection.horizontalSizeClass == .compact {
            NSLayoutConstraint.activate(self.compactConstraints)
        }
        else {
            NSLayoutConstraint.activate(self.regularConstraints)
        }
    }

    // MARK: Private

    private static let spinnerSize: CGFloat = 20

    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 26, tvOS 26, *) {
            view.layer.cornerRadius = 23
        }
        else {
            view.layer.cornerRadius = 12
        }
        view.layer.cornerCurve = .continuous
        view.layer.borderColor = UIColor.systemGray.withAlphaComponent(0.25).cgColor
        view.layer.borderWidth = 1.0
        view.layer.masksToBounds = true
        return view
    }()

    private let effectView: UIVisualEffectView = {
        let effect = if #available(iOS 26, tvOS 26, *) {
            UIGlassEffect(style: .regular)
        }
        else {
            #if os(iOS)
            UIBlurEffect(style: .systemMaterial)
            #else
            UIBlurEffect(style: .prominent)
            #endif
        }
        let ev = UIVisualEffectView(effect: UIBlurEffect(style: .prominent))
        ev.translatesAutoresizingMaskIntoConstraints = false
        return ev
    }()

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 16
        return stack
    }()

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = Toast.iconTint
        imageView.contentMode = .scaleAspectFit
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 28),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor),
        ])
        return imageView
    }()

    private let label: UILabel = {
        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.font = Toast.font
        lbl.numberOfLines = 0
        lbl.textColor = Toast.textColor
        return lbl
    }()

    private lazy var spinner: NVActivityIndicatorView = {
        let frame = CGRect(x: 0, y: 0, width: Toast.spinnerSize, height: Toast.spinnerSize)
        let ai = NVActivityIndicatorView(frame: frame, type: .circleStrokeSpin, color: .label, padding: 0)
        ai.translatesAutoresizingMaskIntoConstraints = false
        ai.color = Toast.iconTint

        NSLayoutConstraint.activate([
            ai.widthAnchor.constraint(equalToConstant: Toast.spinnerSize),
            ai.heightAnchor.constraint(equalToConstant: Toast.spinnerSize),
        ])

        return ai
    }()

    @objc private func tapHandler() {
        self.hide()
    }

    private func setup(imageName: String, withSpinner: Bool) {
        self.translatesAutoresizingMaskIntoConstraints = false

        self.layer.backgroundColor = UIColor.clear.cgColor
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOffset = .zero
        self.layer.shadowOpacity = 0.25
        self.layer.shadowRadius = 20

        self.addSubview(self.contentView)
        self.contentView.addSubview(self.effectView)
        self.contentView.addSubview(self.stackView)

        self.imageView.image = UIImage(systemName: imageName)

        self.stackView.addArrangedSubview(self.imageView)
        self.stackView.addArrangedSubview(self.label)

        if withSpinner {
            self.stackView.addArrangedSubview(self.spinner)
            self.spinner.startAnimating()
        }

        NSLayoutConstraint.activate([
            self.contentView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.contentView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            self.contentView.topAnchor.constraint(equalTo: self.topAnchor),
            self.contentView.bottomAnchor.constraint(equalTo: self.bottomAnchor),

            self.effectView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor),
            self.effectView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor),
            self.effectView.topAnchor.constraint(equalTo: self.contentView.topAnchor),
            self.effectView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor),

            self.stackView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 16),
            self.stackView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -16),
            self.stackView.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 10),
            self.stackView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -10),
        ])

        self.alpha = 0
        self.contentView.backgroundColor = .clear

        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.tapHandler)))
    }
}
