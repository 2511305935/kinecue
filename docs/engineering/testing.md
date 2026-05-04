# 测试策略

> 变更频率：低。新增测试层时更新此文件。

---

## 测试金字塔

```
           ╱╲
          ╱  ╲        E2E（W3+）
         ╱────╲       集成测试：摄像头→姿态→反馈链路
        ╱      ╲
       ╱────────╲     Widget 测试（W2+）
      ╱          ╲    UI 交互、反馈面板渲染
     ╱────────────╲
    ╱              ╲  单元测试（W1 必须建立）
   ╱────────────────╲ 纯函数、状态机、规则引擎
```

---

## 各层职责

### 单元测试（Unit Tests）

**覆盖目标**：所有纯函数，无任何外部依赖。

```
必须测试：
  AngleCalculator.calculate()      纯数学，无依赖
  SquatFormChecker.check()         规则判定，无依赖
  SquatPhaseDetector.update()      状态机，无依赖

无需测试（用 Mock 隔离）：
  ML Kit PoseDetector              外部 SDK
  CameraController                 硬件依赖
  Claude API                       网络调用
```

### Widget 测试（W2 开始）

覆盖 `SquatFeedbackWidget` 在不同 `SquatError` 输入下的渲染正确性。

### 集成测试（W3 开始）

使用 `integration_test` 包，在真机上验证完整链路：摄像头启动 → 骨骼检测 → 角度计算 → UI 更新。

---

## 测试规范

### 文件位置

测试文件与源文件保持镜像结构：

```
lib/core/utils/angle_calculator.dart
test/core/utils/angle_calculator_test.dart

lib/features/squat_coach/domain/squat_form_checker.dart
test/features/squat_coach/squat_form_checker_test.dart
```

### 命名规范（Given-When-Then）

```dart
test('given knee angle 120°, when check(), then returns notDeepEnough', () {
  // Arrange
  final model = SquatAngleModel(kneeAngle: 120, hipAngle: 60, ankleAngle: 85);

  // Act
  final result = SquatFormChecker.check(model);

  // Assert
  expect(result, SquatError.notDeepEnough);
});
```

### 边界测试要求

每个纯函数必须覆盖：
- 正常输入（典型值）
- 边界值（阈值上下各 1°）
- 异常输入（两点重合、负值、NaN）

---

## Definition of Done

每个任务合入前必须满足全部条件：

- [ ] `flutter analyze` 零 error、零 warning
- [ ] `flutter test` 全部通过
- [ ] 新增公开函数有对应单元测试，或在 PR 中说明不可测原因
- [ ] 在 iPhone 真机上人工验证核心路径
- [ ] commit message 符合 Conventional Commits 规范
- [ ] 涉及坐标变换的改动：PR 描述中说明变换公式和预期视觉效果

---

## 运行测试

```bash
# 全量单元测试
flutter test

# 单文件
flutter test test/core/utils/angle_calculator_test.dart

# 含覆盖率报告
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html

# 静态分析
flutter analyze
```

---

*最后更新：2026-04-26*
