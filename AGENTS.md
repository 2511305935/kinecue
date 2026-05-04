# KineCue 项目工作约定

## 编码原则

- 编码前先思考：不确定时要询问，不要默默选择一种解释就直接开始
- 简约至上：代码最简化，不做任何过度设计
- 精确编辑：只修改必要的部分，不要顺便修复其他代码
- 目标驱动：在开始前将模糊的指令转化为可验证的目标
- 真机优先：摄像头、骨骼识别、坐标变换相关改动必须在 iPhone 真机上验证，模拟器结果无效

## 项目目标

KineCue 是一款面向零基础健身人群的 AI 动作纠正教练 App。
通过手机摄像头实时识别骨骼关键点，结合力学角度模型判断器械训练动作是否标准，
以中文语音和文字向用户提供实时纠正指导。首个 MVP 动作：深蹲。

## 命名约定

| 用途 | 规范 | 值 |
|---|---|---|
| 品牌 / App Store 显示名 | 驼峰 | `KineCue` |
| `pubspec.yaml name` | 全小写（Flutter 强制） | `kinecue` |
| 项目文件夹 / Git repo | 小写 | `kinecue` |
| iOS `CFBundleDisplayName` | 驼峰 | `KineCue` |

## 当前技术约束

- Flutter 3.x / Dart，iOS 先行，后扩 Android
- 姿态识别：`google_mlkit_pose_detection ^0.11.0`，设备端推理，不上传视频帧
- 摄像头：`camera ^0.11.0`，bgra8888 格式，前置摄像头优先
- 状态管理：当前阶段使用 StatefulWidget + setState，本阶段不引入 BLoC / Riverpod
- UI 风格：Material Dark Theme，本阶段不做 Cupertino 迁移
- 本阶段不接入 Claude API、Firebase、数据库
- 本阶段不做用户账号系统、训练历史持久化

## 生效文件

开始任何工作前，按顺序阅读以下文件：

1. `docs/state/current-status.md` — 当前实现状态、已知问题、技术债务
2. `docs/engineering/architecture.md` — 架构设计、目录结构、坐标系约定、编码规范
3. `docs/engineering/testing.md` — 测试策略、DoD、运行方式
4. `docs/tasks/SPRINT-W1.md` — 当前 Sprint 任务范围与验收标准

如果多个文件之间出现范围冲突：

- 以 `docs/tasks/SPRINT-W1.md` 为当前任务范围的唯一准则
- 以 `docs/state/current-status.md` 为当前事实状态的唯一准则
- 以 `docs/engineering/architecture.md` 为实现边界和编码规范的唯一准则
- 以 `docs/engineering/testing.md` 为测试要求和 DoD 的唯一准则

## 工作方式

- 先总结你理解的目标、约束、风险
- 先输出 plan，再开始改代码
- 小步提交，优先低风险改动
- 坐标变换逻辑（rotation / mirror / coverScale）极易出错：
  改动前说明变换公式，改动后描述预期视觉效果供真机验证
- 如发现需求冲突或实现风险，先暂停并说明，再等待确认

## 代码要求

- 保持现有代码风格（snake_case 文件名，lowerCamelCase 方法）
- 角度阈值唯一数据源：`lib/core/constants/pose_thresholds.dart`
- 用户可见文案唯一数据源：`lib/core/constants/copy.dart`
- 禁止在 widget 或 checker 内部硬编码数字和中文字符串
- 新功能必须有对应单元测试，或在输出中明确说明为什么无法补测：
  - 纯函数（角度计算、规则判定、状态机）：必须有测试
  - ML Kit / Camera / Claude API 调用：用 Mock 隔离，无需直接测试
- ML Kit 推理在设备端完成，禁止将摄像头帧或骨骼坐标发送到任何外部服务
- `flutter analyze` 必须零 warning，提交前运行

## 输出格式

每次任务结束后输出：

**已完成项**
- （列出实际完成的子任务，与 SPRINT-Wx.md 的 checkbox 对应）

**文件变更**
- （新增 / 修改的文件路径）

**测试结果**
- `flutter test` 通过 / 失败数量

**真机验证**
- 在 iPhone 上观察到的实际视觉效果

**风险点**
- 已知问题、不确定项

**后续建议**
- 下一步推荐做什么
