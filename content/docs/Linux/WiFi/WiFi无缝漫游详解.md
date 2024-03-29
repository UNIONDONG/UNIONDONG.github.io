---
date: '2024-01-20T10:23:36+08:00'
title:       'WiFi无缝漫游详解'
description: ""
author:      "Donge"
image:       ""
tags:        ["tag1", "tag2"]
categories:  ["Tech" ]
weight: 3
---

# WiFi无缝漫游详解

## 1、WLAN漫游简介

> **百度百科**：：当网络环境存在多个相同SSID的AP，且它们的覆盖范围的重合时，无线用户可以在整个WLAN覆盖区内移动，无线网卡能够自动发现附近信号强度最大的AP，并通过这个AP收发数据，保持不间断的网络连接，这就称为无线漫游。

**简单来说**：`WLAN`漫游是指`STA`在不同的`AP`覆盖范围之间移动，且保持用户业务不中断的行为。

- **AP**：也就是无线接入点，是一个无线网络的创建者，是**网络的中心节点**。一般家庭或办公室使用的无线路由器就一个AP。
- **STA**：每一个连接到无线网络中的**终端**(如笔记本电脑、PDA及其它可以联网的用户设备)都可称为一个站点。

> 如下图所示，`STA1`从`AP1`的覆盖范围移动到`AP2`的覆盖范围时保持业务不中断。

![img](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/1161761-20190808105029933-1487137636.png)

&nbsp;

## 2、WiFi漫游由来

当家庭面积超过一定面积后，为了保证全家范围的wifi网络覆盖，我们就需要引入2个以上的WiFi接入点了。在多个WiFi接入点下，为了优化网络使用体验，免去手动切换wifi接入的麻烦，就需要引入WiFi漫游。

&nbsp;

- **伪漫游**：

一般**最常见的伪漫游方法**就是将2个以上的wifi接入点的SSID名称及密码设置相同，虽然起到了一定的切换作用，不过用过的朋友都知道效果非常的不好，先不说能否自动切换的问题，就算切换成功了，也会造成IP地址的改变，游戏掉网、断连接是必须的！因此在多AP情况下就必须引入一个新的名词：**Wifi快速漫游**

&nbsp;

* * *

- **WiFi漫游**

上文提到的设置SSID名称及密码相同的方案是最低能的做法，稍微懂一点网络知识的朋友都不会采用的；

最次的方案也是要**保证DHCP服务器的统一，保证切换Wifi时候IP地址不变。**

更进一阶，引入AC控制器，利用AC+AP的组合形式实现wifi漫游。目前市面上主流的TPlink、爱快、Mesh等产品的方案多是如此。

其根本的原理是通过AC设定AP的RSSI阈值，将信号不稳定的设备T下线，迫使终端设备重新连接信号最强的AP，实现AP的自动切换。

> 实话实说这种方案对于绝大多数的用户是完全够用的，AP切换过程中网络中断时间一般在200ms-500ms左右，影响不大，确实优化了网络体验。对于网络要求不高的朋友推荐选择。不过在该方案下游戏会有一段明显的卡顿，但不会掉线。

- **WiFi快速漫游**

> 如果你是一个追求完美网络体验的朋友，而且想一次到位部署网络，不再折腾了，那么你就需要**Wifi快速漫游**了。上面介绍的第二种方案，虽然效果说得过去，但仍然无法保证切换过程尽可能的少丢包及进一步缩短网络中断时间。这个时候就必须引入**Wifi快速漫游**方案了，通过**Wifi快速漫游进一步缩短网络中断时间**，提高网络使用体验，真正实现游戏中不卡顿

&nbsp;

对于有AC控制器的Wifi网络系统中，漫游过程可以简单分为3个阶段：**漫游触发→选择新AP→重新认证**。这时候就需要802.11k/v/r协议登场了。

- 由于Wifi网络密码的存在，在重新认证阶段终端在切换AP的时候需要出示其缓存的密钥，AP检查密钥并进行四次握手，产生数据加密密钥，漫游完成。802.11r协议可以在以上基础上省略4次握手，进一步缩减了断网的时间。
- 802.11k能告诉终端，如何快速选择漫游AP。
- 802.11v能优化漫游触发。

