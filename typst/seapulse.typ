// mastermap.typ
#import "templates/template.typ": project, title-page, contents-page, section-page, with-page-numbering, acias-table, kbd

#show: project

#title-page(
  title: [SeaPulse Project / MasterMap 项目],
  subtitle: [Project Documentation / 项目文档],
  author: [Feng Yu / 冯宇],
  date: [November 2025 / 2025年11月],
  version: [Version 1.0 / 版本 1.0]
)

#contents-page("Table of Contents / 目录")

#show: with-page-numbering

= Project Overview / 项目概述

SeaPulse is a mapping platform specialized in geospatial data visualization and analysis, with its core positioned to deliver intuitive spatial insight and efficient data-driven decision support.  
SeaPulse 是一款专注于地理空间数据可视化与分析的地图平台，其核心定位是提供直观的空间洞察与高效的数据决策支持。

*Key Features / 核心功能*：

- Real-time data visualization on interactive maps  
  交互式地图上的实时数据可视化
- Layer management and toggling  
  图层管理与切换
- Route planning and analysis tools  
  路线规划与分析工具
- Integration with multiple data sources (GNSS, WiFi, UWB, AIS)  
  多数据源集成（GNSS、WiFi、UWB、AIS）

= System Architecture / 系统架构

The architecture consists of frontend, backend, and data processing layers.  
架构由前端、后端和数据处理层组成。

- Frontend: React + Cesium for 3D visualization  
  前端：React + Cesium 用于 3D 可视化


= Components / 组件说明

- Map Components / 地图组件
  - Map Viewer / 地图查看器
  - Layer Panel / 图层面板
  - Search and Filter / 搜索与筛选
- UI Components / UI 组件
  - Info Panels / 信息面板
  - Toolbars / 工具栏


= Development Plan / 开发计划

- Phase 1: Map Viewer Implementation / 地图查看器实现  
- Phase 2: Layer Management / 图层管理  
- Phase 3: Search and Filter / 搜索与筛选  
- Phase 4: Info Panels and Toolbars / 信息面板与工具栏  
- Phase 5: Testing & Deployment / 测试与部署
