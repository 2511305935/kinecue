# Sprint W1

**周期**：2026-04-28 ~ 2026-05-04（7 天）
**目标**：深蹲膝关节角度实时显示 + 动作正误判断完整闭环
**状态**：✅ 已完成

## Sprint Goal

> 用 iPhone 对着自己做 5 个深蹲，屏幕实时显示三个关节角度数值，
> 动作达标时绿色，未达标时黄/红色提示，计次正确累加，`flutter test` 全部通过。

---

## 任务列表

### T1 · 代码重构：拆分 main.dart `[P0]` ✅

- [x] 创建 `lib/app.dart`，迁移 `MaterialApp`
- [x] 创建 `lib/features/pose_detection/data/pose_detector_service.dart`，封装 ML Kit
- [x] 创建 `lib/shared/widgets/pose_painter.dart`，迁移 `PosePainter`
- [x] 创建 `lib/features/pose_detection/presentation/pose_detection_page.dart`，迁移页面
- [x] `main.dart` 精简为 `main()` + `runApp()`，10 行

---

### T2 · 力学层：关节角度计算 `[P0]` ✅

- [x] 实现 `AngleCalculator.calculate(a, b, c)` 静态方法（向量点积）
- [x] 实现 `SquatAngleModel`（膝角、髋角、踝角 + isFullyValid）
- [x] 在 `lib/core/constants/pose_thresholds.dart` 定义阈值常量
- [x] 单元测试：直角 90°、平角 180°、深蹲底部约 80°、两点重合容错

---

### T3 · 深蹲教练：状态机 + 计次 `[P1]` ✅

- [x] 实现 `SquatFormChecker.check(SquatAngleModel) → SquatError`
- [x] 实现 `SquatPhaseDetector.update(double kneeAngle) → (SquatPhase, bool cycleCompleted)`
- [x] 单元测试：4 种错误状态边界条件（各含上下边界值）
- [x] 在 `PosePainter` 叠加关节角度数值文字

**额外完成**：
- 底部质量检测（≥3 帧达标才计为有效深蹲）
- 视觉/语音分离阈值（红线 3 帧 ≈ 100ms，语音 15 帧 ≈ 500ms）
- 深蹲到位阈值调整为 95°（比原设计更严格）

---

### T4 · UI：实时反馈面板 `[P1]` ✅

- [x] 实现 `SquatFeedbackWidget`：三关节角度 + 颜色编码
- [x] 实现计次组件（数字增加时缩放动画）
- [x] 错误关节对应连线变红

**额外完成**：
- 监控区/非监控区视觉层级分离（白粗线 vs 灰细线）
- 三色状态骨骼线（白色默认 / 绿色达标 / 红色错误）
- 语音智能打断：达标时停止纠错语音，计次播报优先

---

### T5 · 测试：修复 + 新增 `[P1]` ✅

- [x] 修复 `test/widget_test.dart`（`MyApp` 引用错误）
- [x] `angle_calculator_test.dart`：直角、平角、深蹲底部、两点重合
- [x] `squat_form_checker_test.dart`：4 种错误状态 + 临界值
- [x] `squat_phase_detector_test.dart`：阶段转换 + 边界条件

**结果**：20 个测试全绿。

---

### T6 · 工程配套 `[P2]` ⚠️ 部分完成

- [x] 更新 `README.md`（替换 Flutter 默认模板内容）
- [x] `analysis_options.yaml` lint 规则
- [ ] 统一日志：`debugPrint` → `Logger` 封装（延至 W2）

---

## Sprint Review 检查清单

- [x] Sprint Goal 用 Mac (Designed for iPad) 演示通过
- [x] `flutter test` 全部通过（20/20）
- [x] `flutter analyze` 零警告
- [x] `docs/state/current-status.md` 已更新
- [x] 技术债务表已更新（TD-01、TD-02、TD-04、TD-05 标记为已解决）
- [ ] `docs/roadmap.md` W2 内容已确认
