//
//  PlaceDetailCellModels.swift
//  TRPCoreKit
//
//  Created by Rozeri Dilar on 3/17/20.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import TRPUIKit
import TRPFoundationKit
import TRPDataLayer

enum FeedElement {
    case image(ImageCellModel)
    case title(TitleCellModel)
    case description(DescriptionCellModel)
    case openingHours(OpeningHoursCellModel)
    case customTagsCell(CustomTagsCellModel)
    case map(MapCellModel)
    case button(ButtonCellModel)
}

protocol TitleProtocol {
    var title: String { get set }
}

struct ImageCellModel :TitleProtocol{
    public var title: String
    var isFavorite: Bool?
    var images: [PagingImage]
}

public struct PagingImage {
    public var imageUrl: String?
    public var picOwner: TRPImageOwner?
}

struct TitleCellModel :TitleProtocol{
    public var title: String
    var sdkModeType: SdkModeType
    var globalRating: Bool
    var starCount: Int
    var reviewCount: Int
    var explainText: NSAttributedString?
}

struct DescriptionCellModel: TitleProtocol{
    var title: String
}

struct OpeningHoursCellModel: TitleProtocol{
    public var title: String
}

struct ButtonCellModel: TitleProtocol{
    public var title: String
}

public enum PlaceDetailCustomCellStatus{
    case cuisines, address, feautures, narrativeTags, money, web, phone, reportaproblem, mustTry, makeAReservation
}

struct CustomTagsCellModel: TitleProtocol{
    public var title: String
    var price: Int?
    public var status: PlaceDetailCustomCellStatus
}

struct MapCellModel{
    public var location: TRPLocation
}
