---
date: '2024-01-20T10:36:40+08:00'
title:       '【一文秒懂】Linux内核死锁检测'
description: ""
author:      "Donge"
image:       ""
tags:        ["tag1", "tag2"]
categories:  ["Tech" ]
weight: 8
---

# 【一文秒懂】Linux内核死锁检测


> 最近遇到了一个驱动上面的`BUG`，导致终端敲命令都无响应，最终导致内核触发了`hung_task_timeout`…
>
> 为什么会出现这种情况？该如何排查？

![Screenshot_20230627_222840](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/Screenshot_20230627_222840.png)

## 1、死锁

死锁指两个或更多进程或线程因相互等待对方释放资源而互相阻塞，从而导致系统中所有的进程或线程都无法继续运行的情况。

一个典型的死锁场景包括以下几个角色：

- **资源**：系统内的某个文件、某个设备、共享的内存区域等。
- **进程/线程**：进程或线程需要访问某个资源来完成其工作，但其当前无法取得该资源的控制权，因为该资源已被其他进程或线程占用。
- **饥饿**：由于进程无法获取其需要的资源，它不能继续前进或完成操作。如果没有正确的措施来处理和解决死锁，进程可能会一直等待，直到设备或整个系统崩溃。

&nbsp;

## 2、常见的死锁方式

**常见死锁的2种方式**：

- AA锁：包括重复上锁和上下文切换引起的上锁，即一个线程，持有`A`锁，还未释放，又去请求`A`锁
- AB-BA死锁：一个`F1`线程，持有`A`锁，再去获取`B`锁，而一个`F2`线程持有`B`锁，再去获取`A`锁，这个时候处于的死锁状态

**常见的死锁有以下4种情况**：

1.  进程重复申请同一个锁，称为AA死锁。例如，重复申请同一个自旋锁；使用读写锁，第一次申请读锁，第二次申请写锁。
2.  进程申请自旋锁时没有禁止硬中断，进程获取自旋锁以后，硬中断抢占，申请同一个自旋锁。这种AA死锁很隐蔽，人工审查很难发现。
3.  两个进程都要获取锁L1和L2，进程1持有锁L1，再去获取锁L2，如果这个时候进程2持有锁L2并且正在尝试获取锁L1，那么进程1和进程2就会死锁，称为AB-BA死锁。
4.  在一个处理器上进程1持有锁L1，再去获取锁L2，在另一个处理器上进程2持有锁L2，硬中断抢占进程2以后获取锁L1。这种AB-BA死锁很隐蔽，人工审查很难发现。

**内核提供了`Lockdep`来检测死锁的异常情况**

&nbsp;

## 3、Lockdep 内核配置

- `CONFIG_LOCKDEP`：
- `CONFIG_DEBUG_LOCK_ALLOC`：检查内核是否错误地释放被持有的锁。
- `CONFIG_PROVE_LOCKING`：允许内核报告死锁问题。
- `CONFIG_DEBUG_LOCKDEP` ：在死锁发生，内核报告相应的死锁
- `CONFIG_LOCK_STAT`：追踪锁竞争的点，解释的更详细

&nbsp;

## 4、Lockdep 初探

- **`lockdep`操作的基本单元并非单个的锁实例，而是锁类（lock-class）**。比如，`struct inode`结构体中的自旋锁`i_lock`字段就代表了这一类锁，而具体每个`inode`节点的锁只是该类锁中的一个实例。对所有这些实例，`lockdep`会把它们当作一个整体做处理，即把判断粒度放大，否则对可能有成千上万个的实例进行逐一判断，那处理难度可想而知，而且也没有必要.
- **`lockdep`跟踪每个锁类的自身状态**，也跟踪各个锁类之间的依赖关系，通过一系列的验证规则，以确保锁类状态和锁类之间的依赖总是正确的。另外，锁类一旦在初次使用时被注册，那么后续就会一直存在，所有它的具体实例都会关联到它。

**锁的几个状态**：

- ever held in STATE context –> 该锁曾在STATE上下文被持有过
- ever head as readlock in STATE context –> 该锁曾在STATE上下文被以读锁形式持有过
- ever head with STATE enabled –> 该锁曾在启用STATE的情况下被持有过
- ever head as readlock with STATE enabled –> 该锁曾在启用STATE的情况下被以读锁形式持有过

&nbsp;

## 5、Lockdep 检查规则

**单锁状态规则如下**： （1）一个软中断不安全的锁类也是硬中断不安全的锁类。

（2）任何一个锁类，不可能同时是硬中断安全的和硬中断不安全的，也不可能同时是软中断安全的和软中断不安全的。也就是说：硬中断安全和硬中断不安全是互斥的，软中断安全和软中断不安全也是互斥的。

