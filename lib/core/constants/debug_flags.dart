/// 调试编译开关。
///
/// 通过 --dart-define 在构建时控制：
///
///   显示调试叠加层（默认）：
///     flutter run
///
///   隐藏调试叠加层：
///     flutter run --dart-define=SHOW_DEBUG_OVERLAY=false
///
///   Release 构建时关闭：
///     flutter build ipa --dart-define=SHOW_DEBUG_OVERLAY=false
const bool kShowDebugOverlay = bool.fromEnvironment(
  'SHOW_DEBUG_OVERLAY',
  defaultValue: true,
);
