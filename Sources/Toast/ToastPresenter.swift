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

    private static let showTime: TimeInterval = 0.3
    private static let hideTime: TimeInterval = 0.4
    /// The content fades in once the glass has mostly materialized, and fades out
    /// before the glass dissolves.
    private static let contentShowDelay: TimeInterval = 0.1
    private static let contentHideTime: TimeInterval = 0.15
    /// How far the toast travels and how much it grows while appearing.
    /// Both are skipped when Reduce Motion is on, leaving only the fade/materialize.
    private static let travel: CGFloat = 24
    private static let hiddenScale: CGFloat = 0.9
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
            springDuration: Self.showTime,
            bounce: 0,
            animations: self.animationsForShow
        )
        UIView.animate(
            withDuration: Self.showTime - Self.contentShowDelay,
            delay: Self.contentShowDelay,
            options: .curveEaseOut,
            animations: { self.setContentVisible(true) }
        )
        return self
    }

    func hide(after delay: TimeInterval = .zero) {
        UIView.animate(
            withDuration: Self.contentHideTime,
            delay: delay,
            options: .curveEaseIn,
            animations: { self.setContentVisible(false) }
        )
        UIView.animate(
            withDuration: Self.hideTime,
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
            positionConstraint = self.topAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.topAnchor, constant: Self.hiddenOffset(for: position))
            self.isAnchoredToTabBar = false
        case .bottom:
            // Check if there's a tab bar to position above
            if let tabBar = TabBarFinder.findTabBar(in: parentView), tabBar.bounds.height > 0 {
                // When showing above tab bar, anchor to the tab bar's top directly
                positionConstraint = self.bottomAnchor.constraint(equalTo: tabBar.topAnchor, constant: Self.hiddenOffset(for: position))
                self.isAnchoredToTabBar = true
            }
            else {
                positionConstraint = self.bottomAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.bottomAnchor, constant: Self.hiddenOffset(for: position))
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
        self.transform = Self.hiddenTransform
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
        self.transform = .identity
        guard let position = self.position else { return }

        self.positionConstraint?.constant = Self.shownOffset(for: position)
        self.superview?.layoutIfNeeded()
    }

    private func animationsForHide() {
        self.setVisible(false)
        self.transform = Self.hiddenTransform
        guard let position = self.position else { return }

        self.positionConstraint?.constant = Self.hiddenOffset(for: position)
        self.superview?.layoutIfNeeded()
    }

    private static var hiddenTransform: CGAffineTransform {
        UIAccessibility.isReduceMotionEnabled ? .identity : CGAffineTransform(scaleX: self.hiddenScale, y: self.hiddenScale)
    }

    private static func shownOffset(for position: Position) -> CGFloat {
        switch position {
        case .top: self.topMargin
        case .bottom: -self.bottomMargin
        }
    }

    /// Slightly short of the resting place, toward the edge the toast belongs to.
    private static func hiddenOffset(for position: Position) -> CGFloat {
        let travel = UIAccessibility.isReduceMotionEnabled ? 0 : self.travel
        switch position {
        case .top: return self.shownOffset(for: position) - travel
        case .bottom: return self.shownOffset(for: position) + travel
        }
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
