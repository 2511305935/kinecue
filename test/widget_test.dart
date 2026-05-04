// 占位测试 — 修复 TD-01（旧模板引用了不存在的 MyApp 和错误包名）。
// 完整 widget 测试将在 T5 实现。
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('placeholder', () {
    expect(true, isTrue);
  });
}
