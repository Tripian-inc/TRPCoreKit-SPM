//
//  TRPOpeningHours.swift
//  TRPCoreKit
//
//  Parses a POI `hours` string into per-day 24h ranges and answers whether a chosen
//  time span falls inside them. Mirrors the Android `OpeningHours` helper so both
//  platforms warn on the same input.
//
//  Input looks like "Sun, Sat: 9:00 AM - 1:00 AM | Mon-Fri: 8:30 AM - 1:00 AM";
//  day names may be localized. A range whose end is not after its start crosses
//  midnight, so it stays open until that hour the next day.
//

import Foundation

public struct TRPOpeningHours {

    public static let dayOrder = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    private struct Range {
        let startMinutes: Int
        let endMinutes: Int
        var crossesMidnight: Bool { endMinutes <= startMinutes }
    }

    private static let dayNameMappings: [String: String] = [
        "Mon": "Mon", "Tue": "Tue", "Wed": "Wed", "Thu": "Thu", "Fri": "Fri", "Sat": "Sat", "Sun": "Sun",
        "Monday": "Mon", "Tuesday": "Tue", "Wednesday": "Wed", "Thursday": "Thu", "Friday": "Fri", "Saturday": "Sat", "Sunday": "Sun",
        "Lun": "Mon", "Mar": "Tue", "Mié": "Wed", "Mie": "Wed", "Jue": "Thu", "Vie": "Fri", "Sáb": "Sat", "Sab": "Sat", "Dom": "Sun",
        "Lunes": "Mon", "Martes": "Tue", "Miércoles": "Wed", "Miercoles": "Wed", "Jueves": "Thu", "Viernes": "Fri", "Sábado": "Sat", "Sabado": "Sat", "Domingo": "Sun",
        "Mo": "Mon", "Di": "Tue", "Mi": "Wed", "Do": "Thu", "Fr": "Fri", "Sa": "Sat", "So": "Sun",
        "Montag": "Mon", "Dienstag": "Tue", "Mittwoch": "Wed", "Donnerstag": "Thu", "Freitag": "Fri", "Samstag": "Sat", "Sonntag": "Sun",
        "Mer": "Wed", "Jeu": "Thu", "Ven": "Fri", "Sam": "Sat", "Dim": "Sun",
        "Lundi": "Mon", "Mardi": "Tue", "Mercredi": "Wed", "Jeudi": "Thu", "Vendredi": "Fri", "Samedi": "Sat", "Dimanche": "Sun",
        "Pzt": "Mon", "Sal": "Tue", "Çar": "Wed", "Car": "Wed", "Per": "Thu", "Cum": "Fri", "Cmt": "Sat", "Paz": "Sun",
        "Pazartesi": "Mon", "Salı": "Tue", "Sali": "Tue", "Çarşamba": "Wed", "Carsamba": "Wed", "Perşembe": "Thu", "Persembe": "Thu", "Cuma": "Fri", "Cumartesi": "Sat", "Pazar": "Sun",
        "Gio": "Thu",
        "Lunedì": "Mon", "Lunedi": "Mon", "Martedì": "Tue", "Martedi": "Tue", "Mercoledì": "Wed", "Mercoledi": "Wed", "Giovedì": "Thu", "Giovedi": "Thu", "Venerdì": "Fri", "Venerdi": "Fri", "Sabato": "Sat", "Domenica": "Sun",
        "Seg": "Mon", "Ter": "Tue", "Qua": "Wed", "Qui": "Thu", "Sex": "Fri",
        "Segunda": "Mon", "Terça": "Tue", "Terca": "Tue", "Quarta": "Wed", "Quinta": "Thu", "Sexta": "Fri"
    ]

    private static let allDayNames: [String] = dayNameMappings.keys.sorted { $0.count > $1.count }

    /// Localized "closed" markers a day entry may carry instead of a time range.
    private static let closedMarkers = [
        "closed", "cerrado", "cerrada", "fermé", "ferme", "geschlossen",
        "chiuso", "chiusa", "fechado", "fechada", "kapalı", "kapali"
    ]

    /// English day abbreviation ("Mon"..."Sun") for `date`, or nil when it can't be derived.
    public static func dayKey(of date: Date?) -> String? {
        guard let date = date else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        switch calendar.component(.weekday, from: date) {
        case 2: return "Mon"
        case 3: return "Tue"
        case 4: return "Wed"
        case 5: return "Thu"
        case 6: return "Fri"
        case 7: return "Sat"
        case 1: return "Sun"
        default: return nil
        }
    }

    /// English day abbreviation to `"HH:mm - HH:mm"`; days with no entry are absent.
    public static func dayTexts(_ hoursString: String?) -> [String: String] {
        guard let hoursString = hoursString, !hoursString.trimmingCharacters(in: .whitespaces).isEmpty else {
            return [:]
        }

        var dayHours: [String: String] = [:]
        for group in hoursString.split(separator: "|").map({ $0.trimmingCharacters(in: .whitespaces) }) {
            guard group.contains(":") else { continue }

            let daysPart = findDaysPart(group)
            guard !daysPart.isEmpty else { continue }

            var timePart = String(group.dropFirst(daysPart.count)).trimmingCharacters(in: .whitespaces)
            if timePart.hasPrefix(":") { timePart.removeFirst() }
            let converted = convertTo24HourFormat(timePart.trimmingCharacters(in: .whitespaces))

            for day in parseDays(daysPart) {
                dayHours[day] = converted
            }
        }
        return dayHours
    }

