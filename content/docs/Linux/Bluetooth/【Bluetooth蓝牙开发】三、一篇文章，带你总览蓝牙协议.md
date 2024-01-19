---
date: '2024-01-19T21:00:08+08:00'
title:       '【Bluetooth蓝牙开发】三、一篇文章，带你总览蓝牙协议'
description: ""
author:      "Donge"
image:       ""
tags:        ["Bluetooth开发", "蓝牙开发教程", "Bluetooth开发详解"]
categories:  ["Tech" ]
weight: 3
---

# 【Bluetooth|蓝牙开发】三、一篇文章，带你总览蓝牙协议

## 1、前言

在我们上一章节，学习了蓝牙的基础概念，发展历程，以及常见的蓝牙架构，相信大家对蓝牙也有了一定的了解！

为了更好的去踏入蓝牙开发的大门，蓝牙协议栈是一个我们不得不去跨越的门槛！

![](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/image-20220930070002304.png)

> 蓝牙协议及其复杂，并非一文能够道尽，本篇文章主要在于对蓝牙整体的协议架构进行梳理，<span style="color: red;">**文末官方协议附下载链接。**</span>

&nbsp;

## 2、蓝牙芯片架构

蓝牙的核心架构，由一个`Host`和一个或多个`Controller`组成。

- `BT Host`：一个逻辑实体，在`HCI（Host Controller Interface）`的上层。
- `BT Controller`：一个逻辑实体，在`HCI（Host Controller Interface）`的下层。

![image-20220927085245742](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/image-20220927085245742.png)

`Bluetooth`的主控制器，可能是以下几种：

- `BR/EDR Controller`：内部包含`Radio`, `Baseband`，`Link Manager`，`可选的HCI`。
- `LE Controller` ：内部包含`LE PHY`，`Link Layer` ，`可选的HCI`
- `BR/EDR & LE Controller` ：BR/EDR与LE的组合的控制器
- `MAC/PHY (AMP) Controller`：二级控制器，可替代的，内部包含 `802.11 PAL (Protocol Adaptation Layer)`，`802.11 MAC`，`PHY`，`可选的HCI`。

![image-20220927085439947](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/image-20220927085439947.png)

&nbsp;

根据`Host`与`Controller`的组成关系，常见的蓝牙芯片也分为以下几种架构：

- **单模蓝牙芯片**：单一传统蓝牙的芯片，单一低功耗蓝牙的芯片。即（1个`Host`结合1个`Controller`）
- **双模蓝牙芯片**：同时支持传统蓝牙和低功耗蓝牙的芯片。即（1个`Host`结合多个`Controller`）

<font color = "blue">**如下图**：</font>

![image-20220607200203023](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/202206072002059.png)

&nbsp;

## 3、蓝牙协议架构——视角1

![image-20220607201228994](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/202206072012045.png)

==**上图为官方协议中所提及的图片，由全局到局部来看**==

### 3.1 全局分析

> **由下到上分析**

**Controller**：

- **BR/EDR Controller**：由`BR/EDR Radio`、`Link Controller`、`Link Manager`组成
- **LE Controller**：由 `LE Radio` 、`Link Controller`、`Link Manager`组成
- **AMP Controller**：由, `AMP PHY` 、`AMP MAC`, 、`AMP PAL`组成

**Host**：

- **BR/EDR Host**：由 `L2CAP`、`SDP` 、`GAP` 组成
- **LE Host**：由 `L2CAP`、`SMP` 、`GAP` 、`Attribute protocol`、`GATT`组成

&nbsp;

### 5.3.2 局部分析

> **由上到下分析**

#### Host层

