Kubernetes（简称k8s）一个开源的容器编排系统。

## 基本组件

1. **Master 组件**：
   - **API Server**：提供Kubernetes API，是集群的入口点。
   - **Scheduler**：负责将Pod调度到合适的Node上运行。
   - **Controller Manager**：运行各种控制器进程，确保集群的状态与期望的状态一致。
   - **etcd**：保存集群的配置数据和状态。
2. **Node 组件**：
   - **Kubelet**：是一个代理服务，在每个Node上运行，确保容器在Pod中运行(节点管理,pod管理,健康检查,资源监控)。
   - **Kube Proxy**：负责为Service提供网络代理和负载均衡功能，确保Pod之间的网络通信。
   - **Container Runtime**：如Docker，负责运行容器。




**Scheduler** 的主要职责是：
- 监听未调度的Pod（即那些还没有被分配到Node上的Pod）。
- 根据各种约束和资源需求，选择最合适的Node来运行这些Pod。
- 调度决策考虑了诸如资源需求、亲和性和反亲和性规则、数据局部性等因素。

**Controller Manager** 的主要职责是：

- 运行多种控制器进程，这些控制器负责确保集群的状态与用户定义的期望状态一致。
- 包括但不限于：
  - **Replication Controller**：确保指定数量的Pod副本在任何时候都处于运行状态。
  - **Deployment Controller**：管理Pod和ReplicaSet的声明式更新。
  - **StatefulSet Controller**：管理有状态应用的Pod。
  - **DaemonSet Controller**：确保每个Node上运行一个特定的Pod。
  - **Job Controller**：管理一次性任务的Pod。
  - **Namespace Controller**：管理Namespace的创建和删除。
  - **Endpoint Controller**：维护Service和Pod之间的Endpoint列表。
  
  

## 核心概念：

- **Node**：工作节点，可以是物理机或虚拟机，上面运行着Pod。
- **Pod**：Kubernetes中最小的部署单元，一个Pod可以包含一个或多个容器。
- **Label**：键值对，用于标识和选择一组对象，如Pod。
- **Replication Controller/ReplicaSet**：确保指定数量的Pod副本在任何时候都处于运行状态。
- **Deployment**：管理Pod和ReplicaSet的**声明式更新**。
- **Service**：定义一组Pod的逻辑集合和一个访问它们的策略。
- **Volume**：提供持久化存储，使数据在容器重启后仍然可用。
- **Namespace**：将集群资源划分成多个虚拟集群，便于**多租户**或**多环境**使用。









![](https://developer.qcloudimg.com/http-save/yehe-11033471/77c834f29bfb6c796667288fde6bfb44.png)

![](https://img-blog.csdnimg.cn/2021032417225914.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxXzQyODI4Mzkx,size_16,color_FFFFFF,t_70)

![](https://i-blog.csdnimg.cn/blog_migrate/297b65c080eb19a5d72246f219497e94.jpeg)







https://blog.csdn.net/IT_ZRS/article/details/126622431

https://blog.csdn.net/crazymakercircle/article/details/128671196



、
