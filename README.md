# KineCue

> 中文 · 器械力量训练 · 零基础用户 · 实时 AI 动作纠正

手机摄像头实时识别骨骼关键点，结合力学角度模型判断动作是否标准，以中文语音和文字向用户提供教练级指导。首个 MVP 动作：深蹲。

---

## 核心用户

刚办了健身房会员卡、不知道如何使用器械、买不起私教的 25–35 岁城市上班族。

## 差异化

| 维度 | 竞品现状 | KineCue |
|---|---|---|
| 语言 | 英文为主 | 中文实时语音 |
| 场景 | 居家 / 瑜伽为主 | 健身房器械专项 |
| 用户门槛 | 假设有健身基础 | 零基础引导设计 |
| 纠错时机 | 事后分析 | 实时反馈 |

---

## 快速启动

**环境要求**

- Flutter 3.x（`flutter --version` 确认）
- Xcode 15+（iOS 真机调试必须）
- iPhone：iOS 15.5+，开启开发者模式

**运行**

```bash
git clone <repo>
cd kinecue
flutter pub get
cd ios && pod install && cd ..
flutter run          # 插上 iPhone 后运行
```

**摄像头权限**：首次启动会弹出权限请求，点允许后骨骼识别开始工作。

> ⚠️ 姿态识别在模拟器上无效，必须使用 iPhone 真机。

---

## 文档导航

| 文档 | 内容 |
|---|---|
| [docs/engineering/architecture.md](docs/engineering/architecture.md) | 架构设计、目录结构、编码规范 |
| [docs/engineering/testing.md](docs/engineering/testing.md) | 测试策略、规范、DoD |
| [docs/state/current-status.md](docs/state/current-status.md) | 当前状态基线、已知问题、技术债务 |
| [docs/tasks/SPRINT-W1.md](docs/tasks/SPRINT-W1.md) | 当前 Sprint 任务 |
| [docs/roadmap.md](docs/roadmap.md) | 后续 Sprint 规划 |
| [AGENTS.md](AGENTS.md) | AI 编程工具工作约定 |

---

## 技术栈

- **Flutter 3.x / Dart** — 跨平台，iOS 先行
- **google_mlkit_pose_detection** — 设备端姿态识别，17 关键点，< 20ms
- **camera** — 摄像头流，bgra8888 格式
- **Claude API**（W2 接入）— AI 教练指导语生成

---

*当前 Sprint：W1 · 2026-04-28 ~ 2026-05-04*
