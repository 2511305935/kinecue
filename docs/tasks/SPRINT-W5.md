# Sprint W5

**周期**：2026-05-11 ~ 2026-05-18（7 天）
**目标**：品牌主题系统 + 训练详情页 + 启动页优化 + UI 打磨
**状态**：⏳ 进行中

## Sprint Goal

> 建立 KineCue 品牌视觉体系（绿色主题），替换全部硬编码颜色；
> 历史记录可点击进入训练详情页，展示每组数据；
> 启动页背景匹配 app 暗色主题，消除白屏闪烁；
> 页面过渡动画、空状态改进、触感反馈等交互打磨。
> `flutter test` 全部通过，`flutter analyze` 零警告。

---

## 架构决策

| 决策 | 结论 | 理由 |
|---|---|---|
| 主题系统 | `AppColors` + `AppSpacing` + `AppTheme.darkTheme` | 颜色语义化常量，最小改动量 |
| 绿色色板 | 主色 `#00C853`，accent `#69F0AE`，dark `#00892E` | 从 greenAccent 升级但保持视觉连续性 |
| 详情页路由 | `sessionId` 传参，页内查库 | 解耦，支持未来 deep link |
| 详情页结构 | 单文件 `training_detail_page.dart` | 纯展示页，复杂度低 |
| 页面过渡 | `CupertinoPageRoute` | iOS 原生滑动返回体验 |
| 启动页 | 背景改 #121212，匹配 AppColors.surface | 消除白→黑闪烁 |

---

## 任务列表

### T1 · 品牌主题系统 `[P0]` `[5h]` ✅

- [x] 创建 `lib/core/theme/app_theme.dart`：AppColors / AppSpacing / AppTheme
- [x] 修改 `lib/app.dart` 使用 `AppTheme.darkTheme`
- [x] 替换 7 个文件中所有硬编码颜色（~85 处）

---

### T2 · 训练详情页 `[P0]` `[6h]` ✅

- [x] 创建 `lib/features/training_detail/presentation/training_detail_page.dart`
- [x] `copy.dart` 新增详情页文案 + `errorDisplayNames` 中文映射
- [x] `exercise_selection_page.dart` 历史卡片添加 `onTap` 导航 + chevron 图标

---

### T3 · 启动页优化 `[P1]` `[1h]` ✅

- [x] `LaunchScreen.storyboard` 背景色改为 #121212（匹配暗色主题）
- [ ] 应用图标替换（待用户提供 1024x1024 PNG 素材）

---

### T4 · UI 打磨 `[P1]` `[5h]` ✅

- [x] 页面过渡：`CupertinoPageRoute` 统一 iOS 风格滑动过渡
- [x] 运动卡片：绿色调 splash/highlight + `HapticFeedback.mediumImpact()`
- [x] 配置按钮：`HapticFeedback.lightImpact()`
- [x] 空状态改进：图标 + 主文字 + 引导提示文字
- [x] 休息倒计时：`AnimatedSwitcher` + `FadeTransition`
- [x] 训练完成：奖杯 `TweenAnimationBuilder` + `elasticOut` 入场动画

---

### T5 · 集成验证 + 文档 `[P1]` `[2h]`

- [x] `flutter analyze` 零警告
- [x] `flutter test` 55 个测试全绿
- [x] 更新 `current-status.md`
- [x] 更新 `roadmap.md`
- [x] 创建 `docs/tasks/SPRINT-W5.md`

---

## 新增/修改文件清单

**新增（2 个）**：
```
lib/core/theme/app_theme.dart
lib/features/training_detail/presentation/training_detail_page.dart
```

**修改（10 个）**：
```
lib/app.dart
lib/core/constants/copy.dart
lib/features/exercise_selection/presentation/exercise_selection_page.dart
lib/shared/widgets/rest_screen_overlay.dart
lib/shared/widgets/pose_painter.dart
lib/shared/mixins/camera_coach_mixin.dart
lib/features/squat_coach/presentation/squat_feedback_widget.dart
lib/features/bicep_curl_coach/presentation/curl_feedback_widget.dart
lib/features/pose_detection/presentation/pose_detection_page.dart
ios/Runner/Base.lproj/LaunchScreen.storyboard
```

---

## Sprint Review 检查清单

- [x] `grep -r "Colors.greenAccent" lib/` 零命中
- [x] 全 app 颜色统一使用 AppColors
- [x] 点击历史卡片 → 导航至详情页 → 显示每组数据
- [x] 启动页黑色背景
- [x] 页面切换有 iOS 滑动过渡动画
- [x] 卡片有触感反馈
- [x] 空状态有图标 + 引导文字
- [x] 倒计时数字有淡入淡出动画
- [x] 奖杯有弹性入场动画
- [x] `flutter test` 全绿
- [x] `flutter analyze` 零警告
