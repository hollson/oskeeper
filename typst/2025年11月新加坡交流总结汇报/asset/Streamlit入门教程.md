# Streamlit教程

### **一、Streamlit 的核心特点**
**Streamlit 是一个开源的 Python 工具库，专为数据科学家和开发者设计，用于快速构建交互式数据应用和 Web 应用程序，无需具备前端开发经验。** 它通过简单的 Python 代码即可创建包含图表、表格、交互控件等元素的动态应用，特别适合数据可视化、机器学习模型展示和数据分析报告的场景。

1. **极简开发**：仅需 Python 代码，无需 HTML/CSS/JavaScript。
2. **实时更新**：代码修改后，浏览器页面自动刷新。
3. **丰富的组件**：支持图表（Plotly、Matplotlib）、表格、滑动条、下拉菜单等交互控件。
4. **数据持久化**：通过 `st.session_state` 保存用户输入状态。
5. **快速部署**：支持一键分享到 `share.streamlit.io` 或部署到服务器。

### **二、快速入门指南**

#### **1. 环境安装**

- **推荐使用 Conda 管理环境**：

  ```bash
  bash# 创建并激活新环境
  conda create -n streamlit_env python=3.9
  conda activate streamlit_env
  
  # 安装 Streamlit
  pip install streamlit
  ```

- **验证安装**：

  ```bash
  bash
  
  streamlit hello
  ```

  浏览器会自动打开一个示例应用，显示动态图表和交互控件。

#### **2. 创建第一个应用**

- **新建 Python 文件**（如 `app.py`），输入以下代码：

  ```python
  pythonimport streamlit as st
  import pandas as pd
  import numpy as np
  import plotly.express as px
  
  # 设置页面标题
  st.title("我的第一个 Streamlit 应用")
  st.markdown("这是一个使用 Plotly 绘制的动态图表示例。")
  
  # 生成随机数据
  df = pd.DataFrame({
      "x": np.random.randn(100),
      "y": np.random.randn(100),
      "类别": np.random.choice(["A", "B", "C"], 100)
  })
  
  # 添加交互控件
  category = st.selectbox("选择类别", ["A", "B", "C"])
  filtered_df = df[df["类别"] == category]
  
  # 绘制散点图
  fig = px.scatter(filtered_df, x="x", y="y", title=f"类别 {category} 的数据分布")
  st.plotly_chart(fig, use_container_width=True)
  
  # 显示数据表格
  st.subheader("原始数据")
  st.dataframe(df)
  ```

- **运行应用**：

  ```bash
  bash
  
  streamlit run app.py
  ```

  浏览器会打开应用，展示交互式图表和数据表格。

#### **3. 关键功能解析**

- 页面布局

  ：

  - `st.title()`：设置主标题。
  - `st.markdown()`：支持 Markdown 格式的文本。
  - `st.subheader()`：添加副标题。

- 数据展示

  ：

  - `st.dataframe()`：显示可滚动的 Pandas 数据框。
  - `st.plotly_chart()`：集成 Plotly 图表。
  - `st.table()`：显示静态表格。

- 交互控件

  ：

  - `st.selectbox()`：下拉选择框。
  - `st.slider()`：滑动条。
  - `st.checkbox()`：复选框。
  - `st.button()`：按钮。

- 数据持久化

  ：

  ```python
  pythonif "counter" not in st.session_state:
      st.session_state.counter = 0
  
  if st.button("点击增加"):
      st.session_state.counter += 1
  
  st.write("当前计数:", st.session_state.counter)
  ```

#### **4. 进阶功能**

- 多页面应用

  ：

  - 使用 `st.experimental_singleton` 和 `st.experimental_rerun` 管理页面状态。
  - 通过 `st.radio()` 实现页面导航。

- 部署到云端

  ：

  1. 注册 [Streamlit Community Cloud](https://share.streamlit.io/)。
  2. 将代码推送到 GitHub。
  3. 在 Streamlit 平台上关联仓库，一键部署。

### **三、完整操作示例**

#### **示例：交互式数据探索工具**

```python
pythonimport streamlit as st
import pandas as pd
import plotly.express as px

# 页面标题
st.title("数据探索工具")

# 上传 CSV 文件
uploaded_file = st.file_uploader("选择 CSV 文件", type=["csv"])
if uploaded_file is not None:
    df = pd.read_csv(uploaded_file)
    st.subheader("数据预览")
    st.dataframe(df.head())

    # 选择列名绘制图表
    selected_columns = st.multiselect("选择要绘制的列", df.columns)
    if len(selected_columns) > 0:
        fig = px.line(df, x=df.index, y=selected_columns, title="多列趋势图")
        st.plotly_chart(fig)
else:
    st.info("请上传 CSV 文件以开始分析。")
```

#### **运行步骤**：

1. 将代码保存为 `data_explorer.py`。

2. 执行命令：

   ```bash
   bash
   
   streamlit run data_explorer.py
   ```

3. 上传 CSV 文件后，应用会显示数据预览和交互式图表。

### **四、学习资源**

- **官方文档**：[Streamlit 文档](https://docs.streamlit.io/)
- **示例库**：[Streamlit Gallery](https://streamlit.io/gallery)
- **社区论坛**：[Streamlit Forum](https://discuss.streamlit.io/)