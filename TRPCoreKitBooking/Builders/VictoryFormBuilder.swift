import Foundation
import TRPBookingKit

/// Builds the ticket buyer form and turns its answers into a buyer.
struct VictoryFormBuilder {

    let text: TRPBookingText
    var locale: Locale = .current

    var sections: [BookingFormSection] {
        let countries = Locale.isoRegionCodes
            .map { BookingFormOption(value: $0, title: locale.localizedString(forRegionCode: $0) ?? $0) }
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        let currentRegion = locale.regionCode.map { [$0] } ?? []
        return [
            BookingFormSection(title: text(.contact), fields: [
                BookingFormField(id: "name", title: text(.fullName), kind: .text, isRequired: true),
                BookingFormField(id: "email", title: text(.email), kind: .email, isRequired: true),
                BookingFormField(id: "phone", title: text(.phone), kind: .phone, isRequired: false)
            ]),
            BookingFormSection(title: text(.street), fields: [
                BookingFormField(id: "street", title: text(.street), kind: .text, isRequired: true),
                BookingFormField(id: "extended", title: text(.extendedAddress), kind: .text, isRequired: false),
                BookingFormField(id: "city", title: text(.city), kind: .text, isRequired: true),
                BookingFormField(id: "region", title: text(.region), kind: .text, isRequired: false),
                BookingFormField(id: "postalCode", title: text(.postalCode), kind: .text, isRequired: true),
                BookingFormField(id: "country", title: text(.country), kind: .choice(countries, allowsMultiple: false),
                                 isRequired: true, initialValues: currentRegion)
            ])
        ]
    }

    func buyer(from values: BookingFormValues) -> VictoryBuyer {
        VictoryBuyer(name: values.value("name") ?? "",
                     email: values.value("email") ?? "",
                     phoneNumber: values.value("phone"),
                     billingAddress: VictoryBuyer.Address(streetAddress: values.value("street") ?? "",
                                                          extendedAddress: values.value("extended"),
                                                          locality: values.value("city") ?? "",
                                                          region: values.value("region"),
                                                          postalCode: values.value("postalCode") ?? "",
                                                          countryCode: values.value("country") ?? ""))
    }
}
