---
date: '2024-01-17T21:41:10+08:00'
title:       'Linux用户态和内核态交互的几种方式'
description: ""
author:      "Donge"
image:       ""
tags:        ["Linux面试指南"]
categories:  ["Tech" ]
weight: 3
---
# Linux用户态和内核态交互的几种方式

![img](https://img2.baidu.com/it/u=408265743,2883498083&fm=253&fmt=auto&app=138&f=PNG?w=522&h=500)

`Linux`分为内核态`Kernel Mode`和用户态`User Mode`，**其通信方式主要有**：

- **系统调用`System Call`**：最常见的用户态和内核态之间的通信方式。通过系统调用接口（`open`、`read`、`write`、`fork`等）请求内核执行特定的动作。
- **中断`Interrupts`**：中断包括软中断和硬中断，每当中断到来的时候，`CPU`会暂停当前执行的用户态代码，切换到内核态来处理中断。
- **信号`Signal`**：内核通过`Signal`通知用户态进程发生了某些事件，用户态注册信号处理函数，来响应特定的信号事件。如 `SIGTERM`、`SIGINT` 等。
- **共享内存`Share Memory`**：允许多个进程在它们的地址空间中共享一块内存区域，从而实现用户态和内核态之间的高效通信。这种方式避免了用户态和内核态之间频繁切换的问题，但是也需要考虑到数据的同步问题，保证数据一致性。

&nbsp;

![img](https://img0.baidu.com/it/u=4155245835,2490995974&fm=253&fmt=auto&app=138&f=PNG?w=598&h=327)

用户态`User Mode`访问内核态`Kernel Mode`的**数据交互的方式有**：

- **`procfs`进程文件系统**：一个伪文件系统，因为其不占用外部存储空间，只占有少量的内存，挂载在`/proc`目录下

- **`sysctl`**：它也是一个`Linux`命令，主要用来修改内核的运行时参数，也就是在内核运行时，动态修改内核参数。

  > 和 `procfs` 的区别在于：`procfs` 主要是输出只读数据，而 `sysctl` 输出的大部分信息是可写的。

- **`sysfs`虚拟文件系统**：通过`/sys`来完成用户态和内核的通信，和 procfs 不同的是，sysfs 是将一些原本在 procfs 中的，关于设备和驱动的部分，独立出来，以 “设备树” 的形式呈现给用户。

- **`netlink `接口**：也是最常用的一种方式，本质是`socket`接口，使用`netlink`用于网络相关的内核和用户进程之间的消息传递。

- **共享内存`Share Memory`**：允许多个进程在它们的地址空间中共享一块内存区域，从而实现用户态和内核态之间的高效数据传输。

<center><b> <font color ="blue">欢迎关注【嵌入式艺术】，董哥原创！</font></b></center>

<div align=center><img src="https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/Embeded_Art.gif" alt="img" width = "60%" height ="10%"/>
</div>