**多锁依赖规则如下**： （1）同一个锁类不能被获取两次，否则可能导致递归死锁（AA死锁）。

（2）不能以不同顺序获取两个锁类，否则导致AB-BA死锁。

（3）不允许在获取硬中断安全的锁类之后获取硬中断不安全的锁类。

（4）不允许在获取软中断安全的锁类之后获取软中断不安全的锁类。

&nbsp;

## 6、输出分析

```bash
# ifconfig wlan0 up
[  152.765951] 
[  152.767477] ============================================
[  152.772802] WARNING: possible recursive locking detected
[  152.778130] 4.19.123 #4 Tainted: G           O     
[  152.783021] --------------------------------------------
[  152.788347] ifconfig/231 is trying to acquire lock:
[  152.793243] c043f769 (pmutex){+.+.}, at: phy_RFSerialRead_8723D+0x30/0x168 [8723ds] ctimer:152793251832, htime:152765938707, wtime:000000000000
[  152.807243] 
[  152.807243] but task is already holding lock:
[  152.813093] 97637552 (pmutex){+.+.}, at: netdev_open+0x64/0xb0 [8723ds] ctimer:152813101541, htime:151310817588, wtime:000000000000
[  152.825872] 
[  152.825872] other info that might help us debug this:
[  152.832415]  Possible unsafe locking scenario:
[  152.832415] 
[  152.838349]        CPU0
[  152.840810]        ----
[  152.843269]   lock(pmutex);
[  152.846082]   lock(pmutex);
[  152.848894] 
[  152.848894]  *** DEADLOCK ***
[  152.848894] 
[  152.854831]  May be due to missing lock nesting notation
[  152.854831] 
[  152.861637] 2 locks held by ifconfig/231:
[  152.865659]  #0: cdd640ad (rtnl_mutex){+.+.}, at: devinet_ioctl+0x118/0x5f8 ctimer:152865670624, htime:151310702505, wtime:000000000000
[  152.877865]  #1: 97637552 (pmutex){+.+.}, at: netdev_open+0x64/0xb0 [8723ds] ctimer:152877875915, htime:151310817588, wtime:000000000000
[  152.891057] 
[  152.891057] stack backtrace:
[  152.895439] CPU: 1 PID: 231 Comm: ifconfig Tainted: G           O      4.19.123 #4
[  152.903022] Hardware name: arobot r8 family
[  152.907245] [<c010f3cc>] (unwind_backtrace) from [<c010bfc4>] (show_stack+0x10/0x14)
[  152.915018] [<c010bfc4>] (show_stack) from [<c065b6ec>] (dump_stack+0xa4/0xd8)
[  152.922268] [<c065b6ec>] (dump_stack) from [<c0169adc>] (__lock_acquire+0x1218/0x129c)
[  152.930209] [<c0169adc>] (__lock_acquire) from [<c016a420>] (lock_acquire+0x150/0x240)
[  152.938151] [<c016a420>] (lock_acquire) from [<c0670f20>] (__mutex_lock+0x7c/0x890)
[  152.945833] [<c0670f20>] (__mutex_lock) from [<c06717ac>] (mutex_lock_interruptible_nested+0x18/0x20)
[  152.955975] [<c06717ac>] (mutex_lock_interruptible_nested) from [<bf0d1ea8>] (phy_RFSerialRead_8723D+0x30/0x168 [8723ds])
[  152.968687] [<bf0d1ea8>] (phy_RFSerialRead_8723D [8723ds]) from [<bf0d205c>] (PHY_QueryRFReg_8723D+0xc/0x24 [8723ds])
[  152.981030] [<bf0d205c>] (PHY_QueryRFReg_8723D [8723ds]) from [<bf0d4e5c>] (rtl8723ds_hal_init+0x28c/0x864 [8723ds])
[  152.993294] [<bf0d4e5c>] (rtl8723ds_hal_init [8723ds]) from [<bf0a8fdc>] (rtw_hal_init+0x30/0x144 [8723ds])
[  153.004763] [<bf0a8fdc>] (rtw_hal_init [8723ds]) from [<bf079fa4>] (_netdev_open+0x8c/0x290 [8723ds])
[  153.015713] [<bf079fa4>] (_netdev_open [8723ds]) from [<bf07a404>] (netdev_open+0x7c/0xb0 [8723ds])
[  153.025646] [<bf07a404>] (netdev_open [8723ds]) from [<c049d2fc>] (__dev_open+0x7c/0xc8)
[  153.033766] [<c049d2fc>] (__dev_open) from [<c049d5d4>] (__dev_change_flags+0x148/0x15c)
[  153.041878] [<c049d5d4>] (__dev_change_flags) from [<c049d600>] (dev_change_flags+0x18/0x48)
[  153.050339] [<c049d600>] (dev_change_flags) from [<c051849c>] (devinet_ioctl+0x304/0x5f8)
[  153.058539] [<c051849c>] (devinet_ioctl) from [<c051ac34>] (inet_ioctl+0x278/0x350)
[  153.066222] [<c051ac34>] (inet_ioctl) from [<c0479128>] (sock_ioctl+0x190/0x50c)
[  153.073647] [<c0479128>] (sock_ioctl) from [<c024ed30>] (vfs_ioctl+0x28/0x3c)
[  153.080808] [<c024ed30>] (vfs_ioctl) from [<c024f574>] (do_vfs_ioctl+0x98/0x96c)
[  153.088229] [<c024f574>] (do_vfs_ioctl) from [<c024fe80>] (ksys_ioctl+0x38/0x54)
[  153.095650] [<c024fe80>] (ksys_ioctl) from [<c0101000>] (ret_fast_syscall+0x0/0x28)
[  153.103321] Exception stack(0xc67f7fa8 to 0xc67f7ff0)
[  153.108395] 7fa0:                   000a88e2 bef75348 00000003 00008914 bef75348 000a88e2
[  153.116594] 7fc0: 000a88e2 bef75348 000946d0 00000036 bef7550c bef75508 bef7570d 00000000
[  153.124788] 7fe0: 000c72e4 bef752e4 0001b528 b6e59166
[  153.130116] 
```

