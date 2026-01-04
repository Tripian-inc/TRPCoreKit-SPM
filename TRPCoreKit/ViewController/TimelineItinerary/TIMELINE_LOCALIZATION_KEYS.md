# Timeline Localization Keys

This document contains all localization keys used in the Timeline Itinerary feature.

## Localization Keys and Default English Values

### Navigation
| Key | Default English Value |
|-----|----------------------|
| `timeline.navigation.title` | "Plan Your Itinerary" |

### Booked Activity Cell
| Key | Default English Value |
|-----|----------------------|
| `timeline.bookedActivity.reservation` | "Reservation" |
| `timeline.bookedActivity.confirmed` | "Confirmed" |
| `timeline.bookedActivity.freeCancellation` | "Free cancellation" |
| `timeline.bookedActivity.adults` | "Adults" |
| `timeline.bookedActivity.child` | "Child" |
| `timeline.bookedActivity.children` | "Children" |

### Remove Activity Alert
| Key | Default English Value |
|-----|----------------------|
| `timeline.removeActivity.title` | "Remove Activity" |
| `timeline.removeActivity.message` | "Are you sure you want to remove this activity from your itinerary?" |
| `timeline.removeActivity.remove` | "Remove" |
| `timeline.removeActivity.cancel` | "Cancel" |

### Remove Recommendations Alert
| Key | Default English Value |
|-----|----------------------|
| `timeline.removeRecommendations.title` | "Remove Recommendations" |
| `timeline.removeRecommendations.message` | "Are you sure you want to remove these recommendations from your itinerary?" |

### Segment/Cell Labels
| Key | Default English Value |
|-----|----------------------|
| `timeline.label.recommendations` | "Recommendations" |
| `timeline.label.activityBadge` | "Activity" |
| `timeline.label.pointOfInterest` | "Point of interest" |
| `timeline.label.unknown` | "Unknown" |
| `timeline.label.unknownLocation` | "Unknown Location" |
| `timeline.label.from` | "From" |

### Duration & Distance Formats
| Key | Default English Value |
|-----|----------------------|
| `timeline.format.hours` | "%dh" |
| `timeline.format.minutes` | "%dm" |
| `timeline.format.durationCombined` | "%dh %dm" |
| `timeline.format.distance` | "%d min (%@ km)" |

### Errors
| Key | Default English Value |
|-----|----------------------|
| `timeline.error.title` | "Error" |
| `timeline.error.somethingWentWrong` | "Something went wrong. Please try again." |
| `timeline.error.generationFailed` | "Failed to generate your itinerary. Please try again." |
| `timeline.error.timeout` | "Request timed out. Please try again." |

## Implementation

All localization is handled through `TimelineLocalizationKeys.swift` with automatic fallback to English.

```swift
TimelineLocalizationKeys.localized(TimelineLocalizationKeys.removeActivityTitle)
// Returns the localized value for "timeline.removeActivity.title"
// If the key is not found, returns "Remove Activity" (default English value)
```

### Format Helper Methods

The localization system includes helper methods for formatting duration and distance:

```swift
// Format duration in minutes to localized string (e.g., "2h 30m" or "45m")
TimelineLocalizationKeys.formatDuration(minutes: 150)
// Returns: "2h 30m"

// Format distance with walking time (e.g., "5 min (0.4 km)")
TimelineLocalizationKeys.formatDistance(minutes: 5, kilometers: "0.4")
// Returns: "5 min (0.4 km)"
```

### Fallback Behavior

If a localization key is not found in the language files, the system automatically returns the default English text:

- ✅ Key exists → Returns translated value
- ✅ Key missing → Returns default English value
- ✅ No blank screens or raw key names displayed

## Adding Translations

To add translations for these keys:

1. Add each key-value pair to your remote language files in `TRPLanguagesController`
2. Provide translations for each language you support (English, Spanish, etc.)
3. The app will automatically use the correct translation based on the user's language setting

## Files

- `TimelineLocalizationKeys.swift` - Localization key definitions, default values, and format helpers
- `TRPTimelineItineraryVC.swift` - Uses remove activity alert keys
- `TRPTimelineItineraryViewModel.swift` - Uses unknown city fallback
- `TRPTimelineBookedActivityCell.swift` - Uses booked activity cell keys and duration formatting
- `TRPTimelineRecommendationsCell.swift` - Uses activity badge, point of interest, from label, duration and distance formatting
- `TRPTimelineManualPoiCell.swift` - Uses point of interest fallback
- `TRPTimelineActivityStepCell.swift` - Uses activity badge
- `TimelineCellData.swift` - Uses recommendations fallback
- `TimelinePoiDetailViewController.swift` - Uses unknown location fallback
- `AddPlanTimeSelectionVC.swift` - Uses error title
- `ActivityCardCell.swift` - Uses duration formatting
- `TimelineGenerateController.swift` - Uses error messages (somethingWentWrong, generationFailed, timeout)

## Changelog

### January 5, 2026
- Added Timeline Generation Error keys:
  - `timeline.error.somethingWentWrong` - Generic error message
  - `timeline.error.generationFailed` - Itinerary generation failed
  - `timeline.error.timeout` - Request timeout error
- Updated `TimelineGenerateController.swift` to use localized error messages

### January 4, 2026
- Added Segment/Cell Labels:
  - `timeline.label.recommendations` - Recommendations section title
  - `timeline.label.activityBadge` - Activity type badge
  - `timeline.label.pointOfInterest` - Default category fallback
  - `timeline.label.unknown` - Unknown city fallback
  - `timeline.label.unknownLocation` - Unknown location fallback
  - `timeline.label.from` - Price prefix label
- Added Duration & Distance Formats:
  - `timeline.format.hours` - Hours format ("%dh")
  - `timeline.format.minutes` - Minutes format ("%dm")
  - `timeline.format.durationCombined` - Combined duration format ("%dh %dm")
  - `timeline.format.distance` - Distance with walking time format
- Added Error keys:
  - `timeline.error.title` - Error alert title
- Added format helper methods:
  - `TimelineLocalizationKeys.formatDuration(minutes:)` - Format minutes to localized duration string
  - `TimelineLocalizationKeys.formatDistance(minutes:kilometers:)` - Format distance with walking time

### December 30, 2024
- Added Remove Recommendations Alert keys:
  - `timeline.removeRecommendations.title`
  - `timeline.removeRecommendations.message`
- Added Remove Activity Alert keys:
  - `timeline.removeActivity.title`
  - `timeline.removeActivity.message`
  - `timeline.removeActivity.remove`
  - `timeline.removeActivity.cancel`
