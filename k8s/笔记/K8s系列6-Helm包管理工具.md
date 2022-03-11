+++
title= "📒 K8s笔记六.  - Helm包管理工具"
url= "/posts/k8sea795d75f38c06/"
aliases = ["/posts/k8s006"]
description= "Kubernetes 是用于自动部署,扩展和管理容器化应用程序的开源系统。 它将组成应用程序的容器组合成逻辑单元,以便于管理和服务发现。"
image= "/img/res/blog.jpg"
date= 2020-06-28T10:12:31+08:00
lastmod= 2020-08-23T10:12:31+08:00
categories= ["K8s"]
tags= ["K8s"]
archives= "2020"
author= "史布斯"
height= 1587401551
draft= false

+++

## 前言

- - -
Helm是Kubernetes生态系统中的一个软件包管理工具。本文将介绍为何要使用Helm进行Kubernetes软件包管理，澄清Helm中使用到的相关概念，并通过一个具体的示例学习如何使用Helm打包，分发，安装，升级及回退Kubernetes应用。

## Kubernetes应用部署的挑战
- - -
让我们首先来看看Kubernetes，kubernetes提供了基于容器的应用集群管理，为容器化应用提供了部署运行、资源调度、服务发现和动态伸缩等一系列完整功能。

kubernetes的核心设计理念是: 用户定义应用程序的规格，而kubernetes则负责按照定义的规则部署并运行应用程序，如果应用系统出现问题导致偏离了定义的规格，kubernetes负责对其进行自动修正。例如应用规格要求部署两个实例，其中一个实例异常终止了，kubernetes会检查到并重新启动一个新的实例。

用户通过使用kubernetes API对象来描述应用程序规格，包括Pod，Service，Volume，Namespace，ReplicaSet，Deployment，Job等等。一般这些对象需要写入一系列的yaml文件中，然后通过kubernetes命令行工具kubectl进行部署。

以下面的wordpress应用程序为例，涉及到多个kubernetes API对象，这些kubernetes API对象分散在多个yaml文件中。

