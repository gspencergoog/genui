
import 'package:genui/genui.dart';

void main() {
  final tool = BeginRenderingTool(
    handleMessage: (msg) {},
    catalogId: 'test',
  );
  print(tool.catalogId);
}
