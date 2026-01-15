import 'dart:io';
import 'package:automerge/automerge.dart';

Future<void> initPlatformState() async {
  if (Platform.isIOS || Platform.isMacOS) {
    // On iOS and macOS, the library is statically linked.
    await RustLib.init(
      externalLibrary: ExternalLibrary.process(iKnowHowToUseIt: true),
    );
  } else {
    await RustLib.init();
  }
}
