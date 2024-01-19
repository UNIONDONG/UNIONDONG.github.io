---
date: '2024-01-19T21:14:38+08:00'
title:       '【MMC子系统】三、MMC子系统框架'
description: ""
author:      "Donge"
image:       ""
tags:        ["MMC子系统", "MMC/SD/SDIO", "Linux驱动开发"]
categories:  ["Tech" ]
weight: 3
---

# 【MMC子系统】三、MMC子系统框架

上章，我们简单了解了`EMMC`协议，感兴趣的可以查阅一下`SD`和`SDIO`的协议，之所以`Linux`内核能够对`SD`、`SDIO`、`EMMC`进行统一管理，根本原因就是三者协议上的相似性，我们该系列文章均以`EMMC`为剑，一层层划开包裹着的盔甲。

> 本系列文章，均以`Linux 4.19`为参考

&nbsp;

## 1、MMC子系统框架

![MMC Subsystem](https://hughesxu.github.io/assets/img/sample/mmc_subsystem.svg)

如上图所示，`MMC`子系统的整体框架包括：`MMC Host`、`MMC Core`、`MMC Block`。我们从下网上看：

- `MMC HOST`：即`MMC`控制器驱动层，正如其名，该层主要是为了实现`MMC`控制器的初始化，以及`MMC`底层的数据收发操作，其直接控制的是底层寄存器，用以产生相应的通信时序。
- `MMC CORE`：即`MMC`核心层，该层主要起到了承上启下的作用。对下，主要体现在注册`MMC`总线，实现对`MMC device`和`MMC driver`的统一管理；对上，体现在实现`MMC`通信协议，并向上提供相应的读写操作接口。
- `MMC BLOCK`：即`MMC`块设备驱动层，其主要作用是屏蔽底层的实现逻辑，将底层抽象为卡设备，并且与虚拟文件系统关联，负责块设备请求的处理以及请求队列的管理，又称为`card`卡驱动。

> 哈哈，简单吧，我们刚开始对`MMC`子系统框架就先了解这么多，不着急，慢慢来。

&nbsp;

## 2、MMC子系统文件结构

了解完`MMC`子系统后，我们看一下`MMC`驱动在`Linux`下的目录结构，我们进入到`drivers/mmc`目录

```bash
drivers/mmc/
	├── core
		├── block.c
		├── bus.c
		├── core.c
		├── mmc.c
		├── mmc_ops.c
		├── ......
	├── host
		├── sunxi-mmc.c
		├── ......
```

> **这里介绍一个方法**

如果刚接触的朋友，不知道文件之间的关系是怎么样的，可以通过`Makefile`和`Kconfig`文件来大致看一下。

```makefile
obj-$(CONFIG_MMC)		+= mmc_core.o
mmc_core-y			:= core.o bus.o host.o \
				   mmc.o mmc_ops.o sd.o sd_ops.o \
				   sdio.o sdio_ops.o sdio_bus.o \
				   sdio_cis.o sdio_io.o sdio_irq.o \
				   slot-gpio.o
```

由上面可知，`MMC CORE`核心层，包括的文件有：`core.c`、`bus.c`等等，

&nbsp;

> 更多干货可见：[高级工程师聚集地](https://t.zsxq.com/0eUcTOhdO)，助力大家更上一层楼！

&nbsp;

了解大致的文件布局后，我们主要介绍一下文件的作用：

**`MMC HOST`控制器驱动层**：

- `sunxi-mmc.c`：所有的控制器驱动文件，均位于`host`文件夹下，主要是不同芯片厂家对`MMC`控制器的底层实现，一般非原厂人员不必深入研究。

**`MMC CORE`核心层**：

- `bus.c`：主要作用是为了注册`MMC`总线，实现对`MMC` `drivers`和`devices`的统一管理
- `core.c`：主要作用是实现`MMC`通信协议，封装`MMC`通信命令，完成`MMC`核心功能，并向上提供操作接口。
- `mmc_ops.c`：主要作用是提供操作`MMC`卡的接口函数，如：发送，接收数据接口，该文件会用到`core.c`提供的命令接口。
- `mmc.c`：主要作用是处理`MMC`卡的相关操作，包括识别卡，读写卡等等，该文件会用到`mmc_ops.c`和`core.c`提供的命令接口。

**`MMC BLOCK`块设备驱动层**：

- `block.c`：处理`MMC`卡的块设备接口，包括读写块，处理块设备的电源和时钟等。

&nbsp;

## 3、MMC设备在Linux下的文件分布

介绍完源代码中的目录结构，我们看一下成功加载`MMC`驱动后，在`Linux`文件系统中的目录结构。

**在进程文件系统中**：

- 我们的`MMC Card`被成功识别后，会在`procfs`中看到`mmc`的相关节点：如`/dev/mmcblk0`，其中看到`/dev/mmcblk0p1`表示磁盘中的一个分区

**在虚拟文件系统中**：

> 同时在`sysfs`中也会看到对应的节点

- 在`/sys/bus/mmc/devices/`下，我们能够看到识别到的设备信息
- 在`/sys/class/mmc_host/mmc0/`下也能够看到设备信息
- 同时在`/sys/block/mmcblk0/`下，能够看到该卡设备的信息，以及分区信息等。

```bash
# ls /sys/bus/mmc/devices/
mmc0:aaaa

# ls /sys/class/mmc_host/mmc0/
device     mmc0:aaaa  power      subsystem  uevent

# ls /sys/block/mmcblk0/
alignment_offset   ext_range          mq                 size
bdi                force_ro           power              slaves
capability         hidden             queue              stat
dev                holders            range              subsystem
device             inflight           removable          uevent
discard_alignment  mmcblk0p1          ro
```

&nbsp;

## 4、总结

本章主要介绍了三个部分：

- `MMC`子系统的框架
- `MMC`子系统的文件结构
- `MMC`设备在`Linux`下的文件分布

下章，我们来详细了解`MMC`子系统的代码实现部分。




<center><b> <font color ="blue">欢迎关注【嵌入式艺术】，董哥原创！</font></b></center>
<div align=center><img src="https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/blog.png" alt="img" width = "60%" height ="10%"/>
</div>
