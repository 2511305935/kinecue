# Sprint W3

**周期**：2026-05-05 ~ 2026-05-11（7 天）
**目标**：组间休息 + Kimi API 中文教练建议 + 技术债务清理
**状态**：⏳ 进行中

## Sprint Goal

> 完成一组目标次数后，进入休息倒计时界面，Kimi API 根据该组训练数据生成中文教练建议；
> 用户可开始下一组或结束训练。摄像头/TTS 重复代码提取为 mixin，权限拒绝有 UI 处理。
> `flutter test` 全部通过，`flutter analyze` 零警告。

---

## 架构决策

| 决策 | 结论 | 理由 |
|---|---|---|
| TD-08 代码复用 | Mixin (`CameraCoachMixin`) | 直接访问 State 成员，不阻塞继承 |
| API Key 管理 | `--dart-define` | 不入源码，开发期够用 |
| 休息界面 | State 驱动覆盖层 | 避免摄像头 dispose/reinit 延迟 |
| API 提供商 | Kimi API（Anthropic 兼容格式） | 已有 AK，`api.kimi.com/coding/v1` |
| API 模型 | moonshot-v1-auto | 中文优秀，短文本教练建议够用 |
| 响应方式 | 等待完整响应 | 文本短，流式无收益 |
| API 错误 | 静默降级 + 通用文案 | AI 是增强功能，离线可用 |
| 组数配置 | 选择页增加配置控件 | 用户可自定义 |

---

## 任务列表

### T1 · Logger 封装（TD-07）`[P0]` `[1.5h]`

- [ ] 创建 `lib/core/utils/logger.dart`：`Log.d()` / `Log.w()` / `Log.e()` + tag
- [ ] 新代码统一使用 Logger

**验收**：Logger 可用，`flutter analyze` 零警告。

---

### T2 · 摄像头权限拒绝 UI（TD-06）`[P0]` `[2h]`

- [ ] `_initCamera` try-catch `CameraException`
- [ ] 权限拒绝 → 显示中文错误界面 + "返回" 按钮 → pop 到选择页
- [ ] `copy.dart` 新增权限相关文案

**验收**：拒绝摄像头权限后显示友好界面，可返回。

---

### T3 · 提取 CameraCoachMixin（TD-08）`[P0]` `[5h]`

- [ ] 创建 `lib/shared/mixins/camera_coach_mixin.dart`
- [ ] 提取：initCamera, switchCamera, initTts, processFrame 骨架, isPoseRealistic, portraitPreviewSize, dispose, build scaffold
- [ ] `squat_coach_page.dart` 改用 mixin
- [ ] `curl_coach_page.dart` 改用 mixin
- [ ] 39 个测试全绿，Mac 无 regression

**验收**：每个 page 从 ~500 LOC 降到 ~280 LOC，功能无变化。

---

### T4 · Session 数据模型 + 组数管理 `[P0]` `[3h]`

- [ ] `lib/core/models/workout_config.dart`：targetReps, totalSets, restSeconds
- [ ] `lib/core/models/set_summary.dart`：单组统计
- [ ] `lib/core/models/session_state.dart`：SessionPhase enum
- [ ] 运动选择页增加配置控件（次数/组数/休息时长）
- [ ] `test/core/models/set_summary_test.dart`

**验收**：选择页可配置训练参数，数据模型测试通过。

---

### T5 · Kimi API Service `[P0]` `[4h]`

- [ ] `pubspec.yaml` 新增 `http: ^1.2.0`
- [ ] `lib/core/services/coaching_api_service.dart`
- [ ] `--dart-define=KIMI_API_KEY=sk-kimi-...` 读取
- [ ] POST `https://api.kimi.com/coding/v1/messages`（Anthropic Messages 兼容格式）
- [ ] model: `moonshot-v1-auto`，max_tokens: 200
- [ ] 错误处理：超时 10s / 无 key / 网络错误 → 返回 null
- [ ] `test/core/services/coaching_api_service_test.dart`（mock HTTP）

**验收**：API 调用成功返回中文建议，错误时返回 null。

---

### T6 · 休息界面 + 倒计时 `[P0]` `[4h]`

