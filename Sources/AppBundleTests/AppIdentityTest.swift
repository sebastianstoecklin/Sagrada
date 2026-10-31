@testable import AppBundle
import Common
import XCTest

final class AppIdentityTest: XCTestCase {
    func testForkHasItsOwnBundleIdentity() {
        assertEquals(stableAeroSpaceAppId, "com.sebastianstoecklin.sagradaspace")
        #if DEBUG
            assertEquals(aeroSpaceAppId, stableAeroSpaceAppId + ".debug")
            assertEquals(aeroSpaceAppName, "SagradaSpaceDebug")
        #else
            assertEquals(aeroSpaceAppId, stableAeroSpaceAppId)
            assertEquals(aeroSpaceAppName, "SagradaSpace")
        #endif
    }

    func testClientSocketUsesForkIdentity() {
        assertEquals(socketPath, "/tmp/\(aeroSpaceAppId)-\(unixUserName).sock")
        assertFalse(socketPath.contains("bobko.aerospace"))
    }

    func testUpstreamConfigurationContractIsPreserved() {
        assertEquals(configDotfileName, ".aerospace.toml")
        assertEquals(AEROSPACE_WINDOW_ID, "AEROSPACE_WINDOW_ID")
        assertEquals(AEROSPACE_WORKSPACE, "AEROSPACE_WORKSPACE")
        assertEquals(AEROSPACE_FOCUSED_WORKSPACE, "AEROSPACE_FOCUSED_WORKSPACE")
        assertEquals(AEROSPACE_PREV_WORKSPACE, "AEROSPACE_PREV_WORKSPACE")
    }
}
