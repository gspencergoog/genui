// In order to *not* need this ignore, consider extracting the "web" version
// of your plugin as a separate package, instead of inlining it in the same
// package as the core of your plugin.
// ignore: avoid_web_libraries_in_flutter
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

/// A web implementation of the Automerge plugin.
class AutomergeWeb {
  /// Registers this class as the default instance of [AutomergePlatform].
  static void registerWith(Registrar registrar) {
    // Flutter Rust Bridge 2.x initializes itself, but we can configure the
    // loader here if needed. Ideally, we just ensure the WASM is loaded.
    // However, RustLib.init() is usually called by the app. We can provide a
    // custom config to RustLib via a hook or just trust the app to call it?
    // Actually, for Plugins, we might want to pre-configure it.

    // Changing the default config in RustLib is static. We can't easily change
    // the static defaultExternalLibraryLoaderConfig in RustLib without
    // subclassing or modifying the generated code (which we shouldn't). BUT, we
    // can call RustLib.init() with our config here? RustLib.init() is async.
    // registerWith is sync. We can't await it here.

    // Instead, we rely on the `ExternalLibraryLoaderConfig` being correct or
    // passed by the user. But since we are packaging it, we should try to make
    // it "just work".

    // We can verify that the WASM is reachable or set a global variable that
    // helps find it? For now, let's just leave it empty as the user calls
    // RustLib.init()]. But we need this class for the pubspec configuration.
  }
}