- **Channel Manager**：通道管理，主要用于创建、管理、关闭`L2CAP`通道，用于服务协议和应用数据的传输。
- **L2CAP Resource Manage**：`L2CAP`资源管理，主要负责管理分片的`PDU`的正确提交。
- **Security Manager Protocol**：`SMP`安全管理协议，主要负责生成加密密钥和身份密钥。
- **Attribute Protocol**：`ATT`，属性协议，主要负责服务端与客户端点到点的数据传输。
- **AMP Manager Protocol**：直接使用`L2CAP`与远程设备通信。
- **Generic Attribute Profile**：`GATT`，提供更多的功能，概要文件描述了属性服务器中使用的服务层次结构、特征和属性，用于`LE`设备
- **Generic Access Profile**：`GAP`，标识了基础的蓝牙设备的通用功能

![image-20220614110304885](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/202206141103919.png)

#### Controller层

- **Device Manager**：控制蓝牙设备的通用行为，负责与蓝牙通信过程中，所有的与数据无关的操作，如查询设备，连接设备
- **Link Manager**：链路管理，主要负责创建，修改，释放逻辑链路。
- **Baseband Resource Manager**：基带资源管理，主要负责所有的访问无线电媒体
- **Link Controller**：链路控制，主要负责从编码和解码蓝牙数据包
- **PHY**：物理层，主要负责发送，接收物理通道的信息包

以上为官方手册提供的视图，`Host`通过`HCI（Host Controll Interface）`接口，来控制`Controller`执行相应的动作。

&nbsp;

## 4、蓝牙协议架构——视角2

<span style="color: blue;">下面是参考网上的一位博主的文章，写的较为详细，遂分享出来。</span>

![img](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/202206071935280.png)

以上架构图，将蓝牙协议分为了`HW`层，`Transport`层，`Host`层。

&nbsp;

### 4.1 HW层——蓝牙芯片层

`HW`层，指的是蓝牙芯片层，也就是我们上面说的`Controller`，包括以下几个部分：

- **RF（RADIO）**：射频层，本地蓝牙数据通过射频发送给远端设备，并且通过射频接收来自远端蓝牙设备的数据。
  
- **BB（BASEBAND）**：基带层，进行射频信号与数字或语音信号的相互转化，实现基带协议和其它的底层连接规程。
  
- **LMP（LINK MANAGER PROTOCOL）**：链路管理层，负责管理蓝牙设备之间的通信，实现链路的建立、验证、链路配置等操作
  
- **HCI（HOST CONTROLLER INTERFACE）**：主机控制器接口层，HCI层在芯片以及协议栈都有，芯片层面的HCI负责把协议栈的数据做处理，转换为芯片内部动作，并且接收到远端的数据，通过HCI上报给协议栈。
  
- **BLE PHY**：BLE的物理层，通信通道的划分。
  
- **BLE LL**：BLE的链路层，对通信通道的复用以及逻辑划分。

&nbsp;

### 4.2 Transport——数据传输层

`Transport`层，主机控制层接口，通过硬件接口`UART/USB/SDIO`把`HOST`协议层的数据发送给`Controller`层，并且接收`Controller`层的数据。

<span style="color: blue;">**该部分有几个协议**</span>：

- **H2**：基于USB的传输
- **H4**：基于UART的传输，最简单的传输方式，只在`HCI raw data`前面加上一个`type`，基于流控
- **H5**: 基于UART的传输，普通模式下即可传输。
- **BCSP**: 基于UART的传输
- **SDIO** ：基于SDIO的传输

<span style="color: blue;">**H4需要蓝牙芯片的UART\_TX/UART\_RX/UART\_CTS/UART\_RTS/VCC/GND接到MCU；而H5只需要蓝牙芯片的UART\_TX/UART\_RX/VCC/GND接到MCU就可以通信。**</span>

&nbsp;

### 4.3 HOST——协议层

`HOST`层，此部分就是蓝牙协议栈，该部分包括多个协议：

- <span style="color: red;">**L2CAP（Logical Link Control and Adaptation Protocol）**</span>：逻辑链路控制与适配协议，将ACL数据分组，对高层应用的数据进行分组，并提供协议复用和服务质量交换等功能。通过协议多路复用、分段重组操作和组概念,向高层提供面向连接的和无连接的数据服务

