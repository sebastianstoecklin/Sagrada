#include "include/private.h"
#include <dlfcn.h>
#include <stdlib.h>

// Runtime-only WindowServer overrides: never write com.apple.symbolichotkeys.
// These private APIs are resolved dynamically so unsupported macOS versions
// can report failure instead of preventing the application from launching.
typedef bool (*IsEnabled)(int);
typedef CGError (*SetEnabled)(int, bool);
static SetEnabled setEnabled;
static const int screenshotIds[] = {28, 29, 30, 31, 184};
static bool originalEnabled[5];
static bool overridden = false;
static bool registeredCleanup = false;

void sagradaRestoreScreenshotHotkeys(void) {
    if (!overridden) return;
    for (int i = 0; i < 5; i++) {
        setEnabled(screenshotIds[i], originalEnabled[i]);
    }
    overridden = false;
}

bool sagradaSuspendScreenshotHotkeys(void) {
    if (overridden) return true;
    void *library = dlopen("/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight", RTLD_LAZY);
    if (!library) return false;
    IsEnabled isEnabled = (IsEnabled)dlsym(library, "CGSIsSymbolicHotKeyEnabled");
    setEnabled = (SetEnabled)dlsym(library, "CGSSetSymbolicHotKeyEnabled");
    if (!isEnabled || !setEnabled) {
        dlclose(library);
        return false;
    }
    for (int i = 0; i < 5; i++) originalEnabled[i] = isEnabled(screenshotIds[i]);
    if (!registeredCleanup) {
        if (atexit(sagradaRestoreScreenshotHotkeys) != 0) {
            dlclose(library);
            return false;
        }
        registeredCleanup = true;
    }
    overridden = true;
    for (int i = 0; i < 5; i++) {
        if (setEnabled(screenshotIds[i], false) != kCGErrorSuccess) {
            sagradaRestoreScreenshotHotkeys();
            return false;
        }
    }
    // Keep the library loaded while the restoration function pointer is in use.
    return true;
}
