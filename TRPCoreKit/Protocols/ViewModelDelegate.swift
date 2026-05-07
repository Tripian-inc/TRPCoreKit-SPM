//
//  ViewModelDelegate.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 17.10.2018.
//  Copyright © 2018 Tripian Inc. All rights reserved.
//

import Foundation
public protocol ViewModelDelegate: AnyObject {
    func viewModel(dataLoaded:Bool)
    func viewModel(error: Error)
    func viewModel(showPreloader:Bool)
    func viewModel(showMessage: String, type: EvrAlertLevel)
    /// Show or hide the shared Lottie loading overlay (window-attached, app-wide).
    /// Pass `text` for a single static label; pass `nil` to use the default rotating texts.
    /// `completion` fires after the show animation begins, or after the hide fade-out
    /// finishes — useful for sequencing follow-up UI (e.g. presenting an alert after
    /// the loader is gone). Mirrors the existing `viewModel(showPreloader:)` /
    /// `TRPLoaderView` pattern so every base VC gets it for free.
    func viewModel(showLottieLoader: Bool, text: String?, completion: (() -> Void)?)
    /// Show or hide a Lottie loading overlay presented as a bottom sheet on the
    /// current screen (rather than full-screen window-attached). Use for shorter
    /// operations where a partial overlay is preferable — e.g. fetching a tour's
    /// schedule from inside the time selection screen.
    func viewModel(showLottieBottomSheet: Bool, text: String?, completion: (() -> Void)?)
    /// Show or hide a Lottie loader embedded directly into the current screen's view
    /// (added as a child VC). Use when the screen itself is already a bottom sheet —
    /// stacking another sheet would feel wrong, so the loader appears inline within
    /// the host's bounds and dismisses without disturbing presentation hierarchy.
    func viewModel(showLottieInView: Bool, text: String?, completion: (() -> Void)?)
}

extension ViewModelDelegate {
    public func viewModel(dataLoaded: Bool) {}
    public func viewModel(error: Error) {}
    public func viewModel(showPreloader: Bool) {}
    public func viewModel(showMessage: String, type: EvrAlertLevel) {}
    public func viewModel(showLottieLoader: Bool, text: String?, completion: (() -> Void)?) {}
    public func viewModel(showLottieBottomSheet: Bool, text: String?, completion: (() -> Void)?) {}
    public func viewModel(showLottieInView: Bool, text: String?, completion: (() -> Void)?) {}

    /// Convenience: no-completion variant. Most call sites don't need to sequence
    /// follow-up work after show/hide and can use this shorter form.
    public func viewModel(showLottieLoader: Bool, text: String?) {
        viewModel(showLottieLoader: showLottieLoader, text: text, completion: nil)
    }
    /// Convenience: no-completion variant for the bottom sheet loader.
    public func viewModel(showLottieBottomSheet: Bool, text: String?) {
        viewModel(showLottieBottomSheet: showLottieBottomSheet, text: text, completion: nil)
    }
    /// Convenience: no-completion variant for the embedded loader.
    public func viewModel(showLottieInView: Bool, text: String?) {
        viewModel(showLottieInView: showLottieInView, text: text, completion: nil)
    }
}