- [ ] `lib/shared/widgets/rest_screen_overlay.dart`
- [ ] repCount >= targetReps → 暂停摄像头 → SessionPhase.resting
- [ ] 倒计时 Timer.periodic（DateTime.now() 差值避免漂移）
- [ ] 异步调 Kimi API → 显示教练建议（loading → 文本）
- [ ] "开始下一组" / "结束训练" 按钮
- [ ] 所有组完成 → SessionPhase.completed → 训练总结

**验收**：完整休息流程可用，AI 建议正确显示。

---

### T7 · 每组数据收集 `[P1]` `[2.5h]`

- [ ] 训练中累积 errorCounts、关键相位角度、时长
- [ ] 组完成时打包 SetSummary 传给 API

**验收**：SetSummary 数据完整，API 能据此生成针对性建议。

---

### T8 · 集成 + 回归测试 `[P1]` `[2h]`

- [ ] 全部测试通过
- [ ] Mac 完整流程演示
- [ ] 离线测试（通用文案，不崩溃）
- [ ] `flutter analyze` 零警告

---

### T9 · 文档更新 `[P2]` `[1h]`

- [ ] 更新 `current-status.md`
- [ ] 更新 `roadmap.md`

---

## 每日排程

| 天 | 任务 | 产出物 |
|---|---|---|
| Day 1 周一 | T1 Logger + T2 权限 UI | 基础设施就绪 |
| Day 2 周二 | T3 Mixin 提取 | 两个 page 瘦身，39 测试绿 |
| Day 3 周三 | T3 调试 + T4 Session 模型 | Mixin 稳定，数据模型定义 |
| Day 4 周四 | T5 Kimi API Service | API 调用成功，mock 测试通过 |
| Day 5 周五 | T6 休息界面 + 倒计时 | 完整休息流程可用 |
| Day 6 周六 | T7 数据收集 + T8 集成测试 | 端到端流程跑通 |
| Day 7 周日 | T8 续 + T9 文档 | Sprint 收尾 |

**总工时**：~25h

---

## 风险与降级

| 风险 | 降级方案 |
|---|---|
| Mixin 提取引发回归 | 放弃 mixin，保持重复，直接在两个 page 加 session 管理 |
| Kimi API 延迟 >5s | 已有 10s 超时 + 通用降级文案 |
| 无网络 / 无 API key | 静默降级，app 完全离线可用 |
| http 包依赖冲突 | 改用 dart:io HttpClient |
| 摄像头暂停/恢复不可靠 | 改为 dispose + reinit（2s 延迟，休息期可接受） |
| 配置控件 UI 占用时间 | 简化为三个 Stepper/Picker |

---

## 新增/修改文件清单

**新增（10 个）**：
```
lib/core/utils/logger.dart
lib/core/models/workout_config.dart
lib/core/models/set_summary.dart
lib/core/models/session_state.dart
lib/core/services/coaching_api_service.dart
lib/shared/mixins/camera_coach_mixin.dart
lib/shared/widgets/rest_screen_overlay.dart
test/core/models/set_summary_test.dart
test/core/services/coaching_api_service_test.dart
docs/tasks/SPRINT-W3.md
```

**修改（7 个）**：
```
pubspec.yaml                                           — 新增 http
lib/core/constants/copy.dart                           — 权限/休息/组数文案
lib/features/squat_coach/presentation/squat_coach_page.dart   — mixin + session
lib/features/bicep_curl_coach/presentation/curl_coach_page.dart — mixin + session
lib/features/exercise_selection/presentation/exercise_selection_page.dart — 组数配置
docs/state/current-status.md
docs/roadmap.md
```

---

## Sprint Review 检查清单

- [ ] Mac 演示：选择 → 配置 → 训练 → 组完成 → 休息 + AI 建议 → 下组 → 训练完成
- [ ] 深蹲 + 弯举各完成一次完整训练流程
- [ ] AI 教练建议中文显示（有 API key）
- [ ] 离线模式正常（通用文案，不崩溃）
- [ ] 摄像头权限拒绝 → 错误界面 → 返回选择页
- [ ] coach page 代码量明显减少（mixin 提取成功）
- [ ] `flutter test` 全绿
- [ ] `flutter analyze` 零警告
- [ ] 文档更新，代码推送 GitHub
