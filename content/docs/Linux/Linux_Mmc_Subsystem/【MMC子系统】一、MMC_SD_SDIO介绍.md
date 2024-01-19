---
date: '2024-01-19T21:16:36+08:00'
title:       '【MMC子系统】一、MMC_SD_SDIO介绍'
description: ""
author:      "Donge"
image:       ""
tags:        ["MMC子系统", "MMC/SD/SDIO", "Linux驱动开发"]
categories:  ["Tech" ]
weight: 1
---

# 【MMC子系统】 一、MMC/SD/SDIO介绍

## 1、前言

该节学习`Linux Kernel`的`MMC`子系统，也称为块设备驱动，正如其名，与字符驱动相比，`MMC`子系统以块为单位进行操作。

同时，由于`MMC Card`、`SD Card`、`SDIO Card`等设备协议基本大同小异，所以在`Linux Kernel`中使用`MMC`子系统来统一管理！

&nbsp;

## 2、MMC/SD/SDIO介绍

上面我们了解到，`Linux Kernel`使用统一的子系统模型来管理`MMC`、`SD`、`SDIO`等设备，那么为什么要这样设计呢？

> 答案当然是：三者协议有一定的共通性。

&nbsp;

`MMC（MultiMediaCard）`多媒体卡设备，从本质上看，**它是一种用于固态非易失性存储的内存卡（memory card）规范，定义了诸如卡的形态、尺寸、容量、电气信号、和主机之间的通信协议等方方面面的内容。**

1997年，`MMC`规范正式发布，至今已经进化出了`SD`、`MicroSD`、`SDIO`、`EMMC`等多种不同的规范，虽然眼花缭乱，但是追其根源，都源于`MMC`规范，所以`Linux Kernel`可以将其统一管理！

![mmc_sd_sdio_history](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/95d6d6a51a757c21cdc3108e12d16d0320161225135202.gif)

> `MMC`：强调的是多媒体存储（MM：MultiMedia）
> 
> `SD`：强调的是安全数据（SD：Secure Digital）
> 
> `SDIO`：强调的是IO接口(IO：Input/Output)

&nbsp;

> 更多干货可见：[高级工程师聚集地](https://t.zsxq.com/0eUcTOhdO)，助力大家更上一层楼！

&nbsp;

## 3、总线接口

`MMC`、`SD`、`SDIO`其物理接口也十分相似，我们以`MMC`为例进行分析。

![Card Concept(eMMC)](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/4ca87abb20c96c2362ed22855c0fb89a20161225135205.gif)

我们的`MMC`卡如上图所示，内部我们不展开分析，直接将其作为一个完整的设备来分析。

其通过`CLK`、`CMD`、`DATA`等管脚与我们的`SOC`通信，两者之间当然少不了`Controller`了。

![mmc_sd_sdio_hw_block](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/fbcc70f4593e41a6f96a28c4667a9c3420161225135203.gif)

**把通信总线部分，拿出来看**：

![image-20240103073934443](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/image-20240103073934443.png)

> `CLK`：提供`SOC`和设备之间的通信时钟，常用的通信频率为`400KHz`（识卡）、`25MHz`，`50MHz`
> 
> `CMD`：提供`SOC`和设备之间的通信命令，标识不同的命令编号，类型多达50多种。
> 
> `DATA`：提供`SOC`和设备之间的数据通信，其通信总线有8根，可自定义设置，一般默认的是1-bit (默认)模式、4-bit模式和8-bit模式。当然数据线越多，传输越快嘛，但是处理起来也稍微繁琐。
> 
> 除了上面的一些管脚，当然还少不了`VCC`、`GND`等管脚喽，与其它外设不同的是，`MMC`类的设备，还会有一个检测引脚`DET`，用于检测是否存在卡设备（热插拔）。

&nbsp;

**好啦，上面我们对`MMC`、`SD`、`SDIO`进行简单了解，也知道了通信的常用方式与物理接口，当然其最核心在于通信的协议啦！由于协议过于复杂，我们放到后面了解。**

&nbsp;

## 4、参考文章

\[1\]：[http://www.wowotech.net/basic\_tech/mmc\_sd\_sdio\_intro.html](http://www.wowotech.net/basic_tech/mmc_sd_sdio_intro.html)

&nbsp;

<center><b> <font color ="blue">欢迎关注【嵌入式艺术】，董哥原创！</font></b></center>
<div align=center><img src="https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/blog.png" alt="img" width = "60%" height ="10%"/>
</div>
