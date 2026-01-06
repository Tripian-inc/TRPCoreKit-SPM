//
//  TRPRangeSlider.swift
//  TRPCoreKit
//
//  Created by Cem Caygoz on 06.01.2025.
//  Copyright © 2025 Tripian Inc. All rights reserved.
//

import UIKit
import TRPFoundationKit

public class TRPRangeSlider: UIControl {

    // MARK: - Properties
    public var minimumValue: Double = 0 {
        didSet { updateLayerFrames() }
    }

    public var maximumValue: Double = 100 {
        didSet { updateLayerFrames() }
    }

    public var lowerValue: Double = 0 {
        didSet {
            lowerValue = max(minimumValue, min(lowerValue, upperValue))
            updateLayerFrames()
        }
    }

    public var upperValue: Double = 100 {
        didSet {
            upperValue = min(maximumValue, max(upperValue, lowerValue))
            updateLayerFrames()
        }
    }

    public var trackTintColor: UIColor = ColorSet.neutral100.uiColor {
        didSet { trackLayer.setNeedsDisplay() }
    }

    public var trackHighlightTintColor: UIColor = ColorSet.primary.uiColor {
        didSet { trackLayer.setNeedsDisplay() }
    }

    public var thumbTintColor: UIColor = .white {
        didSet {
            lowerThumbLayer.setNeedsDisplay()
            upperThumbLayer.setNeedsDisplay()
        }
    }

    private let trackLayer = RangeSliderTrackLayer()
    private let lowerThumbLayer = RangeSliderThumbLayer()
    private let upperThumbLayer = RangeSliderThumbLayer()
    private var previousLocation = CGPoint()

    private let thumbWidth: CGFloat = 24
    private let trackHeight: CGFloat = 4

    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }

    // MARK: - Setup
    private func setupLayers() {
        trackLayer.rangeSlider = self
        trackLayer.contentsScale = UIScreen.main.scale
        layer.addSublayer(trackLayer)

        lowerThumbLayer.rangeSlider = self
        lowerThumbLayer.contentsScale = UIScreen.main.scale
        layer.addSublayer(lowerThumbLayer)

        upperThumbLayer.rangeSlider = self
        upperThumbLayer.contentsScale = UIScreen.main.scale
        layer.addSublayer(upperThumbLayer)
    }

    // MARK: - Layout
    public override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: thumbWidth)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        updateLayerFrames()
    }

    private func updateLayerFrames() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        let trackY = (bounds.height - trackHeight) / 2
        trackLayer.frame = CGRect(x: thumbWidth / 2, y: trackY, width: bounds.width - thumbWidth, height: trackHeight)
        trackLayer.setNeedsDisplay()

        let lowerThumbCenter = positionForValue(lowerValue)
        lowerThumbLayer.frame = CGRect(x: lowerThumbCenter - thumbWidth / 2, y: 0, width: thumbWidth, height: thumbWidth)
        lowerThumbLayer.setNeedsDisplay()

        let upperThumbCenter = positionForValue(upperValue)
        upperThumbLayer.frame = CGRect(x: upperThumbCenter - thumbWidth / 2, y: 0, width: thumbWidth, height: thumbWidth)
        upperThumbLayer.setNeedsDisplay()

        CATransaction.commit()
    }

    private func positionForValue(_ value: Double) -> CGFloat {
        let trackWidth = bounds.width - thumbWidth
        return thumbWidth / 2 + CGFloat((value - minimumValue) / (maximumValue - minimumValue)) * trackWidth
    }

    // MARK: - Touch Handling
    public override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        previousLocation = touch.location(in: self)

        // Determine which thumb to track
        if lowerThumbLayer.frame.contains(previousLocation) {
            lowerThumbLayer.highlighted = true
        } else if upperThumbLayer.frame.contains(previousLocation) {
            upperThumbLayer.highlighted = true
        }

        return lowerThumbLayer.highlighted || upperThumbLayer.highlighted
    }

    public override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let location = touch.location(in: self)

        // Calculate delta
        let deltaLocation = Double(location.x - previousLocation.x)
        let deltaValue = (maximumValue - minimumValue) * deltaLocation / Double(bounds.width - thumbWidth)

        previousLocation = location

        // Update values
        if lowerThumbLayer.highlighted {
            lowerValue += deltaValue
            lowerValue = boundValue(lowerValue, toLowerValue: minimumValue, upperValue: upperValue)
        } else if upperThumbLayer.highlighted {
            upperValue += deltaValue
            upperValue = boundValue(upperValue, toLowerValue: lowerValue, upperValue: maximumValue)
        }

        sendActions(for: .valueChanged)
        return true
    }

    public override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        lowerThumbLayer.highlighted = false
        upperThumbLayer.highlighted = false
    }

    private func boundValue(_ value: Double, toLowerValue lowerValue: Double, upperValue: Double) -> Double {
        return min(max(value, lowerValue), upperValue)
    }
}

// MARK: - Track Layer
private class RangeSliderTrackLayer: CALayer {
    weak var rangeSlider: TRPRangeSlider?

    override func draw(in ctx: CGContext) {
        guard let slider = rangeSlider else { return }

        // Draw track background
        let cornerRadius = bounds.height / 2
        let path = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius)
        ctx.addPath(path.cgPath)
        ctx.setFillColor(slider.trackTintColor.cgColor)
        ctx.fillPath()

        // Draw highlighted range
        let lowerValuePosition = CGFloat((slider.lowerValue - slider.minimumValue) / (slider.maximumValue - slider.minimumValue)) * bounds.width
        let upperValuePosition = CGFloat((slider.upperValue - slider.minimumValue) / (slider.maximumValue - slider.minimumValue)) * bounds.width
        let highlightRect = CGRect(x: lowerValuePosition, y: 0, width: upperValuePosition - lowerValuePosition, height: bounds.height)

        ctx.setFillColor(slider.trackHighlightTintColor.cgColor)
        ctx.fill(highlightRect)
    }
}

// MARK: - Thumb Layer
private class RangeSliderThumbLayer: CALayer {
    var highlighted: Bool = false {
        didSet { setNeedsDisplay() }
    }
    weak var rangeSlider: TRPRangeSlider?

    override func draw(in ctx: CGContext) {
        guard let slider = rangeSlider else { return }

        let thumbFrame = bounds.insetBy(dx: 2, dy: 2)
        let cornerRadius = thumbFrame.height / 2

        // Draw shadow
        ctx.setShadow(offset: CGSize(width: 0, height: 1), blur: 2, color: UIColor.black.withAlphaComponent(0.2).cgColor)

        // Draw thumb circle
        let thumbPath = UIBezierPath(roundedRect: thumbFrame, cornerRadius: cornerRadius)
        ctx.addPath(thumbPath.cgPath)
        ctx.setFillColor(slider.thumbTintColor.cgColor)
        ctx.fillPath()

        // Draw border
        ctx.addPath(thumbPath.cgPath)
        ctx.setStrokeColor(ColorSet.lineWeak.uiColor.cgColor)
        ctx.setLineWidth(0.5)
        ctx.strokePath()
    }
}
