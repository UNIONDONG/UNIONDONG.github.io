---
date: '2024-01-19T20:27:15+08:00'
title:       '【LED子系统深度剖析】二、LED子系统框架分析'
description: ""
author:      "Donge"
image:       ""
tags:        ["LED子系统", "LED子系统深度剖析", "Linux驱动开发", "LED驱动开发"]
categories:  ["Tech" ]
weight: 2
---

# 【LED子系统深度剖析】二、LED子系统框架分析

## 1、前言

我们学习嵌入式，无论是`C51`、`STM32`或者是`ARM`，都是从点灯开始的，点灯在嵌入式中的地位等同于`Hello World`在各大语言中的地位！

虽然`LED`功能简单，但是其**麻雀虽小，五脏俱全**，在学习`Linux驱动开发`的过程中，学习`LED`子系统，往往也能够起到**牵一发而动全身**的作用，也更有益于大家熟悉驱动开发的框架！

## 2、LED裸机处理

我们在学习`Linux驱动框架`的时候，第一步要做的就是去掉子系统的面纱，先弄明白裸机处理的流程！

![image-20230328063034205](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/image-20230328063034205.png)

有嵌入式经验的朋友，对`LED`的裸机在清楚不过了，上面是`LED`的硬件电路，通常一端接到`VCC`，一端接到`GPIO`，当`GPIO`拉低时，`LED`亮；当`GPIO`拉高时，`LED`灭。

在这里裸机我们不过多了解了，目的在于窥探`LED子系统`。

## 3、LED子系统框架

框架是什么？

框架是一个规范，为我们开发者增加限制的同时，也是为了更好的开发新的程序，新的功能，其目的主要是：**将不变的成分剥离开来，固化进框架，让开发者做最少的事情!**

![image-20230417084033734](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/image-20230417084033734.png)

框架所处的位置，正如上图所示，由下往上看：

- **Hardware**：我们的硬件设备，指的是`LED`
- **硬件驱动层**：是直接操作硬件的实现，用于驱动硬件，实现相应的功能，并且将硬件设备注册进框架之中。
- **核心层**：将`LED`进行统一管理，提供注册，注销，管理`LED`等相关接口，起到呈上启下的作用，方便上层调用。
- **用户层**：用户通过`sysfs`文件系统中对应的文件节点，能够直接控制`LED`的亮灭。

## 4、LED子系统目录结构及核心文件

了解完`LED`子系统框架之后，我们来分析一下其相关的目录结构！

```bash
ketnel
│   └── driver
│   │   └── leds
│   │   │   ├──	Makefile
│   │   │   ├──	led-core.c
│   │   │   ├──	led-gpio.c
│   │   │   ├──	led-class.c
│   │   │   ├──	led-triggers.c
│   │   │   ├──	......
│   │   │   └── trigger
│   │   │   │   ├── ledtrig-cpu.c
│   │   │   │   ├── ledtrig-heartbeat.c
│   │   │   │   ├── .......
```

上面即为`LED`子系统的目录结构，其主要核心文件有：

- `led-gpio.c`：硬件驱动层实现，直接控制硬件设备，并且将其操作硬件设备的接口，注册进入`LED`驱动框架
- `led-core.c`：核心层实现，抽象软件实现的相关功能，如闪烁，亮度设置等等，并管理`LED`设备
- `led-class.c`：完成逻辑设备的注册以及相应属性文件的添加
- `led-triggers.c`：`LED`触发功能的抽象，提供注册接口以及闪烁功能控制
- `ledtrig-cpu.c`：将`LED`作为`CPU`灯
- `ledtrig-heartbeat.c`：将`LED`作为心跳灯

## 5、sysfs目录结构

在上面，我们了解了`Linux`下`LED`子系统相关的几个重要文件，那么该子系统在嵌入式设备的`sysfs`中的呈现方式又是如何的呢？

### 5.1 确保LED子系统打开

我们如果在内核中打开了`LED子系统`目录下的`Makefile`文件，也就是`kernel/drivers/leds/Makefile`，我们看到

```makefile
# SPDX-License-Identifier: GPL-2.0

# LED Core
obj-$(CONFIG_NEW_LEDS)			+= led-core.o
obj-$(CONFIG_LEDS_CLASS)		+= led-class.o
obj-$(CONFIG_LEDS_CLASS_FLASH)	+= led-class-flash.o
obj-$(CONFIG_LEDS_TRIGGERS)		+= led-triggers.o

......
```

我们必须在内核的配置中，通过 `make menuconfig`打开`LED`的相关配置，才支持`LED`相关功能。

### 5.2 查看sysfs文件结构

我们在开发板中输入`ls /sys/class/leds/`，**可以查看`LED`子系统生成的文件信息**。

| /sys/class/leds下的目录 | 对应的LED灯设备 |
| --- | --- |
| cpu | 开发板的心跳灯 |
| red | Pro开发板RGB灯的红色 |
| green | Pro开发板RGB灯的绿色 |
| blue | Pro开发板RGB灯的蓝色 |
| mmc0: | SD卡指示灯（出厂镜像默认没有启用） |

根据打开配置的不同，生成不同的文件节点

**查看一下`CPU`节点的信息**

```bash
#在开发板上有cpu目录，可在开发板上执行如下命令查看
ls /sys/class/leds/cpu
```

![未找到图片03|](https://doc.embedfire.com/linux/imx6/quick_start/zh/latest/_images/ledsub003.png)

相关属性文件有：`brightness`、`max_brightness`、`trigger`等

- `max_brightness`文件：表示LED灯的最大亮度值。
- `brightness`文件：表示当前LED灯的亮度值，它的可取 值范围为`[0~max_brightness]`，一些LED设备不支持多级亮度，直接以非0值来 表示LED为点亮状态，0值表示灭状态。
- `trigger`文件：则指示了LED灯的触发方式，查看该文件的内容时，该文件会 列出它的所有可用触方式，而当前使用的触发方式会以“\[\]”符号括起。

常见的触 发方式如下表所示：

| 触发方式 | 说明  |
| --- | --- |
| none | 无触发方式 |
| disk-activity | 硬盘活动 |
| nand-disk | nand flash活动 |
| mtd | mtd设备活动 |
| timer | 定时器 |
| heartbeat | 系统心跳 |

## 6、总结

好啦，本篇主要介绍了`LED`子系统框架，下面我们来回顾一下：

1.  明白裸机中`LED`底层硬件的操作方法
2.  了解`Linux`下`LED`子系统驱动框架以及每层含义
3.  了解`Linux`和`sysfs`的文件分布


<center><b> <font color ="blue">欢迎关注【嵌入式艺术】，董哥原创！</font></b></center>
<div align=center><img src="https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/blog.png" alt="img" width = "60%" height ="10%"/>
</div>
