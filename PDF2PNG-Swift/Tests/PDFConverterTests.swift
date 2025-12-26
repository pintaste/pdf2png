import XCTest
@testable import PDF2PNG

final class PDFConverterTests: XCTestCase {

    func testConversionSettingsDefault() {
        let settings = ConversionSettings.default
        XCTAssertEqual(settings.maxDPI, 600)
        XCTAssertEqual(settings.minDPI, 150)
        XCTAssertEqual(settings.maxSizeMB, 5.0)
        XCTAssertFalse(settings.qualityFirst)
    }

    func testConversionSettingsHighQuality() {
        let settings = ConversionSettings.highQuality
        XCTAssertEqual(settings.maxDPI, 1200)
        XCTAssertTrue(settings.qualityFirst)
    }

    func testTaskStatusProgress() {
        let pending = TaskStatus.pending
        XCTAssertEqual(pending.progress, 0)

        let converting = TaskStatus.converting(progress: 0.5)
        XCTAssertEqual(converting.progress, 0.5)

        let completed = TaskStatus.completed(result: PDFConverter.ConversionResult(
            outputURLs: [],
            actualDPI: 600,
            totalSizeBytes: 1000,
            renderTimeMs: 100
        ))
        XCTAssertEqual(completed.progress, 1)
    }

    func testDPIPresets() {
        XCTAssertEqual(ConversionSettings.DPIPreset.standard.maxDPI, 600)
        XCTAssertEqual(ConversionSettings.DPIPreset.high.maxDPI, 1200)
        XCTAssertEqual(ConversionSettings.DPIPreset.ultra.maxDPI, 2400)
    }
}
