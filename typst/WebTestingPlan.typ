#import "templates/template.typ": project, title-page, contents-page, section-page, with-page-numbering, acias-table, kbd

#show: project

#title-page(
  title: [Web Testing Plan / 前端测试计划],
  subtitle: [Unit & UI Testing Strategy / 单元 & UI 测试策略],
  author: [Feng Yu / 冯宇],
  date: [November 2025 / 2025年11月],
  version: [Version 1.0 / 版本 1.0]
)

#contents-page("Table of Contents / 目录")

#show: with-page-numbering

= Testing Framework Selection / 测试框架选型

== Framework Combination / 测试框架组合

Current testing stack / 当前测试技术栈：

- *Jest* —— responsible for pure logic, functions, utilities, Redux, hooks unit tests  
  *Jest* —— 负责纯逻辑、函数、工具类、Redux、hooks 等单元测试
- *Playwright* —— responsible for UI behavior verification, interaction flows, E2E testing  
  *Playwright* —— 负责 UI 行为验证、交互流程、E2E 测试

*Advantages of the combination / 两者组合的优势*：

- Jest is fast, isolated, and suitable for CI integration  
  Jest 速度快、隔离性强，适合集成到 CI
- Playwright can cover map interactions, search, panels, popups, and other complex UI flows  
  Playwright 可覆盖地图交互、搜索、面板、弹窗等复杂 UI 流程
- Forms a complete system of *unit tests + UI automation + end-to-end testing*  
  形成 *单元测试 + UI 自动化 + 端到端* 的完整体系

= MasterMap (1.0) Testing Plan / MasterMap (1.0) 测试计划

== Focus on Core Features Using the 80/20 Rule / 使用二八定律（80/20）聚焦核心功能

*Priority coverage / 优先覆盖*：

- Search functionality (keyword search, result click, map navigation)  
  搜索功能（关键词搜索、结果点击、跳转地图）
- Panel components (PlaceInfo, SegmentInfo, toolbars, etc.)  
  面板类组件（PlaceInfo、SegmentInfo、工具栏等）
- Basic interactions (layer toggle, zoom in/out, route viewing)  
  基础交互（图层开关、放大缩小、路线查看）

> For map projects, 80% of bugs come from 20% of core features. UI tests must cover these parts.  
> 对于地图项目，80% bug 来自核心 20% 功能，这部分必须写 UI 测试

== Submission-Driven Testing Strategy / 提交驱动测试策略

*Principle / 原则*: “Every code submission affecting a module must include tests”  
*原则*：“只要代码提交，涉及到的模块都必须写测试”

- Modified functions, hooks, or components ⇒ must add unit tests (Jest)  
  修改的函数、hook、组件 ⇒ 必须补单元测试（Jest）
- Modified UI displays or button interactions ⇒ Playwright needs 1–2 scenario tests  
  修改的 UI 展示、按钮交互 ⇒ Playwright 需要补 1~2 条场景
- Check test coverage changes via PRs  
  通过 PR 检查测试覆盖率变化

*Goal / 目标*：

- Coverage does not need to be 100%, but should not decrease with each iteration  
  覆盖率不求全 100%，但每次迭代不下降
- Continuously build a maintainable testing system  
  持续积累可维护的测试体系

= MasterMap (2.0) Refactor Testing Plan / MasterMap (2.0) 重构测试计划

== Reusable Logic from MasterMap 1.0 / MasterMap 1.0 测试的复用逻辑

- Reusable: login / registration / basic utility functions  
  可复用：登录 / 注册 / 基础工具函数
- Non-reusable: all other 1.0 tests are discarded  
  不可复用：除登录注册以外的 1.0 测试全部废弃  
  *Reason / 原因*: 1.0 and 2.0 have completely different UI, component tree, and map engine (Cesium)  
  1.0 与 2.0 的 UI、组件树、地图引擎完全不同（Cesium）

== Testing System Designed from Scratch / 测试体系从零开始设计

- MasterMap 2.0 uses Cesium + newly wrapped UI + new map architecture; tests must be re-planned  
  MasterMap 2.0 使用 Cesium + 新封装的 UI + 新地图架构，测试必须重新规划

*2.0 Testing Directions / 2.0 的测试方向*：

- Fully wrap map interaction functions and design unit tests  
  全面封装地图交互函数并设计单元测试  
  - flyTo, addLayer, highlightFeature, pickPosition  
    flyTo, addLayer, highlightFeature, pickPosition  
  - Only API-level testing, do not directly test Cesium internals  
    API 化之后才能单测，不直接测 Cesium 内部
- Re-wrap components/UI to ensure testability  
  组件/UI 重新封装，确保可测性
- Split Redux state management into pure logic for easier testing  
  状态管理（Redux）拆分为纯逻辑便于测试
- UI behavior tests are more important  
  UI 行为测试更重要

*Playwright covers the following key flows / Playwright 覆盖以下关键流程*：

- Search → map navigation  
  搜索 → 地图定位
- Click on map → open detail panel  
  点击地图 → 打开详情面板
- Layer toggle → map effect change  
  图层开关 → 地图效果切换
