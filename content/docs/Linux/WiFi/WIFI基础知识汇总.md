---
date: '2024-01-20T10:14:21+08:00'
title:       'WIFI基础知识汇总'
description: ""
author:      "Donge"
image:       ""
tags:        ["WIFI技术", "WIFI基础知识", "无线网络知识", "WiFi开发详解"]
categories:  ["Tech" ]
weight: 1
---

# WIFI基础知识汇总

## 1. Wi-Fi起源

现在我们大家对`Wi-Fi`肯定都不陌生，无论是笔记本，手机，智能电视，都离不开`Wi-Fi`。现在我们一般用的都是`Wi-Fi5`,`Wi-Fi6`也正在快速普及。



在90年代，`IEEE`成立著名的`802.11`工作组，同时也定义了`802.11`的标准（`Wi-Fi`的核心技术标准）。最终形成了`IEEE802.11`标准版本：`802.11b` 工作于`2.4G`频段，`802.11a`工作于`5.8G`频段。



于此同时，intersil、3Com、诺基亚...六家公司，也成立了`WECA：Wireless Ethernet Compatibility Alliance`无线以太网相容性联盟，最终将该技术正式更名为了`Wi-Fi`，该组织也改名为`Wi-Fi联盟（Wi-Fi Alliance）`，并且`Wi-Fi联盟`不承认`wifi`、`WiFi`等其他字眼。



