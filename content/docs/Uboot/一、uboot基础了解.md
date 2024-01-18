---
date: '2023-11-17T20:50:32+08:00'
title:       '一、uboot基础了解'
description: "U-Boot，全称 Universal Boot Loader，是遵循GPL条款的从FADSROM、8xxROM、PPCBOOT逐步发展演化而来的 开放源码项目。U-boot，是一个主要用于嵌入式系统的引导加载程序，可以支持多种不同的计算机系统结构，其主要作用为：==引导系统的启动！==目前，U-Boot不仅支持Linux系统的引导，还支持NetBSD, VxWorks, QNX, RTEMS, ARTOS, LynxOS, android等多种嵌入式操作系统!"
author:      "Donge"
image:       "img/post-bg-halting.jpg"
published: true
tags: 
    - Uboot开发详解
categories:  ["Tech"]
weight: 1
---


# 一、uboot基础了解

![在这里插入图片描述](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/974ad967a6b74a27888c66746ba1d04a.png)


## 1\. U-boot是什么

`U-Boot`，全称 `Universal Boot Loader`，是遵循GPL条款的从FADSROM、8xxROM、PPCBOOT逐步发展演化而来的 **开放源码项目**。

`U-boot`，是一个主要用于嵌入式系统的引导加载程序，可以支持多种不同的计算机系统结构，其主要作用为：==**引导系统的启动！**==目前，U-Boot不仅支持Linux系统的引导，还支持NetBSD, VxWorks, QNX, RTEMS, ARTOS, LynxOS, android等多种嵌入式操作系统。

## 2\. U-boot主要特性及功能

- **开放**：开放的源代码
- **多平台**：支持多种嵌入式操作系统，如Linux、NetBSD、android等
- **生态**：有丰富的设备驱动源码，如以太网、SDRAM、LCD等，同时也具有丰富的开发文档。

## 3\. U-boot下载地址

**Uboot开发源码：**

- https://source.denx.de/u-boot/u-boot

- https://ftp.denx.de/pub/u-boot/

**其他厂商定制的uboot源码：**

- [野火](https://github.com/Embedfire/ebf_products/tree/master/documentation)

## 4\. U-boot目录结构

| 目录             | 含义                                                         |
| ---------------- | ------------------------------------------------------------ |
| arch             | 各个厂商的硬件信息，目录下包括支持的处理器类型               |
| arch/arm/cpu/xxx | **每一个子文件夹，包含一种cpu系列。**每个子文件夹下包含cpu.c（CPU初始化），interrupts.c（设置中断和异常），start.S（U-boot的启动文件，早期的初始化）。 |
| board            | 与开发板有关，**每一个子文件夹代表一个芯片厂家**，芯片厂家下，每一个子文件夹，表示一个开发板 |
| common           | 存放与处理器体系无关的通用代码，可以说为**通用核心代码！**   |
| cmd              | 存放uboot的相关命令实现部分                                  |
| drivers          | 存放外围芯片驱动，网卡，USB等                                |
| disk             | 存放驱动磁盘的分区处理代码                                   |
| fs               | 本目录下存放文件系统相关代码，**每一个子文件夹表示文件系统** |
| net              | 网络协议相关代码                                             |
| doc              | uboot说明文档                                                |
| include          | 各种头文件                                                   |
| post             | 上电自检代码                                                 |
| api              | 外部扩展程序的API和示例                                      |
| tools            | 编译S-Record或者U-boot镜像的相关工具                         |

## 5\. 如何编译Uboot

```c
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- distclean
make ARCH=arm CORSS_COMPILE=arm-linux-gnueabihf- colibri-imx6ull_defconfig
make V=1 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -j8
```

`ARCH=arm`：arm架构

`CROSS_COMPILE`：使用的交叉编译器

> 如果编译出错，your compile older 6.0，可以参考【[1](https://blog.csdn.net/Jun626/article/details/90448830)】

`colibri-imx6ull_defconfig`：指定一个`config`文件，作为相关版型的配置信息

`V=1`：这个选项能显示出编译过程中的详细信息，即是verbose编译模式

`-j8`：多核并行编译，可以提高编译速度，受硬件限制

## 6\. U-boot工作模式

> U-boot的工作模式有：**启动加载模式和下载模式**

- **启动加载模式**：

**启动加载模式**，为Bootloader正常工作模式，一款开发板，正常上电后，Bootloader将嵌入式操作系统==**从FLASH中加载到SDRAM中**==运行。

- **下载模式**：

**下载模式**，就是Bootloader通过通信，将内核镜像、根文件系统镜像**从PC机直接下载到目标板的FLASH中**。

## 7\. U-boot的存放位置

嵌入式系统，一般使用Flash来作为启动设备，**Flash上存储着U-boot、环境变量、内核映像、文件系统等**。U-boot存放于Flash的起始地址，所在扇区由Soc规定。

![img](https://i.loli.net/2021/12/02/dXOn3fe91FZQWzq.jpg)

## 8\. U-boot系列文章汇总

> 下面是进行U-boot开发期间，感觉比较不错的资料，总结分享一下！

\[1\] : [Uboot官网](http://www.denx.de/wiki/U-Boot/)、[Uboot官方指南](http://www.denx.de/wiki/DULG/Manual)、[官方指南2](https://u-boot.readthedocs.io/en/latest/index.html)

\[2\] : https://blog.51cto.com/u_9291927/category5

\[3\] : https://blog.csdn.net/ooonebook/category_6484145.html

\[4\]：[https://blog.csdn.net/qq\_36310253/category\_9332618.html](https://blog.csdn.net/qq_36310253/category_9332618.html)


<center><b> <font color ="blue">欢迎关注【嵌入式艺术】，董哥原创！</font></b></center>
<div align=center><img src="https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/blog.png" alt="img" width = "60%" height ="10%"/>
</div>
