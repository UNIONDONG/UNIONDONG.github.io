---
title:       "Soc的Bring Up流程"
date:        2023-11-12
author:      "Donge"
image:       "img/post-bg-miui6.jpg"
tags:        ["Linux面试指南", "嵌入式基础必备知识", "嵌入式Linux"]
categories:  ["Tech"]
weight: 1

---

## 1、Bring Up流程

![img](https://img2.baidu.com/it/u=1228692277,1647023594&fm=253&fmt=auto&app=138&f=PNG?w=681&h=294)

`SOC (System on a Chip) bring-up`是一个复杂的过程，涉及到硬件、固件和软件的集成和验证，以下是一个基于`BROM`，`SPL`，`UBOOT`和`Linux`的启动流程的概述：

1.  **`BROM (Boot Read-Only Memory)`启动**：启动的最初阶段，在这个阶段，系统会执行芯片`ROM`里面的代码，这部分代码主要用来检查启动模式，包括`NOR`、`Nand`、`Emmc`等，然后从对应的存储介质中加载`SPL(Secondary Program Loader)`代码。
2.  **`SPL (Secondary Program Loader)`启动**：`SPL`属于`Uboot`的一部分，它的主要作用就是：**初始化硬件并加载完整的`U-boot`**，主要体现在初始化时钟、看门狗、`DDR`、`GPIO`以及存储外设，最后将`U-boot`代码加载到`DDR`中执行。
3.  **`U-Boot`启动**：`U-boot`的主要作用是：引导加载`Kernel`和`DTS`。`U-boot`在启动之后，同样初始化`Soc`硬件资源，然后会计时等待，并执行默认的启动命令，将`Kernel`和`DTS`信息从存储介质中读取出来并加载到内存中执行。
4.  **`Kernel`启动**：在`U-Boot`加载了内核映像和设备树之后，系统会启动`Linux`。在这个阶段，系统会初始化各种硬件设备，加载驱动程序并启动用户空间应用程序。

> 更多干货可见：[高级工程师聚集地](https://t.zsxq.com/0eUcTOhdO)，助力大家更上一层楼！

&nbsp;

## 2、常见问题

![img](https://img1.baidu.com/it/u=1356081243,31945078&fm=253&fmt=auto&app=138&f=JPEG?w=852&h=500)

`Q`：为什么上一个阶段已经初始化了硬件资源，下一个阶段为何重复初始化？

`A`：

1.  每个阶段的硬件初始化，其目标和需求都不同，硬件配置也会不一样，因此在不同阶段进行不同的初始化。

2.  硬件状态可能会改变，在`SOC`启动过程中，硬件状态可能会因为电源管理、时钟管理等原因而改变，这可能需要在每个阶段都重新初始化以确保其正确工作

3.  为了保证硬件资源的可靠性，最好每个阶段都重新初始化一次

&nbsp;

`Q`：`U-boot`加载内核时，会进行重定位的操作，这一操作有何意义？

`A`：

1. `U-boot`的重定位，主要作用是为了 **给内核提供一个连续的、大的内存空间，供内核和其他应用程序使用**
2. `U-boot`的加载过程分两个阶段，即：`SPL`和`U-boot`，
 - 在`SPL`阶段，主要将`U-boot`代码从`Flash`中加载到`RAM`指定位置
 - 在`U-boot`阶段，`U-boot`会将自身从`RAM`的开始部分移动到`RAM`的末尾，占用高地址空间，从而让低地址空间可以作为一个连续的，大的内存空间供内核和其他应用程序使用。 

&nbsp;

`Q`：在`Bring Up`中，为了保证启动时间，如何裁剪？

`A`：

> 启动时间的裁剪是一个重要的步骤，其主要目标是缩短从电源打开到操作系统完全启动的时间。

1.  优化`Bootloader`：减小`Bootloader`的代码大小，减少硬件初始化（只初始化必要硬件设备）等
2.  优化`Kernel`：减少启动服务数量，优化服务的启动顺序，使用预加载技术等方法来实现。
3.  使用快速启动模式：一些`SOC`支持快速启动模式，这种模式下，`SOC`会跳过一些不必要的硬件初始化和自检过程，从而更快地启动。
4.  使用休眠和唤醒技术：一些`SOC`还支持休眠和唤醒技术，这种技术可以将系统的状态保存到非易失性存储器中，然后关闭系统。当系统再次启动时，可以直接从非易失性存储器中恢复系统的状态，从而更快地启动。

<div align=center><img src="https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/blog.png" alt="img" width = "60%" height ="10%"/>
</div>
&nbsp;