![image-20220319161123571](https://cdn.jsdelivr.net/gh/UNIONDONG/Get_Pic_Url/Media202203191611703.png)

## 2. Wi-Fi定义

`Wi-Fi`是`Wi-Fi联盟`制造商的商标做为产品的品牌认证，是一个基于`IEEE 802.11`标准的**无线局域网技术**。

无线网络上网可以简单的理解为无线上网，几乎所有智能手机、平板电脑和笔记本电脑都支持Wi-Fi上网，是当今使用最广的一种**无线网络传输技术**。

> 从宏观来说，也可以理解为`Wi-Fi=IEEE802.11标准`

&nbsp;

## 3. WLAN

`wlan：wireless local area network`，无线局域网络的全称，它利用射频技术`Radio Frequency； RF`，使用电磁波构成局域网络，在空中实现通信。 

该技术的出现绝不是用来取代有线局域网络，而是用来弥补有线局域网络之不足。

>  其实很多时候，人们将二者混用，其实**实现wlan的方式有很多，wifi只是实现方式之一**；

&nbsp;

## 4. 802.11协议标准

`802.11`：`802.11工作组`所制定的一种无线局域网标准。

`IEEE802`家族是由**一系列局域网络(`Local Area Network,LAN`)技术标准**所组成，`802.11`属于其中一员。

`WI-FI`使用了`802.11`的媒体访问控制层（MAC）和物理层（PHY），其内部也包含了不同的协议。



**IEEE802.11协议族成员如下**：

![img](https://cdn.jsdelivr.net/gh/UNIONDONG/Get_Pic_Url/Media202203160959460.png)

`802.11 a/b/g/n/ac`：都是由`802.11`发展而来。不同的后缀代表着**不同的物理层标准工作频段**和**不同的传输速率**，也就是说它们的物理层和传输速度不同。

`5.0GHz`和`2.4GHz`指的是无线路由器的工作频段。双频无线路由器是同时工作在`5.0GHz`和`2.4GHz`的模式下，而单频无线路由器只能工作在`2.4GHz`模式下。

![img](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/b28c0342998925041c5a8abac2959fa8.png)

1、`802.11b`和`802.11g`工作在同一频段上，g能够兼容b，也就是说支持g的网卡都能支持b。

2、`802.11n`协议为双频工作模式（包含2.4GHz和5GHz两个工作频段）。这样11n保障了与以往的802.11a b, g标准兼容。

3、新一代wifi标准`802.11 ac`是从`802.11 n`上发展而来的，有着比802.11 n更高的速度。现在市面是说的双频路由器即支持2.4G和5G的路由器。

4、`802.11n` 和`802.11ac`是WiFi的技术标准，就像手机3G网络一样，移动、联通、电信zhi都有自己不同的3G技术标准，WiFi也有不同的标准，，WiFi标准历经了`802.11a/g/b/n/ac`五代标准，其中`802.11n`是目前主流的应用，`802.11ac`是最新一代标准，也就是第五代标准。

> 由于802.11ac标准可以达到千兆的无线速度，所以已经大有取代802.11n标准的趋势，估计为了一两年内，大部分无线产品报告手机、笔记本、平板、无线路由器都采用802.11ac标准，



## 5. Wi-Fi所采用的技术



`Wi-Fi`使用的是**无线电波技术**，**无线电波是电磁辐射的一种**，而电磁辐射包括从伽玛射线到可见光到无线电波的种种。

![img](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/20170623101404773)

笔记本、平板电脑使用**无线适配器**将数据转换为**无线电波**，通过**天线**发送信号；这些信号**被无线路由器接收**，无线路由器**将无线电波转换为数据**形式，再将数据**转发到互联网**；同理，从互联网获取信息，即为上面流程的逆转。



## 6. Wi-Fi相关术语

&nbsp;

- **LAN**

`LAN（Local area network）`，局域网，路由和主机组成的内部局域网。

&nbsp;

- **WAN**

`WAN（Wide Area Network）`，广域网，可以看作更大的局域网。

&nbsp;

- **无线AP**

**无线AP**，即`Access Point`无线接入点，简单来说就是无线网络中的交换机，是移动终端用户进入有线网络的接入点。其主要功能有：

> - **中继**：作为中转站，放大信号
> - **桥接**：主要负责两个或者多个局域网的数据传输。
> - **主从模式**：作为客户端，连接无线局域网或者有线局域网。

&nbsp;

- **Station**

工作站`Station`，表示可以连接到无线网络中的设备。

&nbsp;

- **SSID**

用来标识一个无线网络，每个网络都有它的`SSID`，无线路由通过这个名字可以为其它设备标识这个无线路由的子网。

当想要扩大一个无线网络（即SSID固定）的范围的时候，可以给多个路由设置相同的SSID来达到这个目的。

&nbsp;

- **BSSID**

用来标识`BSS`，其格式和`MAC`地址一样，`48bit`的格式。一般来说，它是无线接入点的MAC地址。

&nbsp;

- **BSS**

`BSS（Basic Service Set）`，由一组相互通信的工作站组成，是`802.11`无线网络的基本组件。

主要有两种类型的IBSS和基础结构型网络。IBSS又叫ADHOC，组网是临时的，通信方式为`Station<->Station`，这里不关注这种组网方式；

我们关注的基础结构形网络，其通信方式是`Station<->AP<->Station`，也就是所有无线网络中的设备要想通信，都得经过AP。在无线网络的基础形网络中，最重要的两类设备：AP和Station。

&nbsp;

- **MAC**

MAC（`Medium/MediaAccess Control`, 介质访问控制），数据链路层的一部分。`MAC`地址烧录在网卡中，由`48bit`组成的。

&nbsp;

- **Band**

频率范围，一般ap可以支持5g或2.4g两个频率范围段的无线信号。

&nbsp;

- **Channel**

通道是对频段的进一步划分，处于不同传输信道上面的数据，如果信道覆盖范围没有重叠，那么不会相互干扰。

> 将5G或者2.4G的频段范围再划分为几个小的频段，每个频段称作一个Channel）

&nbsp;

- **Cnannel Width**

信道宽度，有`”20M HZ“、”40M HZ“`等，它表示一个Channel片段的宽度。

> 假设5g的频段宽度总共为100M，平均划分为互不干扰的10个Channel，那么每个Channel的Channel Width就为100M/10=10M，实际Channel并不一定是完全不重叠的

&nbsp;

- **Wireless Security**

无线网络安全性，主要涉及到：`WEP`、`WPA`、`WPA2`、`AES`等。

- **WPA**：`Wi-Fi Protected Access`，由`Wi-Fi联盟`制定的安全标准。`WPA2`位其第二个版本。
- **WEP**：`Wired Equivalent Privacy`，采用名为RC4的RSA加密技术。

&nbsp;

- **Qos**

无线网络中的QOS是质量保证，大致的意思是，传输数据的时候，考虑各种因素，以一定的优先级来保证传输的特定要求。

&nbsp;

- **RF Power**

发射功率，给定频段范围内，发射机通过天线对空间辐射的能量。

&nbsp;



## 7. 参考文章

1、https://www.luyouwang.net/4145.html

2、https://www.wi-fi.org/

3、https://www.anywlan.com/

4、https://baijiahao.baidu.com/s?id=1686107058840330503&wfr=spider&for=pc

5、https://www.ebyte.com/new-view-info.aspx?id=404

![img](https://cdn.jsdelivr.net/gh/UNIONDONG/Get_Pic_Url/Media202202271147055.png)



<center><b> <font color ="blue">欢迎关注【嵌入式艺术】，董哥原创！</font></b></center>
<div align=center><img src="https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/blog.png" alt="img" width = "60%" height ="10%"/>
</div>
