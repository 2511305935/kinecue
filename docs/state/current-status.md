# 当前状态基线

> 变更频率：高。每个 Sprint 结束后更新。
> 最后更新：2026-05-04（Sprint W2 完成）

---

## 已实现 ✅

| 功能 | 说明 |
|---|---|
| 运动选择页 | 启动入口，卡片式选择深蹲或哑铃弯举 |
| 实时摄像头流 | 前置/后置摄像头切换，bgra8888 格式 |
| 骨骼关键点检测 | Google ML Kit，17 个关键点，stream 模式 |
| PosePainter 参数化 | 监控区连线/关节/角度标签由调用方配置，支持多运动复用 |
| 骨架可视化（视觉层级） | 监控区：白色粗线（5px），达标绿/错误红；非监控区：灰色细线（2px） |
| 坐标系变换 | rotation90/270 + 前置摄像头镜像，FittedBox cover/contain 自适应 |
| **深蹲教练** | 膝角/髋角/踝角实时计算，4 阶段状态机，3 种错误检测，计次 + 语音 |
| **哑铃弯举教练** | 肘角/肩角实时计算，4 阶段状态机（extended→curling→peak→lowering），bodySwing 检测，计次 + 语音 |
| 实时反馈面板 | 关节角度 + 颜色编码 + 中文纠错提示 + 计次动画（深蹲/弯举各自独立） |
| 语音反馈 | 中文 TTS，纠错语音 + 计次播报，智能打断（快速动作不误报） |
| 视觉/语音分离阈值 | 红线 100ms 灵敏响应，纠错语音 500ms 延迟避免快速通过误报 |
| 模块化架构 | main.dart 10 行，按 feature 拆分，阈值/文案集中管理 |
| macOS 调试 | 支持 Xcode "My Mac (Designed for iPad)" 运行调试 |
| iOS 权限配置 | NSCameraUsageDescription 已正确放置在顶层 dict |

---

## 已知问题 🐛

| ID | 描述 | 严重程度 | 计划解决 |
|---|---|---|---|
| BUG-01 | 骨骼点与画面对齐在极端姿势下可能偏移 | 低 | 持续观察 |
| BUG-04 | Android `build.gradle.kts` 两个 TODO | 低 | W4+ |
| BUG-05 | 弯举无法检测是否手持哑铃（ML Kit 限制，徒手也能通过） | 低 | 已知限制 |

---

## 完全缺失 ❌

- AI 教练指导语（Claude API）
- 训练历史 / 数据持久化
- 组间休息 / 组数管理
- 用户认证 / 云同步
- 应用图标 / 品牌资源
- Android release 签名
- 摄像头权限拒绝的错误处理 UI
- 更多动作（硬拉、卧推、俯卧撑等）

---

## 技术债务

| ID | 描述 | 影响 | 计划解决 |
|---|---|---|---|
| TD-03 | Android `build.gradle.kts` TODO | 无法发布 Android | W4+ |
| TD-06 | 无摄像头权限拒绝的错误处理 UI | 影响体验 | W3 |
| TD-07 | Logger 封装未实现（debugPrint 直接使用） | 日志不统一 | W3 |
| TD-08 | 两个 coach page 摄像头/TTS 代码重复 | 维护成本 | W3 评估提取 mixin |

---

## 环境信息

```
Flutter:  3.41.6
Dart:     3.11.4
目标平台:  iOS 13.0+（先行）
调试方式:  Xcode "My Mac (Designed for iPad)" 或 iPhone 真机
测试设备:  iPhone X / Mac（Apple Silicon）
```

---

## 上次 Sprint Review 结论

W2（多动作 + 运动选择页）完成：
- PosePainter 参数化，支持不同运动配置不同监控区
- 哑铃弯举教练：肘角/肩角实时检测，4 阶段状态机，bodySwing 纠错
- 运动选择页：卡片 UI，Navigator 跳转，摄像头资源正确释放
- 39 个单元测试全绿，flutter analyze 零警告
- 已知限制：弯举无法检测是否手持哑铃（ML Kit 不支持物体检测）
