import 'dart:js_interop';
import 'package:automerge/automerge.dart';

@JS('wasm_ready')
external JSPromise get wasmReady;

Future<void> initPlatformState() async {
  await wasmReady.toDart;
  await RustLib.init();
}
