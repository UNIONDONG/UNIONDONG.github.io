---
date: '2024-01-18T23:02:05+08:00'
title:       '【深入理解Linux锁机制】二、中断屏蔽'
description: ""
author:      "Donge"
image:       ""
tags:        ["内核锁", "Linux 锁机制", "操作系统锁"," Linux 系统开发","Linux 内核"]
categories:  ["Tech" ]
weight: 2
---
# 【深入理解Linux内核锁】二、中断屏蔽


> 上一篇了解了内核锁的由来，本篇文章主要来讲一下中断屏蔽的底层实现以及原理。

![img](https://d00.paixin.com/thumbs/1152339/17466927/staff_1024.jpg)

&nbsp;

## 1、中断屏蔽思想

<span style="color: red;">**中断屏蔽，正如其名，屏蔽掉`CPU`的中断响应功能，解决并发引起的竞态问题。**</span>

> 在进入临界区前屏蔽中断，这么做有什么好处，以及有什么弊端？

**好处在于**：

- **解决了进程与中断之间的并发**：保证在执行临界区代码时，不被中断所打断。
- **解决了进程与进程之间调度的并发**：系统的进程调度与中断息息相关，同时也限制了系统进程的并发，解决了系统进程并发带来的竞态问题。

**弊端在于**：

- **各类中断类型较多，一棒子打死影响大**：`Linux`内核中，除了系统进程调度依赖中断，还有一些异步`I/O`等众多操作都依赖中断，因此长时间屏蔽中断是很危险的，会对系统造成严重影响，因此也要求临界区代码要简短。
- **解决的不够完善**：关闭中断能够解决进程调度、中断引发的竞态，但是这些都是单`CPU`内部的，对于`SMP`对称多处理器，仍然不可避免的会收到其他`CPU`的中断。因此，并不能解决`SMP`多`CPU`引发的竞态。

<span style="color: red;">**因此，单独使用中断屏蔽通常不是一种值得推荐的避免竞态的方法**</span>

&nbsp;

## 2、Linux内核中断屏蔽的实现

### 2.1 Linux内核提供的API接口

> 关于中断屏蔽，`Linux`内核所提供的接口如下：

```c
local_irq_enable()				//	使能本CPU的中断
local_irq_disable()				//	禁止本CPU的中断
local_irq_save(flags)			//	禁止本CPU的中断，并保存CPU中断位的信息
local_irq_restore(flags)		//	使能本CPU的中断，并恢复CPU中断位的信息
local_bh_disable(void)			//	禁止本CPU底半部中断
local_bh_enable(void)    		//	使能本CPU底半部中断
```

文件位置：`kernel/include/linux/irqflags.h`

- `local_irq_enable`与`local_irq_disable`：直接打开/关闭本`CPU`内的中断，包括了顶半部和底半部中断的打开和关闭。
- `local_irq_save`与`local_irq_restore`：直接打开/关闭本`CPU`中断，并且保存中断屏蔽前的状态，便于后续恢复
- `local_bh_enable`与`local_bh_disable`：直接打开/关闭本`CPU`内的底半部中断

&nbsp;

### 2.2 API接口实现分析

> 因为中断屏蔽与底层芯片架构有关，不同架构处理方式不同，我们以`ARM`为例

#### 2.2.1 local\_irq\_enable

```c
#define local_irq_enable()	do { raw_local_irq_enable(); } while (0)

#define raw_local_irq_enable()		arch_local_irq_enable()

#define arch_local_irq_enable arch_local_irq_enable
static inline void arch_local_irq_enable(void)
{
    asm volatile(
        "	cpsie i			@ arch_local_irq_enable"
        :
        :
        : "memory", "cc");
}
```

**函数介绍**：`local_irq_enable`函数用于将`CPSR`寄存器中的中断使能位设为1，从而使得`CPU`能够响应中断。

**文件位置**：`kernel/arch/arm/include/asm/irqflags.h`

**相关实现**：

`asm`：声明一个内联汇编表达式

`cpsie i`：全称`Change Processor State, Interrupts Enabled`，主要用来设置`CPSR`寄存器的`I`位，来允许本`CPU`响应中断。

`memory`：向汇编说明，此处内存发生了更改，类似于内存屏障的作用

`cc`：表示可能会修改条件码的标志

> 汇编语言的格式，大家可以自行简单了解

&nbsp;

#### 2.2.2 local\_irq\_disable

```c
#define local_irq_disable() \
    do { raw_local_irq_disable(); trace_hardirqs_off(); } while (0)

#define raw_local_irq_disable()		arch_local_irq_disable()

#define arch_local_irq_disable arch_local_irq_disable
static inline void arch_local_irq_disable(void)
{
    asm volatile(
        "	cpsid i			@ arch_local_irq_disable"
        :
        :
        : "memory", "cc");
}
```

**函数介绍**：`local_irq_disable`函数用于将`CPSR`寄存器中的中断使能位设为0，从而禁止`CPU`响应中断。

**文件位置**：`kernel/arch/arm/include/asm/irqflags.h`

**相关实现**：同上

- `cpsid`：全称`Change Processor State, Interrupts Disabled`，用于清除`CPSR`寄存器的中断标志，以禁止中断！

&nbsp;

这里顺便提及一下，`CPSR`寄存器为`Current Program Status Register`，用于存储当前程序的状态信息，包括中断使能状态、处理器模式、条件标志等。

大多数的`ARM`处理器，都采用`CPSR`寄存器来管理装填信息，所以`ARM`处理器可以直接进行操作。

&nbsp;

#### 2.2.3 local\_irq\_save

```c
#define IRQMASK_REG_NAME_R "primask"

#define local_irq_save(flags)				\
    do {						\
        raw_local_irq_save(flags);		\
        trace_hardirqs_off();			\
    } while (0)


#define raw_local_irq_save(flags)			\
    do {						\
        typecheck(unsigned long, flags);	\
        flags = arch_local_irq_save();		\
    } while (0)

static inline unsigned long arch_local_irq_save(void)
{
    unsigned long flags;

    asm volatile(
        "	mrs	%0, " IRQMASK_REG_NAME_R "	@ arch_local_irq_save\n"
        "	cpsid	i"
        : "=r" (flags) : : "memory", "cc");
    return flags;
}
```

**函数介绍**：`arch_local_irq_save`函数，用于保存当前中断状态并禁用中断。

**文件位置**：`kernel/arch/arm/include/asm/irqflags.h`

**相关实现**：

`mrs %0 IRQMASK_REG_NAME_R`：这行代码使用`mrs`指令将中断屏蔽寄存器的值读取到通用寄存器`%0`中。`IRQMASK_REG_NAME_R`是一个占位符，表示要读取的中断屏蔽寄存器的名称，实际的中断屏蔽寄存器为`primask`。通过这行代码，中断屏蔽寄存器的值被保存到了`%0`寄存器中。

`: "=r" (flags) : : "memory", "cc"`: 这是一个约束部分，用于指定寄存器和内存的使用约束。`"=r" (flags)`表示将`%0`寄存器的值保存到`flags`变量中。`"memory"`和`"cc"`表示这段代码可能会修改内存和条件码寄存器。

总的来说，这段代码主要实现了：

1.  保存中断屏蔽寄存器的值到`flags`变量中，并返回
2.  关闭本`CPU`的中断

&nbsp;

#### 2.2.4 local\_irq\_restore

```c
#define IRQMASK_REG_NAME_W "primask"

#define local_irq_restore(flags)			\
    do {						\
        if (raw_irqs_disabled_flags(flags)) {	\
            raw_local_irq_restore(flags);	\
            trace_hardirqs_off();		\
        } else {				\
            trace_hardirqs_on();		\
            raw_local_irq_restore(flags);	\
        }					\
    } while (0)

#define raw_local_irq_restore(flags)			\
    do {						\
        typecheck(unsigned long, flags);	\
        arch_local_irq_restore(flags);		\
    } while (0)

/*
 * restore saved IRQ & FIQ state
 */
static inline void arch_local_irq_restore(unsigned long flags)
{
    asm volatile(
        "	msr	" IRQMASK_REG_NAME_W ", %0	@ local_irq_restore"
        :
        : "r" (flags)
        : "memory", "cc");
}
```

**函数介绍**：`arch_local_irq_restore`函数，用于恢复当前中断状态并打开中断。

**相关实现**：同上

&nbsp;

#### 2.2.5 local\_bh\_enable

```c
static inline void local_bh_enable(void)
{
    __local_bh_enable_ip(_THIS_IP_, SOFTIRQ_DISABLE_OFFSET);
}

void __local_bh_enable_ip(unsigned long ip, unsigned int cnt)
{
    WARN_ON_ONCE(in_irq());
    lockdep_assert_irqs_enabled();
#ifdef CONFIG_TRACE_IRQFLAGS
    local_irq_disable();
#endif
    /*
     * Are softirqs going to be turned on now:
     */
    if (softirq_count() == SOFTIRQ_DISABLE_OFFSET)
        trace_softirqs_on(ip);
    /*
     * Keep preemption disabled until we are done with
     * softirq processing:
     */
    preempt_count_sub(cnt - 1);

    if (unlikely(!in_interrupt() && local_softirq_pending())) {
        /*
         * Run softirq if any pending. And do it in its own stack
         * as we may be calling this deep in a task call stack already.
         */
        do_softirq();
    }

    preempt_count_dec();
#ifdef CONFIG_TRACE_IRQFLAGS
    local_irq_enable();
#endif
    preempt_check_resched();
}
EXPORT_SYMBOL(__local_bh_enable_ip);

asmlinkage __visible void do_softirq(void)
{
    __u32 pending;
    unsigned long flags;

    if (in_interrupt())
        return;

    local_irq_save(flags);

    pending = local_softirq_pending();

    if (pending && !ksoftirqd_running(pending))
        do_softirq_own_stack();

    local_irq_restore(flags);
}
```

**函数介绍**：`local_bh_enable`函数，启用本地的底半部`bottom half`处理，当中断来临时，底半部处理可以被执行。

**文件位置**：`kernel/include/linux/bottom_half.h`

**相关实现**：

1.  调用`__local_bh_enable_ip`传入两个参数，这两个参数的作用是：
    - `_THIS_IP_`：是一个宏定义，用于获取当前的指令地址，也就是调用 `local_bh_enable` 函数的地方。
    - `SOFTIRQ_DISABLE_OFFSET`：是一个常量，用于指定软中断禁用的偏移量。
2.  `__local_bh_enable_ip`其主要作用是：处理完软中断`softirq`后重新启用本地底半部`bottom half`处理，并检查是否需要进行进程调度。
3.  `WARN_ON_ONCE(in_irq())`：判断是否处于硬件中断上下文中，如果是，则打印警告信息
4.  lockdep\_assert\_irqs\_enabled()：这是一个锁依赖性检查宏，用于确保在调用此函数时中断是被启用的。
5.  `if (softirq_count() == SOFTIRQ_DISABLE_OFFSET) lockdep_softirqs_on(ip)`：如果当前软中断计数等于`SOFTIRQ_DISABLE_OFFSET`，则启用软中断。
6.  `__preempt_count_sub(cnt - 1)`：减少抢占计数，这是为了防止在处理软中断时发生抢占。
7.  `do_softirq`：这里表示如果有待处理的软中断，那么就调用`do_softirq()`函数来处理这些软中断。
    - `in_interrupt()`：判断是否处于硬中断中，如果是，则直接返回
    - `local_irq_save`：它保存并关闭本地中断，以防止在处理软中断时被其他硬中断打断。
    - `local_softirq_pending`：它获取当前待处理的软中断。
    - 如果存在待处理的软中断，并且软中断处理线程（ksoftirqd）没有在运行，那么就在当前的栈上处理软中断。
    - `local_irq_restore`：恢复本地中断。

&nbsp;

> 这里有一个疑问，大家不妨思考一下：
> 
> 中断上半部和下半部的机制，就是为了让那些紧急处理的事情放在下半部，不那么紧急或者时间较长的任务放到下半部处理，来保证系统的实时性。
> 
> 那么在这里，使能中断底半部之后，仍然执行了`local_irq_save`和`local_irq_restore`，来关闭本地硬中断，这么做是为了什么？

**我的猜想**：`local_bh_disable`和`local_bh_enable`是成对出现的，当我们关闭掉了底半部中断时，也有可能硬中断引发了多个软中断触发，在此打开的时候，此时已经就已经挂起了其他的软中断处理程序；

如果不关闭硬中断，这时候就有可能发生嵌套，导致堆栈溢出。

> 大家不妨可以一起讨论下。

&nbsp;

#### 2.2.6 local\_bh\_disable

```c
static inline void local_bh_disable(void)
{
    __local_bh_disable_ip(_THIS_IP_, SOFTIRQ_DISABLE_OFFSET);
}

static __always_inline void __local_bh_disable_ip(unsigned long ip, unsigned int cnt)
{
    preempt_count_add(cnt);
    barrier();
}
```

**函数介绍**：`local_bh_disable`函数，增加当前进程的抢占计数，从而阻止内核抢占当前进程。

**文件位置**：`kernel/include/linux/bottom_half.h`

**相关实现**：

1.  `preempt_count_add`：增加当前进程的抢占计数
2.  `barrier`：执行内存屏障，以确保抢占计数的增加在所有其他内存操作之前完成。

&nbsp;

#### 2.2.7 抢占计数机制

在`local_bh_eable`和`local_bh_disable`中，有一些抢占计数的操作，如：`preempt_count_add`、`preempt_count_dec`、`preempt_count_dec`等，这些作用是什么呢？

**抢占计数（`preempt_count`）在`Linux`内核中起着非常重要的作用。它主要用于防止内核抢占。**

> 在Linux内核中，当一个进程正在执行内核代码时，如果发生了中断或者有更高优先级的进程需要运行，那么当前进程可能会被抢占，即暂停当前进程，转而去执行中断处理程序或者更高优先级的进程。这种机制被称为内核抢占。
> 
> 然而，有些情况下，我们不希望当前进程被抢占。例如，当一个进程正在修改一些全局数据结构时，如果这个进程被抢占，那么其他进程可能会看到这些数据结构处于不一致的状态。为了防止这种情况发生，我们可以通过增加抢占计数来禁止内核抢占。

当抢占计数大于0时，内核抢占被禁止。

当抢占计数等于0时，内核抢占被允许。

因此，我们可以通过调用`preempt_count_add`函数来增加抢占计数，从而禁止内核抢占，通过调用`preempt_count_dec`和`preempt_count_dec`函数来减少抢占计数，从而允许内核抢占。

<span style="color: red;">**总的来说，抢占计数的作用就是用于控制内核抢占的开启和关闭，以保证内核代码的正确执行。**</span>

&nbsp;

> 关于中断底半部机制，内容较为复杂，放在后面单独拆解！

&nbsp;

## 3、总结

**该篇文章，主要了解以下几点**：

1.  中断屏蔽的思想
2.  中断屏蔽的好处与不足
3.  `Linux`内核提供的中断屏蔽接口
4.  中断屏蔽的底层操作的实现方式

![image-20230730115111509](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/image-20230730115111509.png)

&nbsp;

<center><b> <font color ="blue">欢迎关注【嵌入式艺术】，董哥原创！</font></b></center>
<div align=center><img src="https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/blog.png" alt="img" width = "60%" height ="10%"/>
</div>
