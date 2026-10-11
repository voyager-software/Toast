//
//  ToastPreviews.swift
//  Toast
//
//  Created by Gabor Sajo on 2026-02-18.
//

#if DEBUG && os(iOS)
import SwiftUI
import UIKit

#Preview("Toast with Icon") {
    ToastPreviewWrapper(
        text: "Operation completed successfully",
        imageName: "checkmark.circle.fill",
        color: .systemGreen,
        withSpinner: false
    )
}

#Preview("Toast with Spinner") {
    ToastPreviewWrapper(
        text: "Loading your data...",
        imageName: "arrow.triangle.2.circlepath",
        color: .systemBlue,
        withSpinner: true
    )
}

#Preview("Long Text Toast") {
    ToastPreviewWrapper(
        text: "This is a longer message that demonstrates how the toast handles multiple lines of text content",
        imageName: "info.circle",
        color: nil,
        withSpinner: false
    )
}

private struct ToastPreviewWrapper: UIViewRepresentable {
    let text: String
    let imageName: String
    let color: UIColor?
    let withSpinner: Bool

    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        container.backgroundColor = .systemBackground

        let toast = Toast(
            text: text,
            imageName: imageName,
            color: color,
            withSpinner: withSpinner
        )

        container.addSubview(toast)

        toast.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            toast.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            toast.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            toast.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: 20),
            toast.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -20),
        ])

        // Animate the toast in
        UIView.animate(withDuration: 0.3) {
            toast.setVisible(true)
        }

        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
#endif
