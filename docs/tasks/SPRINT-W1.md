# Sprint W1

**周期**：2026-04-28 ~ 2026-05-04（7 天）  
**目标**：深蹲膝关节角度实时显示 + 动作正误判断完整闭环

## Sprint Goal

> 用 iPhone 对着自己做 5 个深蹲，屏幕实时显示三个关节角度数值，
> 动作达标时绿色，未达标时黄/红色提示，计次正确累加，`flutter test` 全部通过。

---

## 任务列表

### T1 · 代码重构：拆分 main.dart `[P0]` `[3h]`

其他任务依赖此任务，Day 1 必须完成。

- [ ] 创建 `lib/app.dart`，迁移 `MaterialApp`
- [ ] 创建 `lib/features/pose_detection/data/pose_detector_service.dart`，封装 ML Kit
- [ ] 创建 `lib/features/pose_detection/presentation/pose_painter.dart`，迁移 `PosePainter`
- [ ] 创建 `lib/features/pose_detection/presentation/pose_detection_page.dart`，迁移页面
- [ ] `main.dart` 精简为 `main()` + `runApp()`，< 15 行

**验收**：`flutter analyze` 零警告，iPhone 骨骼显示功能与重构前一致。

---

### T2 · 力学层：关节角度计算 `[P0]` `[2h]`

- [ ] 实现 `AngleCalculator.calculate(a, b, c)` 静态方法（向量点积）
- [ ] 实现 `SquatAngleModel`（膝角、髋角、踝角 + 各自置信度）
- [ ] 在 `lib/core/constants/pose_thresholds.dart` 定义阈值常量
- [ ] 单元测试：直角 90°、平角 180°、深蹲底部约 80°、两点重合容错

**验收**：`flutter test test/core/utils/angle_calculator_test.dart` 全绿，角度误差 < 1°。

---

### T3 · 深蹲教练：状态机 + 计次 `[P1]` `[4h]`

深蹲阶段状态机：

```
STANDING（膝角 > 150°）
  ↓ 减小
DESCENDING（150° > 膝角 > 110°）
  ↓ 到达最低点
BOTTOM（膝角 ≤ 110°）← 在此判定深度达标
  ↓ 增大
ASCENDING（110° < 膝角 < 150°）
  ↓ 回站立
STANDING → rep_count++
```

错误枚举：

```dart
enum SquatError { notDeepEnough, kneeOverToe, backTooForward, good }
```

- [ ] 实现 `SquatFormChecker.check(SquatAngleModel) → SquatError`
- [ ] 实现 `SquatPhaseDetector.update(double kneeAngle) → (SquatPhase, int repCount)`
- [ ] 单元测试：4 种错误状态边界条件（各含上下边界值）
- [ ] 在 `PosePainter` 叠加关节角度数值文字

**验收**：做深蹲时 repCount 正确累加，底部触发 `SquatError` 分类正确。

---

### T4 · UI：实时反馈面板 `[P1]` `[3h]`

```
┌──────────────────────────────┐
│  摄像头预览（全屏）            │
│  骨骼叠加（绿线，错误关节变红） │
│                              │
│  ┌── 关节角度 ─────────────┐  │
│  │  膝  127°  ✓           │  │
│  │  髋   68°  ✓           │  │
│  │  踝   82°  ✓           │  │
│  └────────────────────────┘  │
│                              │
│  ┌── 提示 ─────────────────┐  │
│  │  继续蹲低，膝盖弯曲超过90°│  │  ← 绿/黄/红
│  └────────────────────────┘  │
│                              │
│           计次：3             │
└──────────────────────────────┘
```

文案（收口到 `lib/core/constants/copy.dart`）：

| 错误 | 文案 |
|---|---|
| `notDeepEnough` | 继续蹲低，膝盖弯曲超过 90° |
| `kneeOverToe` | 膝盖不要超过脚尖，重心向后 |
| `backTooForward` | 收紧核心，躯干不要过度前倾 |
| `good` | 动作标准！ |

- [ ] 实现 `SquatFeedbackWidget`：三关节角度 + 颜色编码
- [ ] 实现计次组件（数字增加时缩放动画）
- [ ] 错误关节对应连线变红

**验收**：iPhone 真机实测，颜色变化与动作对应，计次动画流畅。

---

### T5 · 测试：修复 + 新增 `[P1]` `[2h]`

- [ ] 修复 `test/widget_test.dart`（`MyApp` 引用错误）
- [ ] `angle_calculator_test.dart`：直角、平角、深蹲底部、两点重合
- [ ] `squat_form_checker_test.dart`：
  - 膝角 = 120° → `notDeepEnough`
  - 膝角 = 90°、髋角 = 60°、踝角 = 85° → `good`
  - 髋角 = 30° → `backTooForward`
  - 边界：膝角 = 110°（临界值）

**验收**：`flutter test` 全部通过，零 failure。

---

### T6 · 工程配套 `[P2]` `[1h]`

- [ ] 更新 `README.md`（替换 Flutter 默认模板内容）
- [ ] 添加 `analysis_options.yaml` 严格 lint 规则
- [ ] 统一日志：`debugPrint` → `Logger` 封装

---

## 每日计划

| 日期 | 任务 | 产出物 |
|---|---|---|
| Day 1 周一 | T1 重构 | 干净模块化结构，iPhone 验证通过 |
| Day 2 周二 | T2 角度计算 + 测试 | `angle_calculator.dart` + 测试全绿 |
| Day 3 周三 | T3 状态机 | `squat_form_checker.dart` + 计次逻辑 |
| Day 4 周四 | T4 UI 反馈面板 | iPhone 看到角度数值 + 颜色提示 |
| Day 5 周五 | T5 测试 + T6 配套 | 全测试通过 + 文档更新 |
| Day 6–7 周末 | 联调缓冲 / Demo 视频 | W1 Demo 录制 |

---

## Sprint Review 检查清单

- [ ] Sprint Goal 用手机演示通过
- [ ] `flutter test` 全部通过（截图为证）
- [ ] `flutter analyze` 零警告
- [ ] `docs/state/current-status.md` 已更新
- [ ] 技术债务表已更新（TD-01、TD-02 标记为已解决）
- [ ] `docs/roadmap.md` W2 内容已确认
