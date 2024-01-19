---
date: '2024-01-19T21:00:17+08:00'
title:       '【Bluetooth蓝牙开发】四、BLE协议之物理层浅析'
description: ""
author:      "Donge"
image:       ""
tags:        ["Bluetooth开发", "蓝牙开发教程", "Bluetooth开发详解"]
categories:  ["Tech" ]
weight: 4
---

# 【Bluetooth|蓝牙开发】四、BLE协议之物理层浅析

## 1、前言

上文，通过对蓝牙协议框架进行整体了解，其包含`BR/EDR((Basic Rate / Enhanced Data Rate))`、`AMP(Alternate MAC/PHYs)`、`LE(Low Energy)`三种技术，不同技术对应不同的协议栈，本专栏目前对于`BLE`技术进行详解！

==下面我们将`BLE`部分单独抽离出来，单独对其进行研究。==

&nbsp;

<font color = "red">**`BLE`的协议可分为`Bluetooth Application`和`Bluetooth Core`两大部分，而`Bluetooth Core`又包含`BLE Controller`和`BLE Host`两部分。**</font>

> 快把小本本拿起来，一定要记住！

![ble_stack](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/202206141522981.gif)

<font color = "blue">我们先从**Physical Layer**开始分析</font>

<img src="https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/202206141046098.gif" alt="img" style="zoom:10%;" />

## 2、Physical Channel

任何一个通信系统，首先要确定的就是通信介质（物理通道，`Physical Channel`），`BLE`也不例外。在`BLE`协议中，“通信介质”的定义是由`Physical Layer`负责。

`Physical Layer`是这样描述`BLE`的通信介质的：

- `BLE`属于无线通信，则其通信介质是一定频率范围下的频带资源`（Frequency Band）`
  
- `BLE`的市场定位是个体和民用，因此使用免费的`ISM`频段`（频率范围是2.400-2.4835 GHz）`
  
- 为了同时支持多个设备，将整个频带分为40份，每份的带宽为`2MHz`，称作`RF Channel`。
  

经过上面的定义之后，`BLE`的物理通道划分已经明了了！
$$
频点(f)=2402(MHz)+k*2(MHz),k=(0...39)
$$
每个`Channel`的带宽为`2MHz`，如下图：

![image-20220614155032530](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/202206141550572.png)

&nbsp;

## 3、Physical Channel的细分

上面我们已经知道了，物理层被划分为了40个赛道，由于传输数据量的不同，为了更加充分利用好物理资源，进一步对通道进行了划分！

<font color = "red">**40个`Physical Channel`物理通道分别划分为3个广播通道`advertising channel`，和37个`Data Channel`数据通道。**</font>

对于数据量少，发送不频繁，时延不敏感的场景，使用广播通道通信。

> 例如一个传感器节点（如温度传感器），需要定时（如1s）向处理中心发送传感器数据（如温度）。
>
> 针对这种场景，BLE的Link Layer采取了一种比较懒的处理方式----广播通信：

对于数据量大，发送频率高，时延较敏感的场景，使用数据通道。

> BLE为这种场景里面的通信双方建立单独的通道（data channel）。这就是连接（connection）的过程。

同时，为了增加信道容量，增大抗干扰能力，连接不会长期使用一个固定的`Physical Channel`，而是在多个通道（如37个）之间随机但有规律的切换，这就是`BLE的跳频（Hopping）技术`。



<font color = "purple">**对物理层的了解先止步于此，再往下面深入分析，意义不大。我们把重点放在BLE的`Link Layer`**</font>

&nbsp;



<center><b> <font color ="blue">欢迎关注【嵌入式艺术】，董哥原创！</font></b></center>
<div align=center><img src="https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/blog.png" alt="img" width = "60%" height ="10%"/>
</div>
