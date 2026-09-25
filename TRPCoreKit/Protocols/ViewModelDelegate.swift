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

    /// Show a Lottie loading indicator on the current screen. The `presentation`
    /// parameter chooses between three placements (full-screen window overlay, modal
    /// bottom sheet, or embedded child VC). The `textMode` controls the label content
    /// next to the animation — `.none` (animation only), `.single(text)` (static label),
    /// `.rotating([texts])` (cycle through messages), or `.defaultRotating` (the timeline
    /// rotating set). `completion` fires after the show animation begins; sequence any
    /// follow-up UI inside it.
    func viewModel(showLottie presentation: LottieLoaderPresentation,
                   textMode: LottieLoadingTextMode,
                   completion: (() -> Void)?)

    /// Hide the active Lottie loading indicator for the given `presentation`. `completion`
    /// fires after the hide fade-out finishes — useful for sequencing follow-up UI (e.g.
    /// presenting an alert once the loader is gone).
    func viewModel(hideLottie presentation: LottieLoaderPresentation,
                   completion: (() -> Void)?)
}

extension ViewModelDelegate {
    public func viewModel(dataLoaded: Bool) {}
    public func viewModel(error: Error) {}
    public func viewModel(showPreloader: Bool) {}
    public func viewModel(showMessage: String, type: EvrAlertLevel) {}
    public func viewModel(showLottie presentation: LottieLoaderPresentation,
                          textMode: LottieLoadingTextMode,
                          completion: (() -> Void)?) {}
    public func viewModel(hideLottie presentation: LottieLoaderPresentation,
                          completion: (() -> Void)?) {}

    /// Convenience: no-completion variant. Most call sites don't need to sequence
    /// follow-up work and can use this shorter form.
    public func viewModel(showLottie presentation: LottieLoaderPresentation,
                          textMode: LottieLoadingTextMode = .none) {
        viewModel(showLottie: presentation, textMode: textMode, completion: nil)
    }
    /// Convenience: no-completion variant for hide.
    public func viewModel(hideLottie presentation: LottieLoaderPresentation) {
        viewModel(hideLottie: presentation, completion: nil)
    }
}
