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
        didSet {
            if #available(iOS 26, tvOS 26, *) {
                if self.isVisible {
                    self.effectView.effect = self.makeGlassEffect()
                }
            }
            else {
                self.effectView.backgroundColor = self.color
            }
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
    private(set) var isVisible = false

    /// Shows or hides the toast; call inside an animation block to animate.
    ///
    /// On iOS/tvOS 26+ the glass materializes by animating its effect, because fading
    /// the alpha of a glass view (or any of its superviews) renders it incorrectly.
    /// The content is faded separately with `setContentVisible(_:)`.
    func setVisible(_ visible: Bool) {
        self.isVisible = visible
        self.isUserInteractionEnabled = visible

        if #available(iOS 26, tvOS 26, *) {
            self.effectView.effect = visible ? self.makeGlassEffect() : nil
        }
        else {
            self.alpha = visible ? 1 : 0
        }
    }

    /// Fades the icon and text on iOS/tvOS 26+, timed apart from the glass so they never
    /// show without a backing. Earlier systems fade the whole toast in `setVisible(_:)`.
    func setContentVisible(_ visible: Bool) {
        if #available(iOS 26, tvOS 26, *) {
            self.stackView.alpha = visible ? 1 : 0
        }
    }

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

    /// Clipping wrapper for the pre-iOS 26 blur; unused with native glass.
    private lazy var contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 12
        view.layer.cornerCurve = .continuous
        view.layer.borderColor = UIColor.systemGray.withAlphaComponent(0.25).cgColor
        view.layer.borderWidth = 1.0
        view.layer.masksToBounds = true
        return view
    }()

    private let effectView: UIVisualEffectView = {
        let ev: UIVisualEffectView
        if #available(iOS 26, tvOS 26, *) {
            // Starts without an effect; `setVisible(_:)` materializes the glass.
            ev = UIVisualEffectView(effect: nil)
            ev.cornerConfiguration = .capsule(maximumRadius: 23)
        }
        else {
            #if os(iOS)
            ev = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
            #else
            ev = UIVisualEffectView(effect: UIBlurEffect(style: .prominent))
            #endif
        }
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

    @available(iOS 26, tvOS 26, *)
    private func makeGlassEffect() -> UIGlassEffect {
        let glass = UIGlassEffect(style: .regular)
        glass.tintColor = self.color
        glass.isInteractive = true
        return glass
    }

    @objc private func tapHandler() {
        self.hide()
    }

    private func setup(imageName: String, withSpinner: Bool) {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.layer.backgroundColor = UIColor.clear.cgColor

        self.imageView.image = UIImage(systemName: imageName)

        self.stackView.addArrangedSubview(self.imageView)
        self.stackView.addArrangedSubview(self.label)

        if withSpinner {
            self.stackView.addArrangedSubview(self.spinner)
            self.spinner.startAnimating()
        }

        let container: UIView
        if #available(iOS 26, tvOS 26, *) {
            // Native glass: corners come from `cornerConfiguration` and the glass renders its own shadow.
            self.addSubview(self.effectView)
            self.effectView.contentView.addSubview(self.stackView)
            container = self.effectView
        }
        else {
            self.layer.shadowColor = UIColor.black.cgColor
            self.layer.shadowOffset = .zero
            self.layer.shadowOpacity = 0.25
            self.layer.shadowRadius = 20

            self.addSubview(self.contentView)
            self.contentView.addSubview(self.effectView)
            self.contentView.addSubview(self.stackView)
            self.contentView.backgroundColor = .clear
            // `didSet` doesn't fire for the assignment in `init`.
            self.effectView.backgroundColor = self.color
            container = self.contentView

            NSLayoutConstraint.activate([
                self.effectView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor),
                self.effectView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor),
                self.effectView.topAnchor.constraint(equalTo: self.contentView.topAnchor),
                self.effectView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor),
            ])
        }

        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            container.topAnchor.constraint(equalTo: self.topAnchor),
            container.bottomAnchor.constraint(equalTo: self.bottomAnchor),

            self.stackView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            self.stackView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            self.stackView.topAnchor.constraint(equalTo: container.topAnchor, constant: 10),
            self.stackView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -10),
        ])

        self.setVisible(false)
        self.setContentVisible(false)

        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.tapHandler)))

        self.registerForTraitChanges(
            [UITraitHorizontalSizeClass.self, UITraitVerticalSizeClass.self]
        ) { (toast: Toast, _: UITraitCollection) in
            toast.updateConstraintsForCurrentSizeClass()
            toast.updateTabBarPositionForOrientation()
        }
    }
}