**能够应用802.11k/v/r协议的Wifi漫游都可以称之为快速漫游**，不过这需要AP和终端都支持哦，实际上目前能够支持802.11k/v/r协议的终端并不多，苹果算是一个例外吧，新产品全都支持802.11k/v/r，所以Wifi快速漫游更适合使用苹果的土豪们

&nbsp;

**综上，WLAN漫游策略主要解决以下问题：**

- **避免漫游过程中的认证时间过长导致丢包甚至业务中断**：802.1x认证、Portal认证等认证过程报文交互次数和时间，大于WLAN连接过程，所以漫游需要避免重新认证授权及密钥协商过程。
- **保证用户授权信息不变**：用户的认证和授权信息，是用户访问网络的通行证，如果需要漫游后业务不中断，必须确保用户在AC上的认证和授权信息不变
- **保证用户IP地址不变**：应用层协议均以IP地址和TCP/UDP Session为用户业务承载，漫游后的用户必须能够保持原IP地址不变，对应的TCP/UDP Session才能不中断，应用层数据才能够保持正常转发

&nbsp;

## 3、漫游基础知识

**WLAN漫游的网络架构**

![img](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/1161761-20190808113243125-2091597894.png)

- **AC控制器**：可用来集中化控制和管理无线AP，是一个无线网络的核心，负责管理无线网络中的所有无线AP，对AP管理包括：下发配置、修改相关配置参数、射频智能管理、接入安全控制等。
- **漫游组**：在WLAN网络中，可以对不同的AC进行分组，**STA可以在同一个组的AC间进行漫游**，这个组就叫漫游组。如图，AC1和AC2组成一个漫游组。
- **AC间隧道**：为了支持AC间漫游，漫游组内的所有AC需要同步每个AC管理的STA和AP设备信息，因此在AC间建立一条隧道作为数据同步和报文转发的通道。
- **Master Controller**：STA在同一个漫游组内的AC间进行漫游，需要漫游组内的AC能够试别组内其他AC。通过选定一个AC作为Master Controller，在该AC上维护漫游组成员表，并下发到漫游组内AC，使各AC之间相互试别并建立AC间隧道，如图，选的AC1作为Master Controller.
  - Master Controller既可以是漫游组外的AC，也可以在漫游组内选择一个AC
  - Master Controlle管理其他AC的同时，不能被其他Master Controlle管理
- AC内漫游：如果漫游过程中关联的是同一个AC，则是AC内漫游，如图STA从AP1漫游到AP2即是AC内漫游
- AC间漫游：如果漫游过程中关联的不是同一个AC，则是AC间漫游，如图STA在从Ap1漫游到AP3的过程即为AC间漫游
- HAC （Home AC）：STA首次与漫游组内某个AC进行关联，则该AC为它的HAC
- HAP （Home AP）：STA首次与漫游组内某个AP进行关联，则该AP为它的HAP
- FAC（Foreign AC）：STA漫游后关联的AC即为它的FAC
- FAP（Foreign AP）：STA漫游后关联的AP即为它的FAP

&nbsp;

## 4、漫游的分类

漫游根据实际的架构我们将它分为两类：**有缝漫游和无缝漫游**。无缝漫游又可以分为**二层漫游和三层漫游**。

- **有缝漫游**：有两种情况

  - 所有网络部署的AP是胖AP，没有AC。
  - 所有网络部署的AP是瘦AP，没有AC也可以工作。

  > 胖瘦AP的区别：https://zhuanlan.zhihu.com/p/64648479

  > 上面两种情况，主要是我们国情产生的，客户不停的压价还要一大堆需要。大家为了降低成本，没有部署AC。只需要SSID、加密配置和信道岔开即可。实际效果第中远好于第一种，因为第二种是在一个DHCP下，第一种就相当安装了很多的家用路由器，问题多多!

- **无缝漫游**：

  > 无缝漫游能够做到的是在 AP 与 AP间的切换时间控制在毫秒级，基本不掉包，在业务运用上感受不到有任何停顿，这样客户终端在移动时从一个 AP 快速自由地切换到另一个 AP， 这就是无缝漫游。

  - 二层漫游：同一AC下的快速漫游，AP与AC直连组网，AP和AC连接在同一个VLAN内，可以实现二层漫游。
  - 三层漫游：跨VLAN的三层漫游，当网络规模比较大，VLAN不一样，IP网段也不相同，因为支持三层无缝漫游，从而保证用户在不一样VLAN间漫游而业务不中断。

