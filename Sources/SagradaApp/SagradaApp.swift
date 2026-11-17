import AppBundle
import SwiftUI

// This file is shared between SPM and xcode project

final class SagradaAppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Status-item host windows are replaced during workspace/permission changes.
        // Closing one must never terminate this background window manager.
        false
    }
}

@main
struct SagradaApp: App {
    @NSApplicationDelegateAdaptor(SagradaAppDelegate.self) private var appDelegate
    @StateObject var viewModel = TrayMenuModel.shared
    @StateObject var messageModel = MessageModel.shared
    @Environment(\.openWindow) var openWindow: OpenWindowAction

    init() {
        initAppBundle()
    }

    var body: some Scene {
        menuBar(viewModel: viewModel)
        getMessageWindow(messageModel: messageModel)
            .onChange(of: messageModel.message) { message in
                if message != nil {
                    openWindow(id: messageWindowId)
                }
            }
    }
}
