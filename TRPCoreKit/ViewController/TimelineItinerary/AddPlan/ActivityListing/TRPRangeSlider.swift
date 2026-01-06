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

    /// Format closure for value labels (default: integer format)
    public var valueLabelFormatter: ((Double) -> String) = { value in
        return "\(Int(value))"
    }

    public var trackTintColor: UIColor = ColorSet.lineWeak.uiColor {
        didSet { trackLayer.setNeedsDisplay() }
    }

    public var trackHighlightTintColor: UIColor = ColorSet.primary.uiColor {
        didSet { trackLayer.setNeedsDisplay() }
    }

    private let trackLayer = RangeSliderTrackLayer()
    private let lowerThumbLayer = RangeSliderThumbLayer()
    private let upperThumbLayer = RangeSliderThumbLayer()
    private var previousLocation = CGPoint()

    // Value labels above thumbs
    private let lowerValueLabel: UILabel = {
        let label = UILabel()
        label.font = FontSet.montserratMedium.font(12)
        label.textColor = ColorSet.primaryText.uiColor
        label.textAlignment = .center
        return label
    }()

    private let upperValueLabel: UILabel = {
        let label = UILabel()
        label.font = FontSet.montserratMedium.font(12)
        label.textColor = ColorSet.primaryText.uiColor
        label.textAlignment = .center
        return label
    }()

    // Constants
    private let thumbSize: CGFloat = 25
    private let trackHeight: CGFloat = 8
    private let thumbBorderWidth: CGFloat = 7
    private let valueLabelHeight: CGFloat = 18
    private let valueLabelSpacing: CGFloat = 4 // Space between label and thumb

    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
        setupLabels()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
        setupLabels()
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

    private func setupLabels() {
        addSubview(lowerValueLabel)
        addSubview(upperValueLabel)
    }

    // MARK: - Layout
    public override var intrinsicContentSize: CGSize {
        // Height = value label + spacing + thumb size
        let totalHeight = valueLabelHeight + valueLabelSpacing + thumbSize
        return CGSize(width: UIView.noIntrinsicMetric, height: totalHeight)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        updateLayerFrames()
    }

    private func updateLayerFrames() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        // Calculate vertical positions
        let thumbY = valueLabelHeight + valueLabelSpacing
        let trackY = thumbY + (thumbSize - trackHeight) / 2

        // Track frame (centered between thumbs area)
        trackLayer.frame = CGRect(
            x: thumbSize / 2,
            y: trackY,
            width: bounds.width - thumbSize,
            height: trackHeight
        )
        trackLayer.setNeedsDisplay()

        // Lower thumb
        let lowerThumbCenter = positionForValue(lowerValue)
        lowerThumbLayer.frame = CGRect(
            x: lowerThumbCenter - thumbSize / 2,
            y: thumbY,
            width: thumbSize,
            height: thumbSize
        )
        lowerThumbLayer.setNeedsDisplay()

        // Upper thumb
        let upperThumbCenter = positionForValue(upperValue)
        upperThumbLayer.frame = CGRect(
            x: upperThumbCenter - thumbSize / 2,
            y: thumbY,
            width: thumbSize,
            height: thumbSize
        )
        upperThumbLayer.setNeedsDisplay()

        // Update value labels
        updateValueLabels()

        CATransaction.commit()
    }

    private func updateValueLabels() {
        // Lower value label
        lowerValueLabel.text = valueLabelFormatter(lowerValue)
        lowerValueLabel.sizeToFit()
        let lowerThumbCenter = positionForValue(lowerValue)
        lowerValueLabel.center = CGPoint(
            x: lowerThumbCenter,
            y: valueLabelHeight / 2
        )

        // Upper value label
        upperValueLabel.text = valueLabelFormatter(upperValue)
        upperValueLabel.sizeToFit()
        let upperThumbCenter = positionForValue(upperValue)
        upperValueLabel.center = CGPoint(
            x: upperThumbCenter,
            y: valueLabelHeight / 2
        )
    }

    private func positionForValue(_ value: Double) -> CGFloat {
        let trackWidth = bounds.width - thumbSize
        return thumbSize / 2 + CGFloat((value - minimumValue) / (maximumValue - minimumValue)) * trackWidth
    }

    // MARK: - Touch Handling
    public override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        previousLocation = touch.location(in: self)

        // Expand touch area for better UX
        let lowerThumbFrame = lowerThumbLayer.frame.insetBy(dx: -10, dy: -10)
        let upperThumbFrame = upperThumbLayer.frame.insetBy(dx: -10, dy: -10)

        // Determine which thumb to track
        if lowerThumbFrame.contains(previousLocation) {
            lowerThumbLayer.highlighted = true
        } else if upperThumbFrame.contains(previousLocation) {
            upperThumbLayer.highlighted = true
        }

        return lowerThumbLayer.highlighted || upperThumbLayer.highlighted
    }

    public override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let location = touch.location(in: self)

        // Calculate delta
        let deltaLocation = Double(location.x - previousLocation.x)
        let deltaValue = (maximumValue - minimumValue) * deltaLocation / Double(bounds.width - thumbSize)

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

        // Draw track background (unselected - lineWeak)
        let cornerRadius = bounds.height / 2
        let path = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius)
        ctx.addPath(path.cgPath)
        ctx.setFillColor(slider.trackTintColor.cgColor)
        ctx.fillPath()

        // Draw highlighted range (selected - primary)
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
        // 25x25 thumb with 7px primary border and white center
        let thumbRect = bounds
        let cornerRadius = thumbRect.height / 2

        // Draw shadow
        ctx.setShadow(offset: CGSize(width: 0, height: 1), blur: 3, color: UIColor.black.withAlphaComponent(0.15).cgColor)

        // Draw outer circle (primary color border)
        let outerPath = UIBezierPath(roundedRect: thumbRect, cornerRadius: cornerRadius)
        ctx.addPath(outerPath.cgPath)
        ctx.setFillColor(ColorSet.primary.uiColor.cgColor)
        ctx.fillPath()

        // Reset shadow for inner circle
        ctx.setShadow(offset: .zero, blur: 0, color: nil)

        // Draw inner circle (white center)
        // Border width is 7px, so inner circle inset is 7 from each side
        let borderWidth: CGFloat = 7
        let innerRect = thumbRect.insetBy(dx: borderWidth, dy: borderWidth)
        let innerCornerRadius = innerRect.height / 2
        let innerPath = UIBezierPath(roundedRect: innerRect, cornerRadius: innerCornerRadius)
        ctx.addPath(innerPath.cgPath)
        ctx.setFillColor(UIColor.white.cgColor)
        ctx.fillPath()
    }
}
