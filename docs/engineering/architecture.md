# 架构设计

> 变更频率：低。修改此文件需同步更新 AGENTS.md 中的相关约定。

---

## 整体架构

采用 **Feature-First + Clean Architecture** 分层，当前阶段以 StatefulWidget 管理状态，W3 后视复杂度决定是否引入 BLoC。

```
┌──────────────────────────────────────────┐
│            Presentation Layer            │
│   Pages · Widgets · StatefulWidget       │
├──────────────────────────────────────────┤
│              Domain Layer                │
│   Models · Use Cases · Checkers          │
├──────────────────────────────────────────┤
│           Infrastructure Layer           │
│   ML Kit · Camera · Claude API · DB      │
└──────────────────────────────────────────┘
```

## 数据流

```
CameraImage（bgra8888，<20ms）
  → PoseDetectorService（ML Kit 设备端推理）
  → AngleCalculator（向量点积，纯函数）
  → SquatFormChecker（规则引擎，纯函数）
  → UI 实时反馈（骨骼叠加 + 角度数值 + 颜色提示）

SquatFormChecker 触发错误
  → CoachAgent（Claude API，异步，W2 接入）
  → 中文语音 + 深度指导文字
```

**关键约束**：摄像头帧和骨骼坐标不离开设备，隐私优先。

---

## 目录结构

```
lib/
├── main.dart                          # 仅 runApp()，< 10 行
├── app.dart                           # MaterialApp、路由、主题
│
├── core/                              # 跨 feature 通用能力
│   ├── constants/
│   │   ├── pose_thresholds.dart       # 关节角度阈值（唯一数据源）
│   │   └── copy.dart                  # 所有用户可见文案
│   ├── extensions/
│   │   └── pose_landmark_ext.dart     # PoseLandmark 扩展方法
│   └── utils/
│       └── angle_calculator.dart      # 向量角度计算（纯函数）
│
├── features/
│   ├── pose_detection/                # 摄像头 + 骨骼识别
│   │   ├── data/
│   │   │   └── pose_detector_service.dart
│   │   ├── domain/
│   │   │   └── pose_model.dart
│   │   └── presentation/
│   │       ├── pose_detection_page.dart
│   │       ├── pose_painter.dart
│   │       └── camera_preview_wrapper.dart
│   │
│   └── squat_coach/                   # 深蹲教练（W1）
│       ├── domain/
│       │   ├── squat_angle_model.dart
│       │   ├── squat_form_checker.dart
│       │   └── squat_phase_detector.dart
│       └── presentation/
│           ├── squat_coach_page.dart
│           └── squat_feedback_widget.dart
│
└── shared/
    └── widgets/
        └── confidence_badge.dart

test/
├── core/utils/
│   └── angle_calculator_test.dart
└── features/squat_coach/
    ├── squat_form_checker_test.dart
    └── squat_phase_detector_test.dart
```

**原则**：每个 feature 自包含，禁止 feature 之间直接互相 import，共用逻辑提升到 `core/`。

---

## 姿态识别坐标系

这是本项目最容易出错的部分，务必遵循以下约定。

### ML Kit 坐标说明

iOS 上 ML Kit 返回的 landmark 坐标**已是修正后的 portrait 显示坐标**，不需要手动做轴交换。

```
rotation270（iPhone 前置摄像头）：
  px = portraitW - lx * portraitW / imageW   ← 含内建镜像
  py = ly * portraitH / imageH

rotation90（iPhone 后置摄像头）：
  px = lx * portraitW / imageW
  py = ly * portraitH / imageH
```

### CameraPreview 对齐

`CameraPreview` 用 `FittedBox(fit: BoxFit.cover)` 等比缩放填满屏幕，骨骼坐标需叠加 coverScale 和 coverOffset：

```dart
// portraitSize = controller.value.previewSize（已对调宽高）
final scale = max(screen.width / portrait.width, screen.height / portrait.height);
final offsetX = (portrait.width * scale - screen.width) / 2;
final offsetY = (portrait.height * scale - screen.height) / 2;

// 最终屏幕坐标
screenX = px * scale - offsetX;
screenY = py * scale - offsetY;
```

### 置信度策略

- `likelihood < 0.5`：关键点不可信，**不参与角度计算，不渲染**
- 三点中任一点不可信：跳过该组角度计算，保持上一帧结果

---

## 深蹲力学模型

| 关节 | 骨骼点（A-B-C，B 为顶点） | 正常范围 | 判定意义 |
|---|---|---|---|
| 膝关节 | 髋 - 膝 - 踝 | 70°–110° | 是否蹲到位 |
| 髋关节 | 肩 - 髋 - 膝 | 45°–90° | 躯干前倾角 |
| 踝关节 | 膝 - 踝 - 脚趾 | 70°–100° | 踝背屈是否充分 |

角度计算公式（向量点积）：

```
BA = A - B，BC = C - B
θ = arccos（BA · BC / |BA||BC|）× 180 / π
```

**阈值为初始默认值**，需在真实用户数据上标定后调整，不要随意修改。

---

## 编码规范

### 命名

```dart
class SquatFormChecker {}                          // 类：UpperCamelCase
double calculateKneeAngle(...)                     // 方法/变量：lowerCamelCase
const double kMinSquatKneeAngle = 70.0;            // 常量：k 前缀
// 文件名：snake_case.dart
```

### 注释

公开 API 必须写 dartdoc：

```dart
/// 计算三点构成的关节角度（向量点积法）。
///
/// [a] 近端关节点（如髋部）
/// [b] 中心关节点（如膝盖）— 角度顶点
/// [c] 远端关节点（如踝部）
///
/// 返回 0–180 度。若任意两点重合返回 0。
double calculate(PoseLandmark a, PoseLandmark b, PoseLandmark c)
```

### 常量管理

- 角度阈值：`lib/core/constants/pose_thresholds.dart`（唯一数据源）
- 用户可见文案：`lib/core/constants/copy.dart`
- 禁止在 widget 或 checker 内部硬编码数字和中文字符串

### Lint

项目启用严格 lint（`analysis_options.yaml`），`flutter analyze` 必须零 warning。

### Git 提交规范（Conventional Commits）

```
feat(squat):    实现膝关节角度计算
fix(painter):   修复 rotation270 坐标偏移
test(angle):    添加 calculateAngle 边界测试
refactor(core): 拆分 main.dart 为 feature 模块
chore(deps):    升级 camera 到 0.11.1
docs(arch):     更新坐标系变换说明
```

---

*最后更新：2026-04-26*