图1： Wordpress应用程序中涉及到的kubernetes API对象
![](https://img.zhaohuabing.com/in-post/2018-04-16-using-helm-to-deploy-to-kubernetes/wordpress.png)


可以看到，在进行kubernetes软件部署时，我们面临下述问题：
* 如何管理，编辑和更新这些这些分散的kubernetes应用配置文件？
* 如何把一套的相关配置文件作为一个应用进行管理？
* 如何分发和重用kubernetes的应用配置？

Helm的引入很好地解决上面这些问题。

## Helm是什么？
- - -
很多人都使用过Ubuntu下的ap-get或者CentOS下的yum, 这两者都是Linux系统下的包管理工具。采用apt-get/yum,应用开发者可以管理应用包之间的依赖关系，发布应用；用户则可以以简单的方式查找、安装、升级、卸载应用程序。

我们可以将Helm看作Kubernetes下的apt-get/yum。Helm是Deis (https://deis.com/) 开发的一个用于kubernetes的包管理器。

对于应用发布者而言，可以通过Helm打包应用，管理应用依赖关系，管理应用版本并发布应用到软件仓库。

对于使用者而言，使用Helm后不用需要了解Kubernetes的Yaml语法并编写应用部署文件，可以通过Helm下载并在kubernetes上安装需要的应用。

除此以外，Helm还提供了kubernetes上的软件部署，删除，升级，回滚应用的强大功能。

## Helm组件及相关术语
- - -
开始接触Helm时遇到的一个常见问题就是Helm中的一些概念和术语非常让人迷惑，我开始学习Helm就遇到这个问题。

因此我们先了解一下Helm的这些相关概念和术语。

* Helm   

  Kubernetes的应用打包工具，也是命令行工具的名称。
* Tiller 

  Helm的服务端，部署在Kubernetes集群中，用于处理Helm的相关命令。
* Chart 

  Helm的打包格式，内部包含了一组相关的kubernetes资源。
* Repoistory 
  
  Helm的软件仓库，repository本质上是一个web服务器，该服务器保存了chart软件包以供下载，并有提供一个该repository的chart包的清单文件以供查询。在使用时，Helm可以对接多个不同的Repository。
* Release 
  
  使用Helm install命令在Kubernetes集群中安装的Chart称为Release。

>  需要特别注意的是， Helm中提到的Release和我们通常概念中的版本有所不同，这里的Release可以理解为Helm使用Chart包部署的一个应用实例。
>  
>  其实Helm中的Release叫做Deployment更合适。估计因为Deployment这个概念已经被Kubernetes使用了，因此Helm才采用了Release这个术语。

下面这张图描述了Helm的几个关键组件Helm（客户端），Tiller（服务器），Repository（Chart软件仓库），Chart（软件包）之前的关系。

图2： Helm软件架构
![](https://img.zhaohuabing.com/in-post/2018-04-16-using-helm-to-deploy-to-kubernetes/helm-architecture.png)

## 安装Helm
- - -
下面我们通过一个完整的示例来介绍Helm的相关概念，并学习如何使用Helm打包，分发，安装，升级及回退kubernetes应用。

可以参考Helm的帮助文档https://docs.helm.sh/using_helm/#installing-helm 安装Helm

采用二进制的方式安装Helm

1. 下载 Helm https://github.com/kubernetes/helm/releases
1. 解压 tar -zxvf helm-v2.0.0-linux-amd64.tgz
1. 拷贝到bin目录 mv linux-amd64/helm /usr/local/bin/helm

然后使用下面的命令安装服务器端组件Tiller

```bash
Helm init
```

## 构建一个Helm chart
- - -

让我们在实践中来了解Helm。这里将使用一个Go测试小程序，让我们先为这个小程序创建一个Helm chart。

```
git clone https://github.com/zhaohuabing/testapi.git; 
cd testapi
```

首先创建一个chart的骨架
```
helm create testapi-chart
```

该命令创建一个testapi-chart目录，该目录结构如下所示，我们主要关注目录中的这三个文件即可: Chart.yaml，values.yaml 和 NOTES.txt。
```Bash
testapi-chart
├── charts
├── Chart.yaml
├── templates
│   ├── deployment.yaml
│   ├── _helpers.tpl
│   ├── NOTES.txt
│   └── service.yaml
└── values.yaml
```

* Chart.yaml 用于描述这个chart，包括名字，描述信息以及版本。
* values.yaml 用于存储templates目录中模板文件中用到的变量。 模板文件一般是Go模板。如果你需要了解更多关于Go模板的相关信息，可以查看Hugo (https://gohugo.io) 的一个关于Go模板的介绍 (https://gohugo.io/templates/go-templates/)。
* NOTES.txt 用于向部署该chart的用于介绍chart部署后的一些信息。例如介绍如何使用这个chart，列出缺省的设置等。

打开Chart.yaml, 填写你部署的应用的详细信息，以testapi为例：
```
apiVersion: v1
description: A simple api for testing and debugging
name: testapi-chart
version: 0.0.1
```
然后打开并根据需要编辑values.yaml。下面是testapi应用的values.yaml文件内容。

```
replicaCount: 2
image:
  repository: daemonza/testapi
  tag: latest
  pullPolicy: IfNotPresent
service:
  name: testapi
  type: ClusterIP
  externalPort: 80
  internalPort: 80
resources:
  limits:
    cpu: 100m
    memory: 128Mi
  requests:
    cpu: 100m
    memory: 128Mi
```

在 testapi_chart 目录下运行下面命令以对chart进行校验。

```
helm lint
==> Linting .
[INFO] Chart.yaml: icon is recommended

1 chart(s) linted, no failures
```

如果文件格式错误，可以根据提示进行修改；如果一切正常，可以使用下面的命令对chart进行打包：

```
helm package testapi-chart --debug
```

这里添加了 --debug 参数来查看打包的输出，输出应该类似于：

```
Saved /Users/daemonza/testapi/testapi-chart/testapi-chart-0.0.1.tgz to current directory
Saved /Users/daemonza/testapi/testapi-chart/testapi-chart-0.0.1.tgz to /Users/daemonza/.helm/repository/local
```

chart被打包为一个压缩包testapi-chart-0.0.1.tgz，该压缩包被放到了当前目录下，并同时被保存到了helm的本地缺省仓库目录中。

## Helm Repository
- - -
虽然我们已经打包了chart并发布到了helm的本地目录中，但通过Helm search命令查找，并不能找不到刚才生成的chart包。
```
helm search testapi
No results found
```

这是因为repository目录中的chart还没有被Helm管理。我们可以在本地启动一个Repository Server，并将其加入到Helm repo列表中。

通过helm repo list命令可以看到目前helm中只配置了一个名为stable的repo，该repo指向了google的一个服务器。
```Bash
helm repo list
NAME    URL
stable  https://kubernetes-charts.storage.googleapis.com
```

使用helm serve命令启动一个repo server，该server缺省使用'$HELM_HOME/repository/local'目录作为chart存储，并在8879端口上提供服务。

```Bash
helm serve&
Now serving you on 127.0.0.1:8879
```
启动本地repo server后，将其加入helm的repo列表。
```Bash
helm repo add local http://127.0.0.1:8879
"local" has been added to your repositories
```

现在再查找testapi chart包，就可以找到了。

```Bash
helm search testapi

NAME                    CHART VERSION   APP VERSION     DESCRIPTION
local/testapi-chart     0.0.1                           A Helm chart for Kubernetes
```

## 在kubernetes中部署Chart
- - -
chart被发布到仓储后，可以通过Helm instal命令部署chart，部署时指定chart名及Release（部署的实例）名：
```
 helm install local/testapi-chart --name testapi
```
该命令的输出应类似:

```
NAME:   testapi
LAST DEPLOYED: Mon Apr 16 10:21:44 2018
NAMESPACE: default
STATUS: DEPLOYED

RESOURCES:
==> v1/Service
NAME                   TYPE       CLUSTER-IP    EXTERNAL-IP  PORT(S)  AGE
testapi-testapi-chart  ClusterIP  10.43.121.84  <none>       80/TCP   0s

==> v1beta1/Deployment
NAME                   DESIRED  CURRENT  UP-TO-DATE  AVAILABLE  AGE
testapi-testapi-chart  1        1        1           0          0s

==> v1/Pod(related)
NAME                                   READY  STATUS   RESTARTS  AGE
testapi-testapi-chart-9897d9f8c-nn6wd  0/1    Pending  0         0s


NOTES:
1. Get the application URL by running these commands:
  export POD_NAME=$(kubectl get pods --namespace default -l "app=testapi-testapi-chart" -o jsonpath="{.items[0].metadata.name}")
  echo "Visit http://127.0.0.1:8080 to use your application"
  kubectl port-forward $POD_NAME 8080:80
```

使用下面的命令列出所有已部署的Release以及其对应的Chart。
```
helm ls
```

该命令的输出应类似:
```
NAME    REVISION        UPDATED                         STATUS          CHART                   NAMESPACE
testapi 1               Mon Apr 16 10:21:44 2018        DEPLOYED        testapi-chart-0.0.1     default
```

可以看到在输出中有一个Revision（更改历史）字段，该字段用于表示某一Release被更新的次数，可以用该特性对已部署的Release进行回滚。

## 升级和回退
- - -

修改Chart.yaml，将版本号从0.0.1 修改为 1.0.0, 然后使用Helm package命令打包并发布到本地仓库。

查看本地库中的Chart信息，可以看到在本地仓库中testapi-chart有两个版本

```Bash
helm search testapi -l
NAME                    CHART VERSION   APP VERSION     DESCRIPTION
local/testapi-chart     0.0.1                           A Helm chart for Kubernetes
local/testapi-chart     1.0.0                           A Helm chart for Kubernetes
```

现在用helm upgrade将已部署的testapi升级到新版本。可以通过参数指定需要升级的版本号，如果没有指定版本号，则缺省使用最新版本。

```
helm upgrade testapi local/testapi-chart 
```

已部署的testapi release被升级到1.0.0版本

```Bash
helm list
NAME    REVISION        UPDATED                         STATUS          CHART                   NAMESPACE
testapi 2               Mon Apr 16 10:43:10 2018        DEPLOYED        testapi-chart-1.0.0     default
```

可以通过Helm history查看一个Release的多次更改。

```Bash
helm history testapi
REVISION        UPDATED                         STATUS          CHART                   DESCRIPTION
1               Mon Apr 16 10:21:44 2018        SUPERSEDED      testapi-chart-0.0.1     Install complete
2               Mon Apr 16 10:43:10 2018        DEPLOYED        testapi-chart-1.0.0     Upgrade complete
```
如果更新后的程序由于某些原因运行有问题，我们则需要回退到旧版本的应用，可以采用下面的命令进行回退。其中的参数1是前面Helm history中查看到的Release的更改历史。

```Bash
helm rollback testapi 1
```

使用Helm list命令查看，部署的testapi的版本已经回退到0.0.1
```Bash
helm list
NAME    REVISION        UPDATED                         STATUS          CHART                   NAMESPACE
testapi 3               Mon Apr 16 10:48:20 2018        DEPLOYED        testapi-chart-0.0.1     default
```
## 总结
- - -

Helm作为kubernetes应用的包管理以及部署工具，提供了应用打包，发布，版本管理以及部署，升级，回退等功能。Helm以Chart软件包的形式简化Kubernetes的应用管理，提高了对用户的友好性。

## Q&A
- - -

昨天在Docker.io技术微信群里面进行了Helm的分享，下面是分享过程中得到的一些有意思的反馈，进一步启发了我自己的一些思考。

**Q**: Helm结合CD有什么好的建议吗？<BR>
**A**: 采用Helm可以把零散的Kubernetes应用配置文件作为一个chart管理，chart源码可以和源代码一起放到git库中管理。Helm还简了在CI/CD pipeline的软件部署流程。通过把chart参数化，可以在测试环境和生产环境可以采用不同的chart参数配置。

下图是采用了Helm的一个CI/CD流程
![](https://img.zhaohuabing.com/in-post/2018-04-16-using-helm-to-deploy-to-kubernetes/ci-cd-jenkins-helm-k8s.png)

**Q**: 感谢分享，请问下多环境(test,staging，production)的业务配置如何管理呢？通过heml打包configmap吗，比如配置文件更新，也要重新打chats包吗？谢谢，这块我比较乱<BR>
**A**：Chart是支持参数替换的，可以把业务配置相关的参数设置为模板变量。使用Helm install Chart的时候可以指定一个参数值文件，这样就可以把业务参数从Chart中剥离了。例子： helm install --values=myvals.yaml wordpress

**Q**: helm能解决服务依赖吗？<BR>
**A**：可以的，在chart可以通过requirements.yaml声明对其他chart的依赖关系。如下面声明表明chart依赖apache和mysql这两个第三方chart。
```yaml
dependencies:
  - name: apache
    version: 1.2.3
    repository: http://example.com/charts
  - name: mysql
    version: 3.2.1
    repository: http://another.example.com/charts
```

**Q**: chart的reversion 可以自定义吗？比如跟git的tag<BR>
**A**: 这位朋友应该是把chart的version和Release的reversion搞混了，呵呵。 Chart是没有reversion的，Chart部署的一个实例（Release）才有Reversion，Reversion是Release被更新后自动生成的。

**Q**: 没有看到helm指向k8s的配置，怎么确认在哪个K8s集群运行的？<BR>
**A**: 使用和kubectl相同的配置，在  ~/.kube/config 中。

**Q**: 这个简单例子并没有看出 Helm 相比 kubectl 有哪些优势，可以简要说一下吗？<BR>
**A**： Helm将kubernetes应用作为一个软件包整体管理，例如一个应用可能有前端服务器，后端服务器，数据库，这样会涉及多个Kubernetes 部署配置文件，Helm就整体管理了。另外Helm还提供了软件包版本，一键安装，升级，回退。Kubectl和Helm就好比你手工下载安装一个应用 和 使用apt-get 安装一个应用的区别。

**Q**: 如何在helm install 时指定命名空间？<BR>
**A**: helm install local/testapi-chart --name testapi --namespace mynamespace

## 参考
- - -

* [Using Helm to deploy to Kubernetes](https://daemonza.github.io/2017/02/20/using-helm-to-deploy-to-kubernetes/)
* [Helm documentation](https://docs.helm.sh/helm/)
* [Helm - Application deployment management for Kubernetes](https://www.slideshare.net/alexLM/helm-application-deployment-management-for-kubernetes)

