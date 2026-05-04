# 当前状态基线

> 变更频率：高。每个 Sprint 结束后更新。
> 最后更新：2026-04-26（Sprint W1 开始前）

---

## 已实现 ✅

| 功能 | 说明 |
|---|---|
| 实时摄像头流 | 前置摄像头优先，bgra8888 格式 |
| 骨骼关键点检测 | Google ML Kit，17 个关键点，stream 模式 |
| 骨架可视化 | 14 条连线（绿）+ 关键点（黄），置信度 > 0.5 才渲染 |
| 坐标系变换 | rotation90/270 + 前置摄像头镜像，FittedBox cover 对齐 |
| iOS 权限配置 | NSCameraUsageDescription 已正确放置在顶层 dict |

---

## 已知问题 🐛

| ID | 描述 | 严重程度 | 计划解决 |
|---|---|---|---|
| BUG-01 | 骨骼点与画面对齐在部分姿势下偏移 | 中 | W1 联调验证 |
| BUG-02 | `widget_test.dart` 引用不存在的 `MyApp` | 低 | W1-T5 |
| BUG-03 | `main.dart` 单文件约 10KB，无法维护 | 高 | W1-T1 |
| BUG-04 | Android `build.gradle.kts` 两个 TODO | 低 | W4+ |

---

## 完全缺失 ❌

- 动作识别（深蹲 / 弯举等）
- 关节角度计算
- 计次逻辑
- 实时纠错反馈
- 语音提示
- 训练历史 / 数据持久化
- 用户认证 / 云同步
- 运动选择 UI
- 应用图标 / 品牌资源
- Android release 签名

---

## 技术债务

| ID | 描述 | 影响 | 计划解决 |
|---|---|---|---|
| TD-01 | `widget_test.dart` 引用 `MyApp` | CI 无法运行 | W1-T5 |
| TD-02 | `main.dart` 单文件无模块化 | 无法协作 | W1-T1 |
| TD-03 | Android `build.gradle.kts` TODO | 无法发布 Android | W4+ |
| TD-04 | README 是 Flutter 默认模板 | 影响协作 | W1-T6 |
| TD-05 | 坐标对齐精度待真机多场景验证 | 影响纠错准确性 | W1 验证 |
| TD-06 | 无摄像头权限拒绝的错误处理 UI | 影响体验 | W2 |

---

## 环境信息

```
Flutter:  3.x（以 flutter --version 实际输出为准）
Dart:     3.11.4+
目标平台:  iOS 15.5+（先行）
测试设备:  iPhone X，前置摄像头 sensorOrientation = 270
           img: 480×640，rot: rotation270
           portrait: 480×640，scale: 1.27
```

---

## 上次 Sprint Review 结论

W0（基础搭建）完成：摄像头流 + 骨骼可视化在 iPhone 真机上跑通。
坐标系对齐经过多次迭代，当前方案（FittedBox + coverScale）基本可用，
边缘场景（极端姿势、手持器械遮挡）待 W1 继续观察。
