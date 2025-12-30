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

## Implementation

All localization is handled through `TimelineLocalizationKeys.swift` with automatic fallback to English.

```swift
TimelineLocalizationKeys.localized(TimelineLocalizationKeys.removeActivityTitle)
// Returns the localized value for "timeline.removeActivity.title"
// If the key is not found, returns "Remove Activity" (default English value)
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

- `TimelineLocalizationKeys.swift` - Localization key definitions and default values
- `TRPTimelineItineraryVC.swift` - Uses remove activity alert keys
- `TRPTimelineBookedActivityCell.swift` - Uses booked activity cell keys

## Changelog

### December 30, 2024
- Added Remove Recommendations Alert keys:
  - `timeline.removeRecommendations.title`
  - `timeline.removeRecommendations.message`
- Added Remove Activity Alert keys:
  - `timeline.removeActivity.title`
  - `timeline.removeActivity.message`
  - `timeline.removeActivity.remove`
  - `timeline.removeActivity.cancel`
