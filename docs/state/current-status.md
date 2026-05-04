# 当前状态基线

> 变更频率：高。每个 Sprint 结束后更新。
> 最后更新：2026-05-04（Sprint W1 结束）

---

## 已实现 ✅

| 功能 | 说明 |
|---|---|
| 实时摄像头流 | 前置/后置摄像头切换，bgra8888 格式 |
| 骨骼关键点检测 | Google ML Kit，17 个关键点，stream 模式 |
| 骨架可视化（视觉层级） | 监控区：白色粗线（5px），达标绿/错误红；非监控区：灰色细线（2px） |
| 坐标系变换 | rotation90/270 + 前置摄像头镜像，FittedBox cover/contain 自适应 |
| 关节角度计算 | 膝角、髋角、踝角，向量点积法，实时叠加显示 |
| 深蹲状态机 | 4 阶段（standing→descending→bottom→ascending），膝角驱动 |
| 深蹲计次 | 完整循环 + 底部质量达标（≥3 帧）才计为有效深蹲 |
| 动作纠错 | 3 种错误检测：notDeepEnough / kneeOverToe / backTooForward |
| 实时反馈面板 | 三关节角度 + 颜色编码 + 中文纠错提示 + 计次动画 |
| 语音反馈 | 中文 TTS，纠错语音 + 计次播报，智能打断（快速下蹲不误报） |
| 视觉/语音分离阈值 | 红线 100ms 灵敏响应，纠错语音 500ms 延迟避免快速通过误报 |
| 模块化架构 | main.dart 10 行，功能按 feature 拆分，阈值/文案集中管理 |
| macOS 调试 | 支持 Xcode "My Mac (Designed for iPad)" 运行调试 |
| iOS 权限配置 | NSCameraUsageDescription 已正确放置在顶层 dict |

---

## 已知问题 🐛

| ID | 描述 | 严重程度 | 计划解决 |
|---|---|---|---|
| BUG-01 | 骨骼点与画面对齐在极端姿势下可能偏移 | 低 | 持续观察 |
| BUG-04 | Android `build.gradle.kts` 两个 TODO | 低 | W4+ |

---

## 完全缺失 ❌

- 多动作支持（弯举、俯卧撑等）
- 运动选择 UI
- AI 教练指导语（Claude API）
- 训练历史 / 数据持久化
- 用户认证 / 云同步
- 应用图标 / 品牌资源
- Android release 签名
- 摄像头权限拒绝的错误处理 UI

---

## 技术债务

| ID | 描述 | 影响 | 计划解决 |
|---|---|---|---|
| ~~TD-01~~ | ~~`widget_test.dart` 引用 `MyApp`~~ | ~~已解决~~ | W1-T5 ✅ |
| ~~TD-02~~ | ~~`main.dart` 单文件无模块化~~ | ~~已解决~~ | W1-T1 ✅ |
| TD-03 | Android `build.gradle.kts` TODO | 无法发布 Android | W4+ |
| ~~TD-04~~ | ~~README 是 Flutter 默认模板~~ | ~~已解决~~ | W1-T6 ✅ |
| ~~TD-05~~ | ~~坐标对齐精度~~ | ~~已验证可用~~ | W1 ✅ |
| TD-06 | 无摄像头权限拒绝的错误处理 UI | 影响体验 | W2 |
| TD-07 | Logger 封装未实现（debugPrint 直接使用） | 日志不统一 | W2 |

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

W1（深蹲教练核心）完成：
- 深蹲实时角度检测 + 4 阶段状态机 + 计次逻辑全部跑通
- 视觉反馈三色骨骼线（白/绿/红）+ 语音智能打断已验证
- 深蹲到位阈值调整为 95°（更严格），快速下蹲不误报纠错语音
- 20 个单元测试全绿，flutter analyze 零警告
- 代码已推送 GitHub：https://github.com/2511305935/kinecue
