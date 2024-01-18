---
date: '2024-01-18T22:27:58+08:00'
title:       '【NVMEM子系统深入剖析】二、NVMEM驱动框架'
description: ""
author:      "Donge"
image:       ""
tags:        ["NVMEM子系统", "NVMEM子系统深入剖析", "Efuse", "安全启动"]
categories:  ["Tech" ]
weight: 2
---

# 【NVMEM子系统深入剖析】二、NVMEM驱动框架
## 1、前言

> `NVMEM SUBSYSTEM`，该子系统整体架构不算太大，还是比较容易去理解的，下面我们一起去一探究竟！

`NVMEM（Non Volatile Memory）`，该子系统主要用于实现`EEPROM`、`Efuse`等非易失存储器的统一管理。

在早期，像`EEPROM`驱动是存放于`/drivers/misc`目录下，由于没有做到好的抽象，每次需要去访问相应内存空间，都需要去复制几乎一样的代码，去注册`sysfs`，这是一个相当大的抽象泄露。

`NVMEM`子系统就是为了解决以往的抽象泄露问题。

&nbsp;

## 2、驱动框架

> 该驱动框架较为简单，也适合初学者去熟悉基本的驱动框架。

![image-20230210071204144](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/image-20230210071204144.png)

**应用层**：可以通过用户空间所提供的文件节点，来读取或者修改`nvmem`存储器的数据。

**NVMEM 核心层**：统一管理`NVMEM`设备，向上实现文件系统接口数据的传递，向下提供统一的注册，注销`nvmem`设备接口。

**NVMEM 总线驱动**：注册`NVMEM`总线，实现`NVMEM`控制器的底层代码实现。

**TIP**：

`nvmem`子系统提供读写存储器的接口有两种，一种是通过文件系统读写，一种是在内核驱动直接读写。

对于`EEPROM`，其可以进行读写操作，而对于`efuse`，更多用于读取密钥信息，进而判断镜像是否被篡改，在用户空间是不允许被更改的。

这种是通过驱动提供的开放接口，直接获取指定位置的数据，详细的后面展开来说。

&nbsp;

## 3、源码目录结构

```bash
ketnel
│   └── driver
│   │   └── nvmem
│   │   │   ├──	core.c					# NVMEM核心层
│   │   │   ├──	rockchip-efuse.c		# NVMEM总线驱动
```

&nbsp;

## 4、用户空间下的目录结构

我们可以在用户空间去读取/写入数据，其所在的目录：`/sys/bus/nvmem/devices/dev-name/nvmem`

```bash
hexdump /sys/bus/nvmem/devices/qfprom0/nvmem

0000000 0000 0000 0000 0000 0000 0000 0000 0000
*
00000a0 db10 2240 0000 e000 0c00 0c00 0000 0c00
0000000 0000 0000 0000 0000 0000 0000 0000 0000
...
*
0001000
```

&nbsp;

## 5、参考文章

[1]：https://blog.csdn.net/qq_33160790/article/details/87836614

[2]：https://blog.csdn.net/tiantao2012/article/details/72284862

&nbsp;


<center><b> <font color ="blue">欢迎关注【嵌入式艺术】，董哥原创！</font></b></center>
<div align=center><img src="https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/blog.png" alt="img" width = "60%" height ="10%"/>
</div>
