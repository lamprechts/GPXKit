import Foundation
import XCTest
import Difference

@testable import GPXKit
#if canImport(FoundationXML)
import FoundationXML
#endif

public func XCTAssertEqual<T: Equatable>(_ expected: @autoclosure () throws -> T, _ received: @autoclosure () throws -> T, file: StaticString = #filePath, line: UInt = #line) {
    do {
        let expected = try expected()
        let received = try received()
        XCTAssertTrue(expected == received, "Found difference for \n" + diff(expected, received).joined(separator: ", "), file: file, line: line)
    }
    catch {
        XCTFail("Caught error while testing: \(error)", file: file, line: line)
    }
}

fileprivate var iso8601Formatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = .withInternetDateTime
    return formatter
}()

func expectedDate(for dateString: String) -> Date {
    return iso8601Formatter.date(from: dateString)!
}

func expectedString(for date: Date) -> String {
    return iso8601Formatter.string(from: date)
}

func givenTrackPoints(_ count: Int) -> [TrackPoint] {
    let date = Date()

    return (1..<count).map { sec in
        TrackPoint(coordinate: .random, date: date + TimeInterval(sec))
    }
}

extension String {
    var strippedLines: String {
        split(separator: "\n")
            .map {
                $0.trimmingCharacters(in: .whitespaces)
            }.joined(separator: "\n")
    }
}

extension Coordinate {
    static var random: Coordinate {
        Coordinate(latitude: Double.random(in: -90..<90),
                   longitude: Double.random(in: -180..<180),
                   elevation: Double.random(in: 1..<100))
    }

    func offset(north: Double = 0, east: Double = 0, elevation: Double) -> Self {
        var offset = self.offset(north: north, east: east)
        offset.elevation = self.elevation + elevation
        return offset
    }
}

extension TrackPoint {
    func expectedXMLNode(withDate: Bool = false) -> GPXKit.XMLNode {
        XMLNode(name: GPXTags.trackPoint.rawValue,
                atttributes: [
                    GPXAttributes.latitude.rawValue: "\(coordinate.latitude)",
                    GPXAttributes.longitude.rawValue: "\(coordinate.longitude)"
                ],
                children: [
                    XMLNode(name: GPXTags.elevation.rawValue,
                            content: String(format:"%.2f", coordinate.elevation)),
                    withDate ? date.flatMap {
                        XMLNode(name: GPXTags.time.rawValue,
                        content: expectedString(for: $0) )
                    } : nil
                ].compactMap {$0 }
        )
    }
}

extension XCTest {
    func assertDatesEqual(
        _ expected: Date?,
        _ actual: Date?,
        granularity: Calendar.Component = .nanosecond,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let lhs = expected, let rhs = actual else {
            XCTAssertEqual(expected, actual,
                           "Dates are not equal - expected: \(String(describing: expected)), actual: \(String(describing: actual))",
                           file: file,
                           line: line )
            return
        }
        XCTAssertTrue(
            Calendar.autoupdatingCurrent
                .isDate(lhs, equalTo: rhs, toGranularity: granularity),
            "Expected dates to be equal - expected: \(lhs), actual: \(rhs)", file: file, line: line
        )
    }

    func assertTracksAreEqual(
        _ expected: GPXTrack,
        _ actual: GPXTrack,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        assertDatesEqual(expected.date, actual.date, file: file, line: line)
        XCTAssertEqual(expected.title, actual.title, file: file, line: line)
        XCTAssertEqual(expected.trackPoints, actual.trackPoints, file: file, line: line)
    }

    /*
     public struct XMLNode: Equatable, Hashable {
     var name: String
     var atttributes: [String: String] = [:]
     var content: String = ""
     public var children: [XMLNode] = []
     }
     */
    func assertNodesAreEqual(
        _ expected: GPXKit.XMLNode,
        _ actual: GPXKit.XMLNode,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(expected.content, actual.content, file: file, line: line)
        XCTAssertEqual(expected.content, actual.content, file: file, line: line)
        XCTAssertEqual(expected.atttributes, actual.atttributes, file: file, line: line)
        XCTAssertEqual(expected.children, actual.children, file: file, line: line)
    }

    func assertGeoCoordinateEqual(
        _ expected: GeoCoordinate,
        _ actual: GeoCoordinate,
        accuracy: Double = 0.0001,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(expected.latitude,
                       actual.latitude,
                       accuracy: accuracy,
                       "Expected latitude: \(expected.latitude), got \(actual.latitude)",
                       file: file, line: line)
        XCTAssertEqual(expected.longitude,
                       actual.longitude,
                       accuracy: accuracy,
                       "Expected longitude: \(expected.longitude), got \(actual.longitude)",
                       file: file,
                       line: line)
    }

    func assertGeoCoordinatesEqual<T: BidirectionalCollection>(
        _ expected: T,
        _ acutal: T,
        accuracy: Double = 0.00001,
        file: StaticString = #filePath,
        line: UInt = #line
    ) where T.Element: GeoCoordinate {
        XCTAssertEqual(expected.count, acutal.count)
        zip(expected, acutal).forEach { lhs, rhs in
            assertGeoCoordinateEqual(lhs, rhs, accuracy: accuracy, file: file, line: line)
        }
    }

}