- `WARNING: possible recursive locking detected`：警告信息，表示检测到了可能存在的递归锁

- `ifconfig/231 is trying to acquire lock: c043f769 (pmutex){+.+.}, at: phy_RFSerialRead_8723D+0x30/0x168 [8723ds] ctimer:152793251832, htime:152765938707, wtime:000000000000`：表示`ifconfig`任务正在获取一个`pmutex`锁，但是另一个任务已经拥有了这个锁。这意味着任务`ifconfig/231`正在等待另一个任务释放该锁，但是另一个任务已经持有该锁并且没有释放。如果这种情况继续存在，将可能导致死锁的情况。

- `{+.+.}`：是用来描述Linux内核中锁的状态的符号，也称作锁的标志位或锁标志。它是一个五元素元组 `{<waiter>,<owner>,<depth>,<recursion>,<type>}` 的缩写，分别代表了锁的等待者、拥有者、深度、重入次数和类型。

  具体的含义如下：

  - `+` 表示锁没有被占用或等待。
  - `.` 表示锁正在被占用，但没有等待者。
  - `-` 表示等待锁的任务和占用锁的任务都是同一个线程，这种情况也称为递归锁或可重入锁。

  在 `{+.+.}` 中，第一个 `+` 表示锁没有被占用，第二个 `+` 表示没有任务正在等待该锁。因此，该符号代表锁的当前状态为可用。

  > 在 Linux 内核调试中，报告锁状态通常都使用这种简洁的符号，通过观察锁标志位，可以快速地了解内核锁的状态，诊断性能问题和死锁问题。在调试问题时，通常会使用 `dmesg` 命令来查看内核日志中的锁标志，以确定程序中可能存在的锁问题。

- `WARNING: bad contention detected! ifconfig/231 is trying to contend lock (pmutex) at: [<c067118c>] __mutex_lock+0x2e8/0x890 but there are no locks held`：该警告表示检测到了不良争用的情况，其中一个名为 `ifconfig/231` 的任务试图与一个名为 `pmutex` 的锁进行争用，但是没有其他任务持有该锁。这种情况通常表示存在逻辑问题或者编程错误。

- `WARNING: bad unlock balance detected! ifconfig/231 is trying to release lock (pmutex) at: [<bf0d1f98>] phy_RFSerialRead_8723D+0x120/0x168 [8723ds] but there are no more locks to release!`：这个警告表示锁释放不平衡的情况，也就是说，已经没有锁需要被释放。在Linux内核中，每个锁的释放次数需要与该锁的获取次数相匹配，否则就会出现锁释放不平衡的情况。

  在上面的警告信息中，一个名为`ifconfig/231`的任务试图释放一个名为`pmutex`的锁，在释放锁的代码中，有一个名为`phy_RFSerialRead_8723D`的内核函数正在被执行，但是该函数中却没有需要被释放的锁.

&nbsp;

## 7、推荐文章

\[1\]：https://blog.csdn.net/maybeYoc/article/details/123461933

\[2\]：http://www.lenky.info/archives/2013/04/2253

&nbsp;

<center><b> <font color ="blue">欢迎关注【嵌入式艺术】，董哥原创！</font></b></center>
<div align=center><img src="https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/blog.png" alt="img" width = "60%" height ="10%"/>
</div>
