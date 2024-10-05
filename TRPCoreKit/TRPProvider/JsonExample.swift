//
//  JsonExample.swift
//  TRPProvider
//
//  Created by Evren Yaşar on 2020-12-27.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
let paymentJsonResult = """
{
  "_metadata" : {
    "method" : "confirmShoppingCartAction",
    "status" : "OK",
    "totalCount" : 0,
    "offset" : 0,
    "exchange" : {
      "currency" : "usd",
      "rate" : 0.82565480469999997
    },
    "date" : "2020-12-27T12:10:30Z",
    "limit" : 10,
    "availableLanguages" : [

    ],
    "descriptor" : "GetYourGuide AG"
  },
  "data" : {
    "status" : "completed",
    "billing" : {
      "address_line_1" : "",
      "state" : "",
      "country_code" : "TR",
      "salutation_code" : "m",
      "phone_number" : "5339271371",
      "address_line_2" : "",
      "company_name" : "",
      "first_name" : "evren",
      "city" : "",
      "postal_code" : "",
      "last_name" : "yasar",
      "email" : "Necatievren@gmail.com",
      "invoice" : false,
      "is_company" : false
    },
    "shopping_cart_hash" : "58YAF7I7OJSKFUKFHK0IUNQLJ1FB3L3L",
    "traveler" : {
      "salutation_code" : "m",
      "email" : "Necatievren@gmail.com",
      "last_name" : "yasar",
      "phone_number" : "5339271371",
      "first_name" : "evren"
    },
    "bookings" : [
      {
        "bookable" : {
          "datetime_type" : "datetime",
          "tour_id" : 385628,
          "datetime" : "2020-12-27T19:00:00",
          "price" : 113.53,
          "categories" : [
            {
              "name" : "Adult",
              "category_id" : 2124445,
              "number_of_participants" : 1
            }
          ],
          "cancellation_policy_text" : "Please note that your activity's cancellation and rescheduling deadline has passed.",
          "valid_until" : "2020-12-27T22:00:00",
          "datetime_utc" : "2020-12-28T00:00:00Z",
          "booking_parameters" : [
            {
              "name" : "language",
              "value_1" : "language_live",
              "value_2" : "en"
            },
            {
              "name" : "hotel",
              "value_1" : "Denrme"
            },
            {
              "name" : "supplier_requested_question",
              "value_1" : "A"
            }
          ],
          "option_id" : 698176
        },
        "booking_id" : 162179052,
        "shopping_cart_hash" : "58YAF7I7OJSKFUKFHK0IUNQLJ1FB3L3L",
        "ticket" : {
          "booking_reference" : "GYG482QNAK6W",
          "voucher_information" : "• Please contact the local partner within 24 hours of departure to confirm your pickup location and time\\n• Please make sure you have provided a telephone number that functions in Montreal so that the local partner can contact you",
          "emergency_phone_number" : "+1 514-549-1605",
          "ticket_hash" : "PXYB4N00PRSRD0ANFHY09HA30Q7DO9WD",
          "emergency_email" : "local-partner-7ydylnmcvgfammfv@testing1.test-reply.getyourguide.com",
          "supplier_booking_codes" : [
            {
              "code" : "293G4OFWTWD5OVFF3YBU026GG8WA8EM3-2KOUI",
              "ticket_hash" : "PXYB4N00PRSRD0ANFHY09HA30Q7DO9WD-1",
              "label" : "Ticket #1 (ADULT)",
              "type" : "qr_code"
            }
          ],
          "ticket_url" : "https://www.testing1.gygtest.com/ticket.php?PXYB4N00PRSRD0ANFHY09HA30Q7DO9WD"
        },
        "booking_status" : "confirmed",
        "booking_hash" : "PXYB4N00PRSRD0ANFHY09HA30Q7DO9WD",
        "shopping_cart_id" : 319423984
      },
      {
        "bookable" : {
          "datetime_type" : "datetime",
          "tour_id" : 389570,
          "datetime" : "2020-12-27T09:00:00",
          "price" : 234.12,
          "categories" : [
            {
              "name" : "Adult",
              "category_id" : 2154716,
              "number_of_participants" : 1
            }
          ],
          "cancellation_policy_text" : "Please note that your activity's cancellation and rescheduling deadline has passed.",
          "valid_until" : "2020-12-27T18:00:00",
          "datetime_utc" : "2020-12-27T14:00:00Z",
          "booking_parameters" : [
            {
              "name" : "language",
              "value_1" : "language_live",
              "value_2" : "en"
            },
            {
              "name" : "hotel",
              "value_1" : "ssss"
            },
            {
              "name" : "supplier_requested_question",
              "value_1" : "Sss"
            }
          ],
          "option_id" : 706125
        },
        "booking_id" : 162179054,
        "shopping_cart_hash" : "58YAF7I7OJSKFUKFHK0IUNQLJ1FB3L3L",
        "ticket" : {
          "booking_reference" : "GYG6H99KVY2Y",
          "voucher_information" : "• Pickup and drop-off is available from select hotels in downtown Montreal. after booking, you can send your hotel name and address to the local operator. They will confirm whether pickup from your hotel is possible and if it is not, you will be assigned the nearest pickup location\\n• Please contact the local operator within 24-hours of departure to confirm your pickup location and time\\n• Please make sure you have provided a telephone number that functions in Montreal so that the local operator can contact you",
          "emergency_phone_number" : "+1 514-549-1605",
          "ticket_hash" : "JCNCF302BRUELLZA999TZAOLZB49L0T5",
          "emergency_email" : "local-partner-uq47ltd66gel2v5u@testing1.test-reply.getyourguide.com",
          "supplier_booking_codes" : [
            {
              "code" : "IU6GPINTY9JHQAXW1HP1LG85MBKLPW3Q-1JHC9",
              "ticket_hash" : "JCNCF302BRUELLZA999TZAOLZB49L0T5-1",
              "label" : "Ticket #1 (ADULT)",
              "type" : "qr_code"
            }
          ],
          "ticket_url" : "https://www.testing1.gygtest.com/ticket.php?JCNCF302BRUELLZA999TZAOLZB49L0T5"
        },
        "booking_status" : "confirmed",
        "booking_hash" : "JCNCF302BRUELLZA999TZAOLZB49L0T5",
        "shopping_cart_id" : 319423984
      },
      {
        "bookable" : {
          "datetime_type" : "datetime",
          "tour_id" : 385288,
          "datetime" : "2020-12-29T09:30:00",
          "price" : 199.66,
          "categories" : [
            {
              "name" : "Adult",
              "category_id" : 2122958,
              "number_of_participants" : 1
            }
          ],
          "cancellation_policy_text" : "Cancel before 9:30 AM on December 28th for a full refund.",
          "valid_until" : "2020-12-29T17:00:00",
          "datetime_utc" : "2020-12-29T14:30:00Z",
          "booking_parameters" : [
            {
              "name" : "language",
              "value_1" : "language_live",
              "value_2" : "en"
            },
            {
              "name" : "hotel",
              "value_1" : "Aaaa"
            },
            {
              "name" : "supplier_requested_question",
              "value_1" : "Aaaa"
            }
          ],
          "option_id" : 697534
        },
        "booking_id" : 162179055,
        "shopping_cart_hash" : "58YAF7I7OJSKFUKFHK0IUNQLJ1FB3L3L",
        "ticket" : {
          "booking_reference" : "GYGN6G4HKMFZ",
          "voucher_information" : "• Please contact the local partner within 24 hours of departure to confirm your pickup location and time\\n• Please make sure you have provided a telephone number that functions in Montreal so that the local partner can contact you",
          "emergency_phone_number" : "+1 514-549-1605",
          "ticket_hash" : "6PCM6YU6S6GX718UTM65MAMKYE6GC5WU",
          "emergency_email" : "local-partner-ul2vtvt7l5skjvt4@testing1.test-reply.getyourguide.com",
          "supplier_booking_codes" : [
            {
              "code" : "YR0MMVHUMCZC5Q4K4SNA152M7L6NJVBY-SI82V",
              "ticket_hash" : "6PCM6YU6S6GX718UTM65MAMKYE6GC5WU-1",
              "label" : "Ticket #1 (ADULT)",
              "type" : "qr_code"
            }
          ],
          "ticket_url" : "https://www.testing1.gygtest.com/ticket.php?6PCM6YU6S6GX718UTM65MAMKYE6GC5WU"
        },
        "booking_status" : "confirmed",
        "booking_hash" : "6PCM6YU6S6GX718UTM65MAMKYE6GC5WU",
        "shopping_cart_id" : 319423984
      }
    ],
    "shopping_cart_id" : 319423984,
    "payment_info" : {
      "payment_method" : "cc",
      "precoupon_price" : 547.30999999999995,
      "total_price" : 547.30999999999995,
      "payment_currency" : "USD",
      "invoice_reference" : "GCI-0319423984"
    }
  }
}

"""



