# Sprint W2

**周期**：2026-05-05 ~ 2026-05-11（7 天）
**目标**：多动作架构 + 哑铃弯举 + 运动选择页
**状态**：⏳ 待开始

## Sprint Goal

> 启动 app 后看到运动选择页，可选择深蹲或哑铃弯举；
> 做 5 个弯举时屏幕实时显示肘关节角度，正确计次，
> 错误动作（身体晃动、不完全伸展、不完全弯曲）有中文语音提示；
> `flutter test` 全部通过，`flutter analyze` 零警告。

---

## 架构设计

### 核心思路

W1 深蹲代码中，**运动无关的通用逻辑**（摄像头、ML Kit、TTS、防抖、计次触发、PosePainter 框架）和**运动特定逻辑**（角度模型、阶段枚举、错误类型、监控区配置、文案映射）需要分离。

### 不做的事

- **不引入抽象基类/接口继承层**。只有两个运动，"配置参数"比 OOP 继承更简单
- **不提取 CameraCoachMixin**。StatefulWidget mixin 限制多，允许两个 coach page 各自持有 camera/TTS 代码（少量重复），W3 再评估提取
- **不引入 BLoC/Riverpod**

### 具体方案

1. **PosePainter 参数化**：`monitoredConnections`、`monitoredLandmarks`、`angleLabels` 从硬编码改为构造参数
2. **弯举独立 feature 目录**：与深蹲平级，结构对称
3. **运动选择页**：app 入口改为选择页，Navigator.push 到对应 coach page

---

## 哑铃弯举力学模型

### 监控关节

| 关节 | 骨骼点（A-B-C，B 为顶点） | 意义 |
|---|---|---|
| 肘关节 | 肩 - 肘 - 腕 | **主判据**：弯举角度 |
| 肩关节 | 髋 - 肩 - 肘 | **辅助**：检测身体晃动 |

### 阈值（pose_thresholds.dart 新增）

```
kCurlElbowExtended  = 160.0   // > 此值 = 完全伸展
kCurlElbowPeak      = 40.0    // < 此值 = 到达顶峰
kCurlShoulderMin    = 5.0     // 大臂前倾下限
kCurlShoulderMax    = 35.0    // 大臂后摆上限
```

### 阶段状态机

```
EXTENDED（肘角 > 160°）
  ↓ 减小
CURLING（40° < 肘角 ≤ 160°，来自 extended）
  ↓ 到达顶峰
PEAK（肘角 ≤ 40°）
  ↓ 增大
LOWERING（40° < 肘角 ≤ 160°，来自 peak）
  ↓ 回伸展
EXTENDED → rep_count++
```

### 错误类型

| 错误 | 判定条件 | 文案 |
|---|---|---|
| `bodySwing` | 肩角 < 5° 或 > 35° | 大臂保持固定，不要借力晃动 |
| `incompleteExtension` | 从 lowering 回来但肘角未达 160° | 手臂完全伸直再弯曲 |
| `incompleteCurl` | cycleCompleted 但未到达 peak | 再弯高一点，充分收缩 |
| `good` | 无错误 | 动作标准！ |

### 监控区连线

弯举监控区：肩-肘、肘-腕（上臂+前臂）。默认检测左臂。

---

## 运动选择页

```
┌─────────────────────────┐
│                         │
│     KineCue             │
│     选择训练动作         │
│                         │
│  ┌───────────────────┐  │
│  │  深蹲              │  │
│  │  膝关节 · 髋关节   │  │
│  └───────────────────┘  │
│                         │
│  ┌───────────────────┐  │
│  │  哑铃弯举          │  │
│  │  肘关节            │  │
│  └───────────────────┘  │
│                         │
└─────────────────────────┘
```

点击卡片 → Navigator.push 到对应 coach page。

---

## 任务列表

### T1 · PosePainter 泛化 + 阈值文案扩展 `[P0]` `[3h]`

- [ ] `PosePainter` 改为接收 `monitoredConnections`、`monitoredLandmarks`、`angleLabels` 参数
- [ ] `SquatCoachPage` 传入深蹲配置，行为与 W1 完全一致
- [ ] `pose_thresholds.dart` 新增弯举阈值（kCurlElbow*, kCurlShoulder*）
- [ ] `copy.dart` 新增弯举反馈文案 + 运动选择页文案
- [ ] 新增 `lib/core/models/exercise_type.dart`

**验收**：现有 20 个测试全绿，`flutter analyze` 零警告，深蹲功能无 regression。

---

### T2 · 弯举领域层：角度模型 + 错误判定 + 状态机 `[P0]` `[4h]`

