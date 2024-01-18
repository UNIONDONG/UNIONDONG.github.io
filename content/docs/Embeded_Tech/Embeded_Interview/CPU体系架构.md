---
date: '2024-01-17T21:39:15+08:00'
title:       'CPU体系架构'
description: ""
author:      "Donge"
image:       ""
tags:        ["Linux面试指南"]
categories:  ["Tech" ]
weight: 2
---

# CPU体系架构

![img](https://img2.baidu.com/it/u=1963592699,3653391242&fm=253&fmt=auto&app=138&f=JPEG?w=853&h=363)

## 2.1 CPU体系架构有哪些？

> 我们常见的`CPU`架构有哪些呢？

如果我们熟悉`Linux`，那么这个问题肯定不难回答！

我们查看内核目录下的`arch`子目录，就可以看到`Linux`所支持的处理器架构，基本属于我们常见的类型了。

```bash
# ls ./arch
alpha  arc  arm  arm64  c6x  h8300  hexagon  ia64  Kconfig  m68k  microblaze  mips  nds32  nios2  openrisc  parisc  powerpc  riscv  s390  sh  sparc  um  unicore32  x86  xtensa
```

&nbsp;

<span style="color: red;">**准确来说，`CPU`处理器架构主要有以下几种类型**</span>：

- **CISC（复杂指令集计算机）**：`CISC`架构的`CPU`设计理念是尽可能减少程序指令的数量，以降低`CPU`和内存之间的通信频率。这种架构的一个显著特点是拥有大量的寄存器和复杂的指令集。`Intel`的`x86`架构就是一个典型的`CISC`架构
- **RISC（精简指令集计算机）**：`RISC`架构的`CPU`设计理念是通过简化指令集来提高`CPU`的运行效率。这种架构的一个显著特点是拥有较少的寄存器和简单的指令集。`ARM`架构就是一个典型的`RISC`架构
- **MISC（中间指令集计算机）**：`MISC`架构的`CPU`设计理念是在`CISC`和`RISC`之间寻找一个平衡点，既不过于复杂也不过于简单。这种架构的一个显著特点是指令集的复杂度介于`CISC`和`RISC`之间
- **VLIW（超长指令字计算机）**：`VLIW`架构的`CPU`设计理念是通过增大指令长度来提高并行执行的可能性。这种架构的一个显著特点是指令长度远大于其他架构的`CPU`
- **EPIC（显式并行指令计算）**：`EPIC`架构的`CPU`设计理念是通过显式标记并行指令来提高`CPU`的运行效率。这种架构的一个显著特点是指令集中包含了并行执行的信息。`Intel`的`Itanium`架构就是一个典型的`EPIC`架构
- **超标量架构**：超标量架构的`CPU`设计理念是通过在一个时钟周期内执行多条指令来提高`CPU`的运行效率。这种架构的一个显著特点是`CPU`内部包含了多个执行单元，可以同时执行多条指令
- **超线程技术**：超线程技术是`Intel`公司为其部分`CPU`所采用的一种使单一处理器像多个逻辑处理器那样并行处理多个线程的技术
- **多核心架构**：多核心架构的`CPU`设计理念是在一个`CPU`芯片内集成多个处理器核心，以提高并行处理能力。这种架构的一个显著特点是`CPU`内部包含了多个独立的处理器核心，每个核心可以独立执行指令

&nbsp;

![img](https://img2.baidu.com/it/u=3770652576,1376693706&fm=253&fmt=auto&app=120&f=JPEG?w=909&h=500)

这里就有一个疑问，我们什么时候说`RISC`架构，什么时候说`ARM`架构，这两个有什么区别呢？

> 以`ARM`和`RISC`为例：

`ARM`架构和`RISC`架构的主要区别在于`ARM`实际上是`RISC`的一个具体实现，而`RISC`则是一个更广泛的处理器**设计理念**。换句话说，`ARM`是`RISC`的一个子集。

同理，`X86`架构是`CISC`的一个子集。

&nbsp;

## 2.2 常见的问题

`Q1`：你所熟知的处理器架构有哪些？

我们常见的处理器架构有`ARM`、`X86`、`mips`架构等；

&nbsp;

`Q2`：`STM32`属于什么架构的？

`STM32`是`ST`公司开发的32位微控制器集成电路，基于 `ARM` 的 `Cortex-M` 系列内核。因此，`STM32` 属于 `ARM` 架构的微控制器。

&nbsp;

`Q3`：`RISC`和`CISC`的区别是什么？

- `RISC`：精简指令集架构，通过简化指令集，使得大多数的操作都能够在一个指令周期内完成，提高`CPU`运行效率
- `CISC`：复杂指令集架构，指令集丰富，能够完成一些较为复杂的任务，并且可以降低`CPU`和内存之间的通信频率，提高性能。

&nbsp;

<center><b> <font color ="blue">欢迎关注【嵌入式艺术】，董哥原创！</font></b></center>

<div align=center><img src="https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/blog.png" alt="img" width = "60%" height ="10%"/>
</div>
