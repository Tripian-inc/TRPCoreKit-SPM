//
//  NexusLoadingVC.swift
//  TRPCoreKit
//
//  Placeholder shown while the Nexus entry resolves reservations / fetches the
//  user's timelines, before routing to the timeline, My Plans, or create flow.
//

import UIKit

final class NexusLoadingVC: TRPBaseUIViewController {
    public override func setupViews() {
        super.setupViews()
        view.backgroundColor = .white
        navigationController?.setNavigationBarHidden(true, animated: false)
        // Use the SDK's Lottie loader (full-screen window overlay), not the legacy
        // TRPLoaderView. The destination screen's view model keeps/hides the same
        // shared overlay so it reads as one continuous loader.
        TRPLottieLoadingVC.shared.showOnWindow()
    }
}