- [ ] 创建 `curl_angle_model.dart`（elbowAngle + shoulderAngle）
- [ ] 创建 `curl_form_checker.dart`（bodySwing 帧级判定）
- [ ] 创建 `curl_phase_detector.dart`（4 阶段状态机 + cycleCompleted）
- [ ] `curl_form_checker_test.dart`：6 个用例
- [ ] `curl_phase_detector_test.dart`：12 个用例

**验收**：18 个新测试全绿，`flutter analyze` 零警告。

---

### T3 · 弯举展示层：CurlCoachPage + CurlFeedbackWidget `[P0]` `[5h]`

- [ ] 创建 `curl_coach_page.dart`（参考 squat_coach_page 结构）
- [ ] `_computeAngles` 计算肘角（shoulder-elbow-wrist）和肩角（hip-shoulder-elbow）
- [ ] 传入弯举 monitoredConnections（肩-肘、肘-腕）给 PosePainter
- [ ] 创建 `curl_feedback_widget.dart`（肘角 + 肩角 + 计次 + 错误提示）
- [ ] 复用防抖机制（peak quality 帧计数、语音延迟阈值）

**验收**：Mac 上弯举时肘角实时变化，计次正确，语音提示正常。

---

### T4 · 运动选择页 + 路由 `[P1]` `[2h]`

- [ ] 创建 `exercise_selection_page.dart`
- [ ] 修改 `app.dart`：home 改为 `ExerciseSelectionPage`
- [ ] 两个 coach page 加返回按钮
- [ ] 返回选择页时释放摄像头资源

**验收**：启动 app 看到选择页，可进入深蹲或弯举，可返回。

---

### T5 · 集成测试 + 回归验证 `[P1]` `[2h]`

- [ ] 全部测试通过（预计 38+）
- [ ] Mac 上深蹲和弯举各做 5 个，验证计次和语音
- [ ] 微调弯举阈值（如需要）
- [ ] `flutter analyze` 零警告

**验收**：38+ 测试全绿，两个运动在 Mac 上演示通过。

---

### T6 · 文档更新 `[P2]` `[1h]`

- [ ] 更新 `architecture.md`：弯举力学模型、新增目录结构
- [ ] 更新 `current-status.md`
- [ ] 更新 `roadmap.md`：W2 标记完成，确认 W3

---

## 每日排程

| 天 | 任务 | 产出物 |
|---|---|---|
| Day 1 周一 | T1 PosePainter 泛化 | 深蹲无 regression，弯举配置就绪 |
| Day 2 周二 | T2 弯举领域层 + 测试 | 18 个新测试全绿 |
| Day 3 周三 | T3 弯举展示层（前半） | 弯举页面基本跑通 |
| Day 4 周四 | T3 弯举展示层（调试） | 弯举计次和语音完善 |
| Day 5 周五 | T4 运动选择页 | 完整路由流程 |
| Day 6 周六 | T5 集成测试 | 38+ 测试全绿 |
| Day 7 周日 | T6 文档 + 缓冲 | 文档更新，代码推送 |

---

## 风险与降级

| 风险 | 降级方案 |
|---|---|
| PosePainter 泛化引入 regression | 回滚泛化，弯举用独立 CurlPosePainter |
| 弯举功能未按时完成 | 砍掉 incompleteExtension/incompleteCurl，只保留 bodySwing |
| 运动选择页未完成 | 用 TabBar 替代独立选择页 |

---

## 新增/修改文件清单

**新增（9 个）**：
```
lib/core/models/exercise_type.dart
lib/features/bicep_curl_coach/domain/curl_angle_model.dart
lib/features/bicep_curl_coach/domain/curl_form_checker.dart
lib/features/bicep_curl_coach/domain/curl_phase_detector.dart
lib/features/bicep_curl_coach/presentation/curl_coach_page.dart
lib/features/bicep_curl_coach/presentation/curl_feedback_widget.dart
lib/features/exercise_selection/presentation/exercise_selection_page.dart
test/features/bicep_curl_coach/curl_form_checker_test.dart
test/features/bicep_curl_coach/curl_phase_detector_test.dart
```

**修改（4 个）**：
```
lib/shared/widgets/pose_painter.dart       — 参数化
lib/core/constants/pose_thresholds.dart    — 新增弯举阈值
lib/core/constants/copy.dart               — 新增弯举文案
lib/app.dart                               — 入口改为选择页
```

---

## Sprint Review 检查清单

- [ ] Sprint Goal 用 Mac 演示通过（选择页 → 弯举 → 5 次计次）
- [ ] `flutter test` 全部通过（38+）
- [ ] `flutter analyze` 零警告
- [ ] `docs/state/current-status.md` 已更新
- [ ] `docs/roadmap.md` W2 标记完成
- [ ] 代码推送 GitHub
