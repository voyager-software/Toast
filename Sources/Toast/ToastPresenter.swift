//
//  ToastPresenter.swift
//  Toast
//
//  Created by Gábor Sajó on 2026-02-16.
//

import UIKit

public extension Toast {
    enum Position {
        case top
        case bottom
    }

    enum Duration: TimeInterval {
        case
            minimal = 1,
            short = 3,
            long = 7,
            indefinite = 1000
    }

    private static let animationTime: TimeInterval = 0.4
    private static let offScreenPosition: CGFloat = 160
    private static let topMargin: CGFloat = 16
    private static let bottomMargin: CGFloat = 16
    private static let maxWidth: CGFloat = 500

    private var positionConstraint: NSLayoutConstraint? {
        self.superview?.constraints.first {
            $0.identifier == "Toast.positionConstraint" && $0.firstItem === self
        }
    }

    func show(in view: UIView, position: Position = .top) -> Self {
        self.position = position
        self.removeExistingToasts(from: view)
        self.addTo(view, position: position)

        UIView.animate(
            withDuration: Self.animationTime,
            delay: 0,
            options: .curveEaseOut,
            animations: self.animationsForShow
        )
        return self
    }

    func hide(after delay: TimeInterval = .zero) {
        UIView.animate(
            withDuration: Self.animationTime,
            delay: delay,
            options: [],
            animations: self.animationsForHide,
            completion: { _ in
                self.removeFromSuperview()
            }
        )
    }

    func hide(after delay: Toast.Duration) {
        self.hide(after: delay.rawValue)
    }

    private func addTo(_ parentView: UIView, position: Position) {
        parentView.addSubview(self)

        self.compactConstraints = [
            self.leadingAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            self.trailingAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.trailingAnchor, constant: -20),
        ]

        self.regularConstraints = [
            {
                let width = self.widthAnchor.constraint(equalTo: parentView.widthAnchor, multiplier: 0.6)
                width.priority = .defaultHigh
                return width
            }(),
            {
                let maxWidth = self.widthAnchor.constraint(lessThanOrEqualToConstant: Self.maxWidth)
                maxWidth.priority = .required
                return maxWidth
            }(),
        ]

        let positionConstraint: NSLayoutConstraint
        switch position {
        case .top:
            positionConstraint = self.topAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.topAnchor, constant: -Self.offScreenPosition)
            self.isAnchoredToTabBar = false
        case .bottom:
            // Check if there's a tab bar to position above
            if let tabBar = TabBarFinder.findTabBar(in: parentView), tabBar.bounds.height > 0 {
                // When showing above tab bar, anchor to the tab bar's top directly
                positionConstraint = self.bottomAnchor.constraint(equalTo: tabBar.topAnchor, constant: Self.offScreenPosition)
                self.isAnchoredToTabBar = true
            }
            else {
                positionConstraint = self.bottomAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.bottomAnchor, constant: Self.offScreenPosition)
                self.isAnchoredToTabBar = false
            }
        }
        positionConstraint.identifier = "Toast.positionConstraint"

        NSLayoutConstraint.activate([
            self.centerXAnchor.constraint(equalTo: parentView.centerXAnchor),
            positionConstraint,
        ])

        self.updateConstraintsForCurrentSizeClass()

        parentView.layoutIfNeeded()
    }

    private func removeExistingToasts(from parentView: UIView) {
        let toasts = parentView.subviews.compactMap { $0 as? Self }
        toasts.forEach { $0.hide() }
    }

    func updateTabBarPositionForOrientation() {
        // When anchored to tab bar's top, the constraint doesn't need updating
        // The tab bar's frame change will automatically reposition the toast
        // We just need to ensure the layout updates
        if self.isAnchoredToTabBar, self.isVisible {
            self.superview?.layoutIfNeeded()
        }
    }

    private func animationsForShow() {
        self.setVisible(true)
        guard let position = self.position else { return }

        switch position {
        case .top:
            self.positionConstraint?.constant = Self.topMargin
        case .bottom:
            self.positionConstraint?.constant = -Self.bottomMargin
        }

        self.superview?.layoutIfNeeded()
    }

    private func animationsForHide() {
        self.setVisible(false)
        guard let position = self.position else { return }

        switch position {
        case .top:
            self.positionConstraint?.constant = -Self.offScreenPosition
        case .bottom:
            // Move off screen below
            self.positionConstraint?.constant = Self.offScreenPosition
        }

        self.superview?.layoutIfNeeded()
    }
}

public extension Toast {
    @discardableResult
    static func present(
        _ message: String,
        imageName: String = "info.circle",
        color: UIColor? = nil,
        withSpinner: Bool = false,
        duration: Toast.Duration = .short,
        position: Toast.Position = .top,
        in view: UIView? = nil
    ) -> Toast? {
        guard let view = view ?? UIApplication.shared.appWindow else { return nil }

        let toast = Toast(
            text: message,
            imageName: imageName,
            color: color,
            withSpinner: withSpinner
        ).show(in: view, position: position)

        if duration != .indefinite {
            toast.hide(after: duration.rawValue)
        }

        return toast
    }
}