&nbsp;

### 4.1 二层漫游

![img](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/1161761-20190808142355162-1745291625.png)

&nbsp;

二层漫游后，STA仍然在原来的子网中，FAP/FAC对二层漫游用户的报文转发同普通新上线用户没有区别，直接在FAP/FAC本地网络转发，**不需要通过AC间隧道转回到HAP中转**

**漫游前**：

1.  STA发送业务报文到HAP
2.  HAP接收到STA发送的业务报文并发送给HAC
3.  HAC直接将业务报文发送给上层网络

**漫游后**：

1.  STA发送业务报文给FAP
2.  FAP接收到STA的业务报文，并发送给FAC
3.  FAC直接将业务报文发送给上层网络

&nbsp;

### 4.2 三层漫游

#### 4.2.1 三层漫游--隧道转发模式

![img](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/1161761-20190808145416275-1215514956.png)

三层漫游时，用户漫游前后不在同一个子网中，为了支持用户漫游后仍能正常访问漫游前网络，**需要将用户流量通过隧道转发到原来的子网中转**。

隧道转发模式下，HAP和HAC之间业务报文通过CAPWAP隧道封装，此时可以将HAP和HAC看作在同一个子网内，报文无需返回到HAP，直接通过HAC中转到上层网络

**漫游前**：

1.  STA发送业务报文到HAP
2.  HAP接收到STA发送的业务报文并发送给HAC
3.  HAC直接将业务报文发送给上层网络

**漫游后**：

1.  STA发送业务报文给FAP
2.  FAP接收到STA的业务报文，并发送给FAC
3.  FAC通过HAC和FAC之间的AC间隧道将业务报文转发给HAC
4.  HAC直接将业务报文转发给上层网络

#### 4.2.2 三层漫游--直接转发模式

![img](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/1161761-20190808152709359-1091210242.png)

直接转发模式下，HAP和HAC之间的业务报文不通过CAPWAP隧道封装，无法判定HAP和HAC是否在同一个子网内，此时设备默认报文需要返回到HAP进行中转。如果HAP和HAC在同一个子网时，可以将家乡代理设置为性能更强的HAC，减少HAP的负荷并提高转发效率

用户漫游到其他AP后，默认以HAP作为家乡代理。用户漫游时，自动在FAP和家乡代理间建立一条隧道，用户的流量通过家乡代理中转，以保证用户漫游仍能访问原网络

**漫游前**：

1.  STA发送业务报文到HAP
2.  HAP接收到STA发送的业务报文并发送给HAC
3.  HAC直接将业务报文发送给上层网络

**漫游后**：

1.  STA发送业务报文给FAP
2.  FAP接收到STA发送的业务报文，并发送给FAC
3.  FAC通过HAC和FAC之间的隧道，将业务报文转发给HAC
4.  HAC将业务报文发送给HAP
5.  HAP直接将业务报文发送给上层网络

**设置AC为家乡代理**：

1.  STA发送业务报文给FAP
2.  FAP接收到STA发送的业务报文并发送给FAC
3.  FAC通过HAC和FAC之间的隧道，将业务报文转发给HAC
4.  HAC将业务报文发送给上层网络

&nbsp;

## 5、漫游基本原理

1.  **切换检测**：当STA检测到要发生快速切换时，将向各信道发送切换请求。

> STA监听各信道beacon，发现新AP满足漫游条件，向新AP发送probe请求。新AP在其信道中收到请求后，通过在信道中发送应答来进行响应。STA收到应答后，对其进行评估，确定同哪个AP关联最合适。

![img](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/1161761-20190808111837035-725221065.png)

2.  **切换触发**：STA达到漫游阈值就会触发切换，对于触发条件，不同的STA会有不同的方式：

    - 根据当前AP和邻近AP**信号强度的对比**，达到门限值就启动切换

    - 根据业务，例如**丢包率**，达到门限值就启动切换，此切换触发方式较慢，效果差

