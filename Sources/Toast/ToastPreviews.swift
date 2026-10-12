//
//  ToastPreviews.swift
//  Toast
//
//  Created by Gabor Sajo on 2026-02-18.
//

#if DEBUG && os(iOS)
// Not used directly, but the canvas fails with "no such module 'SwiftUI'" without it.
import SwiftUI
import UIKit

#Preview("Top") {
    fillingCanvas(ToastPreviewView(
        text: "Operation completed successfully",
        imageName: "checkmark.circle.fill",
        color: .systemGreen.withAlphaComponent(0.4),
        withSpinner: false,
        position: .top
    ))
}

#Preview("Bottom with Spinner") {
    fillingCanvas(ToastPreviewView(
        text: "Loading your data...",
        imageName: "arrow.triangle.2.circlepath",
        color: nil,
        withSpinner: true,
        position: .bottom
    ))
}

#Preview("Long Text") {
    fillingCanvas(ToastPreviewView(
        text: "This is a longer message that demonstrates how the toast handles multiple lines of text content",
        imageName: "info.circle",
        color: nil,
        withSpinner: false,
        position: .top
    ))
}

/// Hosts the view as a view controller's root so it fills the canvas. A bare `UIView`
/// preview is sized by Auto Layout, so it would shrink to the toast's width while one shows.
@MainActor
private func fillingCanvas(_ view: UIView) -> UIViewController {
    let controller = UIViewController()
    controller.view = view
    return controller
}

/// Repeatedly shows and hides a toast through the real presenter, over a colorful
/// background so the glass is visible.
private final class ToastPreviewView: UIView {
    // MARK: Lifecycle

    init(text: String, imageName: String, color: UIColor?, withSpinner: Bool, position: Toast.Position) {
        self.text = text
        self.imageName = imageName
        self.color = color
        self.withSpinner = withSpinner
        self.position = position
        super.init(frame: .zero)
        self.setupBackground()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    override func layoutSubviews() {
        super.layoutSubviews()
        self.gradient.frame = self.bounds
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        self.loop?.cancel()
        self.loop = nil

        // Start only once on screen, otherwise the first animation is lost.
        guard self.window != nil else { return }
        self.loop = Task { [weak self] in
            while !Task.isCancelled {
                self?.presentToast()
                try? await Task.sleep(for: .seconds(ToastPreviewView.cycle))
            }
        }
    }

    // MARK: Private

    /// Time on screen, then the hide animation and a short pause before the next toast.
    private static let visibleDuration: TimeInterval = 2
    private static let cycle: TimeInterval = visibleDuration + 1.2

    private let text: String
    private let imageName: String
    private let color: UIColor?
    private let withSpinner: Bool
    private let position: Toast.Position
    private let gradient = CAGradientLayer()
    private var loop: Task<Void, Never>?

    private func presentToast() {
        Toast(
            text: self.text,
            imageName: self.imageName,
            color: self.color,
            withSpinner: self.withSpinner
        )
        .show(in: self, position: self.position)
        .hide(after: Self.visibleDuration)
    }

    private func setupBackground() {
        self.clipsToBounds = true

        self.gradient.colors = [UIColor.systemIndigo, .systemPink, .systemOrange].map(\.cgColor)
        self.gradient.startPoint = CGPoint(x: 0, y: 0)
        self.gradient.endPoint = CGPoint(x: 1, y: 1)
        self.layer.addSublayer(self.gradient)

        // Stripes give the glass something to refract.
        let stripes = UIStackView()
        stripes.translatesAutoresizingMaskIntoConstraints = false
        stripes.axis = .vertical
        stripes.distribution = .fillEqually
        stripes.spacing = 24
        for _ in 0 ..< 24 {
            let stripe = UIView()
            stripe.backgroundColor = UIColor.white.withAlphaComponent(0.35)
            stripes.addArrangedSubview(stripe)
        }
        self.addSubview(stripes)

        NSLayoutConstraint.activate([
            stripes.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            stripes.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            stripes.topAnchor.constraint(equalTo: self.topAnchor),
            stripes.bottomAnchor.constraint(equalTo: self.bottomAnchor),
        ])
    }
}
#endif