![img](https://img-blog.csdnimg.cn/20200721140939708.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L1hpYW9YaWFvUGVuZ0Jv,size_16,color_FFFFFF,t_70)

- **SDP（SERVICE DISCOVERY PROTOCOL）**：服务发现协议，为应用程序提供发现可用服务，并确定服务特征的方法。

![img](https://img-blog.csdnimg.cn/20200721141113409.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L1hpYW9YaWFvUGVuZ0Jv,size_16,color_FFFFFF,t_70)

- **RFCOMM（Serial Port Emulation）**：串口仿真协议，上层协议蓝牙电话，蓝牙透传SPP等协议都是直接走的RFCOMM
  
- **OBEX**：对象交换协议，蓝牙电话本，蓝牙短信，文件传输等协议都是走的OBEX
  
- **HFP（Hands-Free）**：蓝牙免提协议
  
- **HSP**：蓝牙耳机协议，最开始的蓝牙耳机协议，目前已经没有产品在用这个了吧，至少我没有看到了。算是一个简化版的HFP。
  
- **SPP（SERIAL PORT PROFILE）**：蓝牙串口协议
  
- **IAP**：苹果的特有协议，分为IAP1/IAP2，一般做Carplay或者iPod功能的人肯定接触过这块，有需要这块的私下联系我
  
- **PBAP（Phone Book Access）**：蓝牙电话本访问协议
  
- **MAP（MESSAGE ACCESS PROFILE）**：蓝牙短信访问协议
  
- **HID（HUMAN INTERFACE DEVICE）**：人机接口协议，HID还是有很多广泛的用途的，比如蓝牙鼠标，蓝牙键盘，蓝牙自拍杆，蓝牙手柄等。
  
- **A2DP（Advanced Audio Distribution）**: 蓝牙音乐协议
  
- **SM**: 蓝牙BLE安全管理协议
  
- <span style="color: red;">**GAP（GENERIC ACCESS PROFILE）**</span>：它定义了蓝牙设备的基本要求。
  
    - 对于`BR/EDR`，它定义了一个蓝牙设备，包括无线电、基带、链路管理器、L2CAP和服务发现协议功能。
    - 对于`LE`，它定义一个物理层，链路层，L2CAP，安全管理器，属性协议和通用属性配置文件。
    
    它联系了所有的不同的层之间的交互，也描述了设备发现、建立连接、安全、认证、关联模型和发现服务的行为和方法。
    

![image-20220614100912745](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/202206141009790.png)

- <span style="color: red;">**ATT（Attribute Protocol）**</span>：蓝牙属性协议,用于发现、读、写对端设备的协议(针对BLE设备),ATT允许设备作为服务端提供拥有关联值的属性集 ，让作为客户端的设备来发现、读、写这些属性；同时服务端能主动通知客户端。
- <span style="color: red;">**GATT（Generic Attribute Profile）**</span>：蓝牙通用属性协议，描述了一种使用ATT的服务框架 ，该框架定义了数据交换的格式。

![image-20220614101640726](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/202206141016771.png)

&nbsp;

## 5、总结时刻

**蓝牙芯片的架构**：根据`Host`与`Controller`的结合关系，可以分为单模芯片和双模芯片。

**蓝牙协议的架构**：蓝牙协议分为三层，即：Host层，Transport层，Controller层。每一层又由多种不同的协议组成。

本篇文章先进行初步了解，后续会逐步深入讲解！

&nbsp;

## 6、参考文章&下载地址

\[1\]：[参考文章](https://blog.csdn.net/XiaoXiaoPengBo/article/details/107466841)

\[2\]：[蓝牙协议下载地址](https://www.dongni.work/archives/resourceall)

&nbsp;


<center><b> <font color ="blue">欢迎关注【嵌入式艺术】，董哥原创！</font></b></center>
<div align=center><img src="https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/blog.png" alt="img" width = "60%" height ="10%"/>
</div>
