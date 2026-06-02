//
//  CoreMLAppTests.swift
//  CoreMLAppTests
//

import XCTest
@testable import CoreMLApp

final class CoreMLAppTests: XCTestCase {

    func testParseClassNames_ExtractsCorrectOrder() throws {
        let manager = ModelManager.shared
        let input = "{0: 'TelekomRouter', 1: 'FritzBoxRouter', 2: 'FritzBoxRepeater'}"

        let result = manager.parseClassNamesForTesting(from: input)

        XCTAssertEqual(
            result,
            ["TelekomRouter", "FritzBoxRouter", "FritzBoxRepeater"],
            "Klassen müssen in der Reihenfolge ihrer Indizes zurückgegeben werden."
        )
    }

    /// Prüft, ob ein leerer Eingabestring zu einer leeren Liste führt
    func testParseClassNames_HandlesEmptyInput() throws {
        let manager = ModelManager.shared

        let result = manager.parseClassNamesForTesting(from: "")

        XCTAssertEqual(result, [], "Leerer Input muss eine leere Liste liefern.")
    }

    /// Prüft, ob auch unsortierte Indizes korrekt sortiert zurückkommen.
    func testParseClassNames_SortsByIndex() throws {
        let manager = ModelManager.shared
        let input = "{2: 'Drittens', 0: 'Erstens', 1: 'Zweitens'}"

        let result = manager.parseClassNamesForTesting(from: input)

        XCTAssertEqual(result, ["Erstens", "Zweitens", "Drittens"])
    }

    /// Prüft, dass ein Frame, der zu kurz nach dem letzten ankommt,
    /// die Throttling-Bedingung nicht erfüllt (also verworfen werden muss).
    func testThrottling_BlocksTooFrequentInferences() throws {
        let interval: TimeInterval = 0.5
        let lastTime = Date()
        let nowTooEarly = lastTime.addingTimeInterval(0.2)

        let elapsed = nowTooEarly.timeIntervalSince(lastTime)

        XCTAssertLessThan(
            elapsed,
            interval,
            "Frame nach 200 ms muss als zu frueh erkannt werden."
        )
    }

    /// Pruüft, dass ein Frame nach Ablauf des Intervalls die Bedingung
    /// erfüllt und damit zur Inferenz freigegeben wird.
    func testThrottling_AllowsAfterInterval() throws {
        let interval: TimeInterval = 0.5
        let lastTime = Date()
        let nowOk = lastTime.addingTimeInterval(0.6)

        let elapsed = nowOk.timeIntervalSince(lastTime)

        XCTAssertGreaterThanOrEqual(
            elapsed,
            interval,
            "Frame nach 600 ms muss zur Inferenz freigegeben werden."
        )
    }
}