![img](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/1161761-20190808112410457-1267483510.png)

3.  **切换操作**：关联新AP，解除与老AP的关联

> 不同的STA会有不同的操作方式，一般情况，STA在发送切换请求后，发送关联新AP的请求，待请求被接受后，再关联新的AP，然后解除与老AP的关联。但有的STA也会先解除与老AP的关联，再关联新AP

![img](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/1161761-20190808112728830-1243620432.png)

&nbsp;

## 6、切换方式

终端的漫游如何实现？**有主动切换和被动切换两种方式**。

### 6.1 主动切换

终端检测到有更强的beacon帧信号，而且SSID与当前接入的SSID相同，主动发送probe request帧，探测具有相同SSID的AP，并从中选择更优的进行接入。通过wireshark抓包，可以看到这个过程如下：  
![在这里插入图片描述](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/20210623203845439.png)

### 6.2 被动切换

AP通过ACTION帧发送BSS Transition Management Request消息，提供可切换的候选AP，终端用BSS Transition Management Response消息回应结果，然后是与主动切换类似的步骤。  
![在这里插入图片描述](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/20210623203924471.png)

终端在接收到BTM Request后，使用probe request检测候选AP是否可达，然后通过BTM response返回结果。

&nbsp;

## 7、漫游基本配置

![img](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/d85f962bd40735fa2ffbd8ae9d510fb30f240861.jpg)

要做到漫游，我们的路由器需要一些基本的配置：

- **无线AP必须设置为相同的SSID**。不同的SSID意味着不同的无线网络，而无法实现无线漫游。需要注意的是，SSID区分大小写。

- **所有无线AP必须使用同一网段的IP地址**，并且处于同一[VLAN](https://info.support.huawei.com/info-finder/encyclopedia/zh/VLAN.html)中。

- **信号相互覆盖的无线AP不能使用相同的频道**。

  > 由于多个AP信号覆盖区域相互交叉重叠，因此，各个AP覆盖区域所占频道之间必须遵守一定的规范，邻近的相同频道之间不能相互覆盖，也就是说，相互覆盖区域的无线AP不能采用同一频道，否则，会造成AP在信号传输时的相互干扰，从而降低AP的工作效率。
  >
  > 在可用的11个频道中，仅有3个频道是完全不覆盖的，他们分别是频道1、频道6和频道11，利用这些频道作为多蜂窝覆盖是最合适的。另外，用于实现无线漫游网络的无线AP必须使用同一网络名称（SSID），使用同一网段的IP地址，否则，无线客户端将无法实现漫游功能。
  >
  > 无线漫游网络中，客户端的配置与接入点网络中的配置完全相同。用户在移动过程中，根本感觉不到无线AP间进行切换。

  ![image-20220913153218889](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/image-20220913153218889.png)

  **通过`wirelessMon`工具，可以查看不同信道的占用情况！**

- **AP信号覆盖区域应当相互交叉重叠**，否则，会导致无线网络盲区。也就是说，无线AP之间的距离，应当小于无线AP的有限传输距离。 相互覆盖的无线AP必须采用不同的、甚至是不相邻频道，否则，将导致严重干扰，降低AP通信效率。

- **必须采用相同的WEP或WPA加密**。所有无线AP和客户端必须采用相同的WEP或WPA加密，否则，将无法建立彼此之间的连接。WEP和WPA也是区分大小写的。

- **将三个无线路由器SSID、加密方式、密钥设置成相同的。实现无缝漫游**。

- **`DHCPC`服务要一致，确保分配到的`IP`地址不变**

&nbsp;

## 8、参考文章

\[1\]：https://post.smzdm.com/p/a83dz8vn/

\[2\]：https://product.pconline.com.cn/itbk/wlbg/network/1802/10851726.html

\[3\]：https://www.cnblogs.com/juankai/p/11320325.html

\[4\]：https://blog.csdn.net/yihuliunian/article/details/106903521

&nbsp;

<center><b> <font color ="blue">欢迎关注【嵌入式艺术】，董哥原创！</font></b></center>
<div align=center><img src="https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/blog.png" alt="img" width = "60%" height ="10%"/>
</div>