    /// `"HH:mm - HH:mm"` for `date`'s weekday, or nil when that day has no entry.
    public static func dayText(_ hoursString: String?, date: Date?) -> String? {
        guard let key = dayKey(of: date) else { return nil }
        return dayTexts(hoursString)[key]
    }

    /// Whether `startTime...endTime` (both `"HH:mm"`) on `date` fits inside that day's
    /// opening hours. A day entry without a time range counts as closed only when it
    /// carries a known localized "closed" marker; any other free text (e.g. "Open 24
    /// hours" in any language) is undecided. Returns nil when it cannot be decided — no
    /// hours data, an unparsable entry, or an incomplete selection — so callers can stay
    /// silent.
    public static func coversSelection(
        _ hoursString: String?,
        date: Date?,
        startTime: String?,
        endTime: String?
    ) -> Bool? {
        guard let selectionStart = minutes(of: startTime),
              let selectionEnd = minutes(of: endTime),
              let key = dayKey(of: date) else { return nil }

        let texts = dayTexts(hoursString)
        if texts.isEmpty { return nil }

        guard let dayEntry = texts[key] else { return false }
        guard let range = parseRange(dayEntry) else { return isClosedText(dayEntry) ? false : nil }

        if range.crossesMidnight {
            return selectionStart >= range.startMinutes || selectionEnd <= range.endMinutes
        }
        return selectionStart >= range.startMinutes && selectionEnd <= range.endMinutes
    }

    private static func isClosedText(_ text: String) -> Bool {
        let normalized = text.lowercased()
        return closedMarkers.contains { normalized.contains($0) }
    }

    private static func parseRange(_ text: String) -> Range? {
        let parts = text.split(separator: "-").map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count == 2,
              let start = minutes(of: parts[0]),
              let end = minutes(of: parts[1]) else { return nil }
        return Range(startMinutes: start, endMinutes: end)
    }

    private static func minutes(of time: String?) -> Int? {
        let parts = time?.split(separator: ":").map { $0.trimmingCharacters(in: .whitespaces) }
        guard let parts = parts, parts.count == 2,
              let hour = Int(parts[0]), let minute = Int(parts[1]) else { return nil }
        return hour * 60 + minute
    }

    private static func findDaysPart(_ group: String) -> String {
        let characters = Array(group)
        var lastDayEnd = 0

        for index in characters.indices {
            let remainder = String(characters[index...])
            for dayName in allDayNames where remainder.lowercased().hasPrefix(dayName.lowercased()) {
                let endPos = index + dayName.count
                if endPos > lastDayEnd { lastDayEnd = endPos }
            }
        }

        return String(characters[0..<lastDayEnd])
    }

    private static func normalizeDayName(_ localizedDay: String) -> String? {
        let trimmed = localizedDay.trimmingCharacters(in: .whitespaces)
        for (key, value) in dayNameMappings where key.caseInsensitiveCompare(trimmed) == .orderedSame {
            return value
        }
        return nil
    }

    private static func parseDays(_ daysString: String) -> [String] {
        var result: [String] = []

        for part in daysString.split(separator: ",").map({ $0.trimmingCharacters(in: .whitespaces) }) {
            if part.contains("-") {
                let rangeParts = part.split(separator: "-").map { $0.trimmingCharacters(in: .whitespaces) }
                guard rangeParts.count == 2,
                      let startDay = normalizeDayName(rangeParts[0]),
                      let endDay = normalizeDayName(rangeParts[1]),
                      let startIdx = dayOrder.firstIndex(of: startDay),
                      let endIdx = dayOrder.firstIndex(of: endDay) else { continue }

                if startIdx <= endIdx {
                    result.append(contentsOf: dayOrder[startIdx...endIdx])
                } else {
                    result.append(contentsOf: dayOrder[startIdx...])
                    result.append(contentsOf: dayOrder[...endIdx])
                }
            } else if let day = normalizeDayName(part), dayOrder.contains(day) {
                result.append(day)
            }
        }

        return result
    }

    private static func convertTo24HourFormat(_ timeString: String) -> String {
        let parts = timeString.split(separator: "-").map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count == 2 else { return timeString }
        return "\(convert12To24(parts[0])) - \(convert12To24(parts[1]))"
    }

    private static func convert12To24(_ time: String) -> String {
        let trimmed = time.trimmingCharacters(in: .whitespaces).uppercased()
        let isPM = trimmed.contains("PM")
        let isAM = trimmed.contains("AM")

        let timeOnly = trimmed
            .replacingOccurrences(of: "AM", with: "")
            .replacingOccurrences(of: "PM", with: "")
            .trimmingCharacters(in: .whitespaces)

        let timeParts = timeOnly.split(separator: ":").map { $0.trimmingCharacters(in: .whitespaces) }
        guard timeParts.count == 2,
              var hour = Int(timeParts[0]),
              let minute = Int(timeParts[1]) else { return time }

        if isPM && hour != 12 {
            hour += 12
        } else if isAM && hour == 12 {
            hour = 0
        }

        return String(format: "%02d:%02d", hour, minute)
    }
}