let cardJsonResult = """
{
    "_metadata": {
        "descriptor": "GetYourGuide AG",
        "method": "getShoppingCartByHashAction",
        "date": "2021-01-04T10:20:40Z",
        "status": "OK",
        "query": "cnt_language=en&currency=usd",
        "availableLanguages": [],
        "exchange": {
            "rate": 0.8169974578299947,
            "currency": "usd"
        },
        "totalCount": 1,
        "limit": 10,
        "offset": 0
    },
    "data": {
        "shopping_cart": {
            "shopping_cart_id": 319446617,
            "shopping_cart_hash": "DL2S9GJM8MZ4QVUVYQQ5XXRNPVTKMHR6",
            "billing": {
                "salutation_code": "m",
                "first_name": "Mehmet",
                "last_name": "Keskinoglu",
                "email": "Mehmet@tripian.com",
                "is_company": false,
                "company_name": "",
                "invoice": false,
                "address_line_1": "",
                "address_line_2": "",
                "city": "",
                "postal_code": "",
                "state": "",
                "country_code": "TR",
                "phone_number": "5339271371"
            },
            "status": "open",
            "bookings": [
                {
                    "booking_id": 162302565,
                    "booking_hash": "1IMIAIGHHIPDPT29GQZQ4GSHUQMLGZ1F",
                    "booking_status": "temp",
                    "shopping_cart_id": 319446617,
                    "shopping_cart_hash": "DL2S9GJM8MZ4QVUVYQQ5XXRNPVTKMHR6",
                    "bookable": {
                        "tour_id": 28602,
                        "option_id": 33184,
                        "datetime": "2021-01-05T10:00:00",
                        "datetime_utc": "2021-01-05T15:00:00Z",
                        "datetime_type": "datetime",
                        "price": 41.65,
                        "categories": [
                            {
                                "category_id": 1327802,
                                "name": "Adult",
                                "number_of_participants": 1
                            }
                        ],
                        "booking_parameters": [
                            {
                                "name": "language",
                                "value_1": "language_live",
                                "value_2": "en"
                            },
                            {
                                "name": "hotel",
                                "value_1": "Ssddsds"
                            },
                            {
                                "name": "supplier_requested_question",
                                "value_1": "Asdasdad"
                            }
                        ],
                        "valid_until": "2021-01-05T12:00:00",
                        "cancellation_policy_text": "Cancel before 10:00 AM on January 4th for a full refund."
                    }
                }
            ],
            "payment_info": {
                "payment_currency": "USD",
                "total_price": 41.65,
                "precoupon_price": 41.65
            }
        }
    }
}

"""




let errorResponseJson = """
{
    "descriptor": "GetYourGuide AG",
    "apiVersion": "1",
    "method": "getTourByQueryAction",
    "date": "2021-01-05T10:42:39Z",
    "status": "ERROR",
    "query": "cnt_language=en&currency=usd&limit=90&preformatted=full&q=montreal",
    "errors": [
        {
            "errorCode": 25,
            "errorMessage": "Unauthorized. The access token is invalid."
        }
    ],
    "helpURL": "https://api.testing1.gygtest.com/doc"
}
"""
