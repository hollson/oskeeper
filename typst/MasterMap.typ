#import "/templates/template.typ": project, title-page, contents-page, section-page, with-page-numbering, acias-table, kbd

#show: project

#title-page(
title: [npm 模块化 / npm Modularization],
subtitle: [模块化 JavaScript 代码管理与发布 / Modular JavaScript Code Management and Publishing],
author: [Feng Yu / 冯宇],
date: [November 2025 / 2025年11月],
version: [Version 1.0 / 版本 1.0]
)

#contents-page("Table of Contents / 目录")

#show: with-page-numbering

= 项目概述 / Project Overview

== 项目背景 / Background
MasterMap 是一款聚焦地理信息可视化与交互的核心系统，支持图层管理、地图瓦片加载、AI 对话交互、用户权限控制等核心能力。
MasterMap is a core system focused on geospatial information visualization and interaction, supporting layer management, map tile loading, AI chat interaction, and user access control.

为提升功能复用性、降低维护成本，特将核心功能拆分为独立模块并进行 npm 包化，形成可跨项目复用的前端/后端组件库。
To improve functionality reuse and reduce maintenance costs, core features are split into independent modules and packaged as npm packages, forming a cross-project reusable frontend/backend component library.

== 项目目标 / Objectives

- 实现核心功能的模块化拆分，确保高内聚、低耦合
Implement modularization of core functionalities, ensuring high cohesion and low coupling

- 前端采用 Monorepo 管理多 npm 包，统一版本与构建流程
Manage multiple npm packages in a frontend Monorepo with unified versioning and build processes

- 后端模块提供标准 API 接口，支持跨服务调用与独立部署
Provide standard API interfaces for backend modules, supporting cross-service calls and independent deployment

- 形成标准化文档模板，便于后续模块扩展与项目对接
Establish standardized documentation templates for future module extension and project integration

= 模块架构与规划 / Module Architecture and Planning

== 核心模块清单 / Core Module List
#acias-table(
caption: [MasterMap 前端核心模块清单（Monorepo） / MasterMap Frontend Core Module List (Monorepo)],
([npm 包名 / Package Name], [模块分类 / Category], [核心功能 / Core Functionality], [技术栈 / Tech Stack]),

[mastermap/core], [核心基础 / Core Utilities], [共享类型/工具函数/事件总线 / Shared Types, Utility Functions, Event Bus], [TypeScript, RxJS],
[mastermap/map-adapter], [地图渲染 / Map Rendering], [封装第三方地图库，提供统一 API / Encapsulate 3rd-party map libraries with unified API], [TypeScript, Cesium],
[mastermap/layer-manager], [图层管理 / Layer Management], [图层加载/样式配置/数据解析 / Layer Loading, Style Config, Data Parsing], [TypeScript],
[mastermap/auth-client], [用户权限 / User Auth], [登录/Token 管理/权限校验 / Login, Token Management, Access Control], [TypeScript, Axios],
[mastermap/ai-chat-widget], [AI 交互 / AI Interaction], [聊天 UI 组件/上下文管理 / Chat UI Component, Context Management], [TypeScript, React],
)

= 模块使用示例 / Module Usage Examples

== 前端模块调用代码 / Frontend Module Usage Example
```// 地图初始化与图层加载示例 / Map initialization and layer loading example

import { LayerType } from 'mastermap/core';
import { MapAdapter } from 'mastermap/map-adapter';
import { LayerManager } from 'mastermap/layer-manager';

// 初始化地图实例 / Initialize map instance
const map = new MapAdapter({
  container: 'map-container',
  style: 'mapbox://styles/mapbox/light-v11',
  center: [116.40, 39.90],
  zoom: 10
});

// 加载基础瓦片图层 / Load base tile layer
const layerManager = new LayerManager(map);
await layerManager.addLayer({
  id: 'basemap',
  type: LayerType.TILE,
  url: 'https://tiles.example.com/basemap/{z}/{x}/{y}.png',
  visible: true
});


== 后端 API 调用示例 / Backend API Example
// HTTP 请求格式示例 / HTTP request format example

GET /api/layers/{layerId}
Headers:
  Authorization: Bearer {token}
Response:
  {
    "id": "basemap",
    "name": "基础地图 / Base Map",
    "url": "https://tiles.example.com/basemap/{z}/{x}/{y}.png",
    "visible": true
  }

```
= 开发与操作指南 / Development and Operation Guide

== 开发流程清单 / Development Workflow
// 使用模板列表样式，规范开发步骤 / Standard development steps using list template


+ 需求确认：明确模块功能边界与接口定义 / Requirement confirmation: clarify module boundaries and interface definitions

+ 开发实现：遵循 ESModule 规范，编写单元测试 / Development: follow ESModule standards and write unit tests

+ 本地验证：通过 demo 应用验证模块功能 / Local validation: verify module functionality via demo app

+ 提交审核：发起 MR 并关联需求文档 / Submit for review: create MR and link requirement documents

+ 发布上线：按语义化版本发布至 npm 仓库 / Release: publish to npm registry with semantic versioning

= 附录 / Appendix

== 依赖版本说明 / Dependency Version List
#acias-table(
caption: [核心依赖版本清单 / Core Dependency Version List],
([依赖名称 / Dependency], [版本要求 / Version Requirement], [用途说明 / Purpose]),

[TypeScript], [^5.2.0], [类型安全开发 / Type-safe development],
[pnpm], [^8.0.0], [Monorepo 依赖管理 / Monorepo dependency management],
[cesium], [^1.59.0-github-master2108], [地图渲染核心 / Map rendering core],
[cesium/wasm-splats], [^0.1.0-alpha.2], [Cesium WebAssembly 支持 / Cesium WebAssembly support],
)

== 文档维护说明 / Documentation Maintenance Notes


- 文档版本与项目版本保持一致，更新版本时同步修改封面版本号 / Keep document version consistent with project version; update cover version when changing project version

- 新增模块需在「模块架构」章节补充对应表格条目 / Add new modules to the “Module Architecture” section table

- 代码示例需与最新版模块 API 保持同步 / Ensure code examples match latest module API

- 快捷键与操作指南需根据开发工具更新及时调整 / Update shortcut keys and operation guide according to development tools