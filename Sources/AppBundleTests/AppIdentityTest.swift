@testable import AppBundle
import Common
import XCTest

final class AppIdentityTest: XCTestCase {
    func testForkHasItsOwnBundleIdentity() {
        assertEquals(stableAeroSpaceAppId, "com.sebastianstoecklin.sagrada")
        #if DEBUG
            assertEquals(aeroSpaceAppId, stableAeroSpaceAppId + ".debug")
            assertEquals(aeroSpaceAppName, "SagradaDebug")
        #else
            assertEquals(aeroSpaceAppId, stableAeroSpaceAppId)
            assertEquals(aeroSpaceAppName, "Sagrada")
        #endif
    }

    func testClientSocketUsesForkIdentity() {
        assertEquals(socketPath, "/tmp/\(aeroSpaceAppId)-\(unixUserName).sock")
        assertFalse(socketPath.contains("bobko.aerospace"))
    }

    func testConfigUsesSagradaNameAndPreservesUpstreamEnvironment() {
        assertEquals(configDotfileName, ".sagrada.toml")
        assertEquals(AEROSPACE_WINDOW_ID, "AEROSPACE_WINDOW_ID")
        assertEquals(AEROSPACE_WORKSPACE, "AEROSPACE_WORKSPACE")
        assertEquals(AEROSPACE_FOCUSED_WORKSPACE, "AEROSPACE_FOCUSED_WORKSPACE")
        assertEquals(AEROSPACE_PREV_WORKSPACE, "AEROSPACE_PREV_WORKSPACE")
    }
}
