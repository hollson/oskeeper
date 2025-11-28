# Typst 全流程使用指南

## 一、Typst 概述
Typst 是开源标记型排版系统，融合 LaTeX 功能与 Markdown 易用性，核心特性：
- 双模式设计：标记语法+编程能力

- 快速编译：比 LaTeX 快 10-20 倍，支持增量编译

- 跨平台：支持 Windows/macOS/Linux 及 Docker

- 学术友好：内置数学公式、参考文献等功能

- 高度定制：通过 `#show` 规则实现样式定制

  

<br/>



## 二、安装与配置

### 1. 快速安装
- **Windows**：
  ```powershell
  winget install --id Typst.Typst  # 或手动下载 releases
  ```

- **macOS**：
  
  ```bash
  brew install typst
  ```
  
- **Linux**：
  ```bash
  # Ubuntu/Debian
  sudo apt install typst
  
  # Arch Linux
  sudo pacman -S typst
  
  # 源码编译
  cargo install --locked typst-cli
  ```

### 2. 验证安装
```bash
typst --version  # 显示版本号如 typst 0.13.1
```

### 3. 中文字体配置
1. 下载思源宋体/黑体等开源字体
2. 安装字体：
   - Linux/macOS: `~/.fonts` 目录
   - Windows: `C:\Windows\Fonts` 目录
3. 文档中设置：
   ```typst
   #set text(font: "Source Han Serif CN")  // 正文字体
   #set heading(font: "Source Han Han Sans CN") // 标题字体
   ```



<br/>



## 三、基础语法

### 1. 文档结构
```typst
= 一级标题  // 等价于 \section
== 二级标题 // 等价于 \subsection

#let main-content = [  // 定义内容块
  正文段落支持*加粗*、_斜体_和`行内代码`。
  
  空行分段，缩进表示嵌套。
]
```

### 2. 数学公式
- 内联公式：`$E=mc^2$` → *E*=*m**c*²
- 块级公式：
  ```typst
  $$
  \nabla \cdot \mathbf{E} = \frac{\rho}{\epsilon_0} \\
  \nabla \cdot \mathbf{B} = 0
  $$
  ```

### 3. 列表与表格
- 无序列表：
  ```typst
  - 第一项
  - 第二项
    - 子项（缩进表示层级）
  ```

- 有序列表：
  ```typst
  + 第一项
  + 第二项
    + 子项
  ```

- 表格：
  ```typst
  #table(
    columns: 3,
    align: (center, left, right),
    [姓名, 年龄, 分数],
    [张三, 25, 92.5],
    [李四, 23, 88.0]
  )
  ```
  
  <br/>
  

## 四、VSCode 开发环境

### 1. 核心插件
1. **Typst LSP**：提供语法高亮、自动补全
   - 安装：VSCode 扩展商店搜索 `Typst LSP`

2. **Typst Preview**：实时预览
   - 安装：搜索 `Typst Preview`
   - 快捷键：`Ctrl+Shift+P` 输入 `Typst Preview: Toggle Preview`

3. 辅助插件：
   - Error Lens：行内错误提示
   - Bracket Pair Colorizer：括号高亮

### 2. 开发流程
1. 初始化项目：
   ```bash
   mkdir typst-project && cd typst-project
   code .  # 用 VSCode 打开
   ```

2. 创建并编辑 `main.typ`
3. 实时预览：`Ctrl+Shift+P` 启动预览
4. 导出 PDF：
   ```bash
   typst compile main.typ output.pdf
   ```
   
   
   
   <br/>
   
   

## 五、模板使用

### 1. 官方模板库
```typst
#import "https://github.com/typst/templates/academic-paper/main.typ": *
#show: academicPaper.with(
  title: "论文标题",
  authors: ("作者1", "作者2"),
  abstract: "摘要内容...",
  content: [正文内容]
)
```

### 2. 中文优化模板（EasyPaper）
1. 下载 `lib.typ` 至项目目录
2. 导入使用：
   ```typst
   #import "/lib.typ": *
   #show: project.with(
     title: "文档标题",
     author: "作者姓名",
     abstract: [摘要内容...],
     keywords: ("关键词1", "关键词2")
   )
   ```

### 3. 社区资源
- Typst Universe：[https://typst.app/community](https://typst.app/community)



<br/>




## 六、完整示例：学术论文
```typst
#set page(
  paper: "a4",
  margin: (top: 2.5cm, bottom: 2.5cm, left: 3cm, right: 3cm),
  numbering: "1."
)

#set heading(
  font: "Source Han Sans CN",
  numbering: (1: "1.", 2: "1.1.", 3: "1.1.1.")
)

#let paper(title, author, abstract, keywords, content) = [
  #place(top + center, float: true)[
    #text(24pt, weight: "bold")[#title]
    #v(0.5em)
    #author
    #v(1em)
    *摘要*：#abstract
    #v(0.5em)
    *关键词*：#keywords
  ]
  
  #content
  
  #place(bottom + right)[
    #page() / #pages()
  ]
]

#paper(
  title: "Typst 应用研究",
  author: "王五",
  abstract: "本文研究 Typst 排版应用...",
  keywords: "Typst, 排版",
  content: [
    = 引言
    量子计算作为下一代技术...
    
    = 方法
    ## 2.1 量子门符号
    $$
    H = \frac{1}{\sqrt{2}}\begin{pmatrix}1 & 1 \\ 1 & -1\end{pmatrix}
    $$
  ]
)
```

<br/>



## 七、进阶学习
1. 交互式练习：[官方 Web App](https://typst.app)
2. 函数编程：学习自定义函数与样式规则
3. 性能优化：使用 `typst watch` 增量编译
4. 社区支持：加入 Typst Discord 社区
