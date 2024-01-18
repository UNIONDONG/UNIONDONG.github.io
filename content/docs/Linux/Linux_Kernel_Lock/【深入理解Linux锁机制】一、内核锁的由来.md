---
date: '2024-01-18T23:01:55+08:00'
title:       '【深入理解Linux锁机制】一、内核锁的由来'
description: ""
author:      "Donge"
image:       ""
tags:        ["内核锁", "Linux 锁机制", "操作系统锁"," Linux 系统开发","Linux 内核"]
categories:  ["Tech" ]
weight: 1
---

# 【深入理解Linux锁机制】一、内核锁的由来

![img](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/11385343fbf2b2115357580754c47b340dd78ecb.jpeg@f_auto)

在`Linux`设备驱动中，我们必须要解决的一个问题是：**多个进程对共享资源的并发访问，并发的访问会导致竞态。**

## 1、并发和竞态

并发`（Concurrency）`：指的是多个执行单元同时、并行的被执行。

竞态`（RaceConditions）`：并发执行的单元对共享资源的访问，容易导致竞态。

共享资源：硬件资源和软件上的全局变量、静态变量等。

<span style="color: red;">**解决竞态的途径是：保证对共享资源的互斥访问。**</span>

互斥访问：一个执行单元在访问共享资源的时候，其他执行单元被禁止访问。

临界区`（Critical Sections）`：访问共享资源的代码区域成为临界区。临界区需要以某种互斥机制加以保护。

**常见的互斥机制包括**：中断屏蔽，原子操作，自旋锁，信号量，互斥体等。

![image-20230718074758776](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/image-20230718074758776.png)

&nbsp;

## 2、竞态发生的场合

![image-20230721075844712](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/image-20230721075844712.png)

### 2.1 多对称处理器（SMP）的多个CPU之间

多个CPU使用共同的系统总线，可以访问共同的外设和存储器。在`SMP`的情况下，多核`（CPU0、CPU1）`的竞态可能发生于：

- `CPU0`的进程和`CPU1`的进程之间
- `CPU0`的进程和`CPU1`的中断之间
- `CPU0`的中断和`CPU1`的中断之间

&nbsp;

### 2.2 单CPU内，该进程与抢占它的进程之间

在单CPU内，多个进程并发执行，当一个进程执行的时间片耗尽，也有可能被另一个高优先级进程打断，会发生竞态，即所谓的调度引发竞态。

&nbsp;

### 2.3 中断（软中断、硬中断、Tasklet、底半部）与进程之间

当一个进程正在执行，一个外部/内部中断（软中断、硬中断、Tasklet等）将其打断，会导致竞态发生。

&nbsp;

## 3、编译乱序和执行乱序

除了并发访问导致的竞态外，还需要了解编译器和处理器的一些特点所引发的一些问题。

### 3.1 编译乱序

> **现代的高性能编译器，为了提高Cache命中率以及CPU的Load/Store工作效率，会对目标代码进行乱序优化，减少逻辑上不必要的访存！**
>
> 因此，在打开编译器优化后，生成的汇编码并没有严格按照代码的逻辑顺序执行，这是正常的。

**为了解决编译乱序的问题，可以加入`barrier()`编译屏障**。

顾名思义，编译屏障，也就是为了阻挡编译器的编译优化，加入`barrier()`编译屏障，即可保证正确的执行顺序。

编译屏障代码实现如下：

```c
#define barrier() __asm__ __volatile__("": : :"memory")
```

这里详细解释一下`barrier`的汇编实现：

- `__asm__`：向编译器说明在此插入汇编代码
- `__volatile__`：用于告诉编译器，严禁将此处的汇编语句与其它的语句重组合优化。
- `("": : :"memory")`：一条汇编语句，第一个`:`前为汇编指令，这里是空操作；第二个`:`前表示输出操作数，为空；第三个冒号前为输入操作数，也是要修改的寄存器；最后`memory`表示该指令对内存进行访问，该指令确保了命令之前的内存操作需要完全执行，不被优化。

&nbsp;

**使用案例**：

```C
int main(int argc,char *argv[])
{
    int a = 0,b,c,d[4096],e;
    e = d[4095];
    barrier();
    b = a;
    c = a;
    return 0;
}
```

&nbsp;

### 3.2 执行乱序

<span style="color: red;">**编译乱序是编译器的行为，而执行乱序就是处理器运行时的行为。**</span>

**高级的`CPU`往往会根据自身的缓存特性，将访存指令重新排序执行！**这样就导致了多个顺序的指令，后发的指令仍有可能先执行完毕。

> 这种执行乱序，在多个`CPU`之间，以及单个`CPU`内部，都是非常常见的。

&nbsp;

#### 3.2.1 多CPU之间

处理器为了解决多核之间执行乱序的问题，一个`CPU`的行为对另一个`CPU`可见的情况，`ARM`处理器引入了内存屏障指令：

- DMB（数据内存屏障），保证在该指令前的所有指令，内存访问完成，再去访问该指令之后的访存动作
- DSB（数据同步屏障），保证在该指令前的所有访存指令执行完毕（访存，缓存，跳转预测，TLB维护等）完成
- ISB（指令同步屏障），`Flush`流水线，保证所有**在ISB之后执行**的指令都是从缓存或者内存中获得。

&nbsp;

#### 3.2.2 单CPU内部

> 在单`CPU`中，我们常遇到访问外设寄存器时，某些外设寄存器就对读写顺序有很高的要求，为了避免执行乱序的发生，这时候就需要`CPU`的一些内存屏障指令了。

`CPU`内部，为了解决这种问题，`CPU`提供了一些内存屏障指令：

> 可以参考`Documentation/memory-devices.txt`和`Documentation/io_ordering.txt`

- 读写屏障：`mb()`
- 读屏障：`rmb()`
- 写屏障：`wmb()`
- 寄存器读屏障`__iormb()__`
- 寄存器写屏障`__iowmb()__`

```c
#define writeb_relaxed(v,c)	__raw_writeb(v,c)
#define writew_relaxed(v,c)	__raw_writew((__force u16) cpu_to_le16(v),c)
#define writel_relaxed(v,c)	__raw_writel((__force u32) cpu_to_le32(v),c)

#define readb(c)		({ u8  __v = readb_relaxed(c); __iormb(); __v; })
#define readw(c)		({ u16 __v = readw_relaxed(c); __iormb(); __v; })
#define readl(c)		({ u32 __v = readl_relaxed(c); __iormb(); __v; })

#define writeb(v,c)		({ __iowmb(); writeb_relaxed(v,c); })
#define writew(v,c)		({ __iowmb(); writew_relaxed(v,c); })
#define writel(v,c)		({ __iowmb(); writel_relaxed(v,c); })
```

> `writel`与`writel_relaxed`的区别就在于有无屏障。

&nbsp;

## 4、总结

![image-20230725073439417](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/image-20230725073439417.png)

由上文可知，发生竞态的场合，主要发生在

1.  多对称处理器的多`CPU`之间
2.  单CPU的进程调度、抢占引发的竞态
3.  单CPU的中断与进程之间引发的竞态
4.  高性能的编译器编译乱序问题
5.  高性能的`CPU`带来的执行乱序问题

为了解决竞态的发生，`CPU`和`ARM`处理器提供的内存屏障指令等，同时也提供了中断屏蔽、原子操作、自旋锁、互斥锁、信号量等机制，下面我们来深入了解这些机制吧。


<center><b> <font color ="blue">欢迎关注【嵌入式艺术】，董哥原创！</font></b></center>
<div align=center><img src="https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/blog.png" alt="img" width = "60%" height ="10%"/>
</div>
