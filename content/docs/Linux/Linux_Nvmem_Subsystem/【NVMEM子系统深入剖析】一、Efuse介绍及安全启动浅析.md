---
date: '2024-01-18T22:27:35+08:00'
title:       '【NVMEM子系统深入剖析】一、Efuse介绍及安全启动浅析'
description: ""
author:      "Donge"
image:       ""
tags:        ["NVMEM子系统", "NVMEM子系统深入剖析", "Efuse", "安全启动"]
categories:  ["Tech" ]
weight: 1
---

# 【NVMEM子系统深入剖析】一、Efuse介绍及安全启动浅析

## 1、Efuse是什么

`eFuse(electronic fuse)`：电子保险丝，熔丝性的一种器件，属于**一次性可编程存储器**。

之所以成为`eFuse`，因为其原理像电子保险丝一样，`CPU`出厂后，这片`eFuse`空间内所有比特全为1，如果向一位比特写入0，那么就彻底烧死这个比特了，再也无法改变它的值，也就是再也回不去 1 了。

> 一般`OEM`从`CPU`厂商购买芯片后，一般都要烧写`eFuse`，用于标识自己公司的版本信息，运行模式等相关信息。
>
> 同时，由于其**一次性编程**的特性，我们又将其用在`Secure Boot`安全启动中。

&nbsp;

## 2、OTP是什么

> 了解完`eFuse`后，我们就顺便了解一下`OTP`

`OTP(One Time Programmable)`是反熔丝的一种器件，就是说，当`OTP`存储单元未击穿时，它的逻辑状态为`0`；当击穿时，它的逻辑状态为`1`，也属于**一次性可编程存储器**。

**它的物理状态和逻辑状态正好和`eFuse`相反！**

![img](https://img-blog.csdnimg.cn/img_convert/abd0b273ba06e74bf7e75322b813dfe1.png)

**两者区别如下**：

- 从成本上讲，`eFuse`器件基本上是各个`Foundry`厂自己提供，因此通常意味着免费或者很少的费用，而`OTP`器件则通常是第三方`IP`厂家提供，这就要收费。
- 从器件面积上讲，eFuse的cell的面积更大，所以仅仅有小容量的器件可以考虑。当然如果需要大容量的，也可以多个eFuse Macro拼接，但是这意味着芯片面积的增加，成本也会增加；OTP的cell面积很小，所有相对来讲，可以提供更大容量的Macro可供使用。

- `OTP` 比 `eFuse` 安全性更好，`eFuse`的编程位可以通过电子显微镜看到，因此其存储的内容可以被轻易破解，但`OTP`在显微镜下无法区分编程位和未编程位，因此无法读取数据。
- `eFuse`默认导通，存储的是"1"，而`OTP`默认是断开，存储的是"0"，因此`OTP`的功耗也较`eFuse`小，面积也较`eFuse`小。

&nbsp;

## 3、什么是Secure Boot

> 上面我们也了解过了，`efuse`主要用于记录一些`OEM`的产品信息，并且也会用于安全启动，那么安全启动是什么，为什么要做安全启动？

安全启动`Secure Boot`，其主要目的是：**以限制消费者能力，防止消费者从软硬件层面，对产品的部分关键系统进行读写，调试等高级权限，达到对产品的商业保密，知识产权的保护。**

**安全启动的安全模型是建立在消费者是攻击者的假设之上**，一般常见的操作有：

- 刷机安装自定义的操作系统
- 绕过厂家封闭的支付平台
- 绕过系统保护，复制厂家保护的数字产品。

**除此之外呢，有的比较专业的消费者，还可以**：

- 使用数字示波器监听 `CPU` 和 `RAM` 、`eMMC` 之间的数据传输来读取非常底层的数据传输
- 而且像 `eMMC` 这种芯片通常都是业界标准化的，攻击者甚至可以把芯片拆下来，然后用市面上现成的通用 `eMMC` 编程工具来读写上面的内容。

![img](https://pic3.zhimg.com/80/v2-8f198e2693ecd4de2230f6b811c4dc52_720w.webp)

安全启动等级也有一个上限：这个上限通常是认为攻击者不至于能够剥离芯片的封装，然后用电子显微镜等纳米级别精度的显像设备来逆向芯片的内部结构。

简单来说：**能成功攻破芯片安全机制的一次性投资成本至少需要在十万美元以上才可以认为是安全的。**

&nbsp;

## 4、CPU内部安全机制

![img](https://pic2.zhimg.com/80/v2-d34291945629ea974d0254936616e541_720w.webp)

### 4.1 bootROM

`BootROM`是集成在`CPU`芯片的一个`ROM`空间，其主要用于存放一小段可执行程序，出厂的时候被烧录进去写死，不可修改。

`CPU`在通电之后，执行的第一条程序就在`BootROM`，用于初始化`Secure Boot`安全机制，加载`Secure Boot Key`密钥，从 存储介质中加载并验证 **First Stage Bootloader（FSBL）**；最后跳转进 FSBL 中。

&nbsp;

### 4.2 iRAM

为了避免使用外部的`RAM`，支持`Secure Boot`的`CPU`都会内置一块很小的`RAM`，通常只有 16KB 到 64KB ，我们称之为 **iRAM**。

这块 `iRAM` 上的空间非常宝贵，`bootROM` 一般会用 `4KB` 的 `iRAM` 作为它的堆栈。`FSBL` 也会被直接加载到 `iRAM` 上执行。

&nbsp;

### 4.3 eFUSE

如上面所述，在`Secure Boot`中存放的是**根密钥**，用于安全启动的验证。

- 一般有两种根密钥：一个是加密解密用的**对称密钥 Secure Boot Key**，一般是 **AES 128** 的，每台设备都是随机生成不一样的；

- 另一个是一个 **Secure Boot Signing Key 公钥**，一般用的 **RSA** 或 **ECC**，这个是每个 `OEM` 自己生成的，每台设备用的都一样，有些芯片会存公钥的 `Hash` 来减少 `eFUSE` 的空间使用。

&nbsp;

### 4.5 Security Engine

有些 CPU 中还会有一个专门负责加密解密的模块，我们称为 **Security Engine**。这个模块通常会有若干个**密钥槽（Keyslots）**，可以通过寄存器将密钥加载到任意一个 `Keyslot` 当中，通过寄存器操作 `DMA` 读写，可以使用 `Keyslot` 中的密钥对数据进行加密、解密、签名、`HMAC`、随机数生成等操作.

&nbsp;

### 4.6 First Stage Bootloader（FSBL）

`FSBL` 的作用是初始化 `PCB` 板上的其他硬件设备，给外部 `RAM` 映射内存空间，从 外部存储介质中加载验证并执行接下来的启动程序。

&nbsp;

### 4.7 根信任建立

1. `CPU`上电后执行`Boot ROM`的程序，其这一小段程序用于初始化`RAM`，并加载`Efuse`上的内容，判断其所处的运行模式是不是生产模式。
2. 如果在生产模式，开启`Secure Boot`功能，把`Efuse`上保存的`Secure Boot Key`加载到`Security Engine`加密模块中处理。
3. 从外部存储介质中加载`FSBL`，`FSBL`里面会有一个数字签名和公钥证书，**bootROM** 会验证这个签名的合法性，以及根证书的 `Hash` 是否和 `eFUSE` 中的 `Signing Key` 的 `Hash` 相同。

4. 如果验证通过，说明 `FSBL` 的的确确是 `OEM` 正式发布的，没有受到过篡改。
5. 然后`bootROM` 就会跳转到 `FSBL` 执行接下来的启动程序。

&nbsp;

## 5、参考文章

[1]：https://zhuanlan.zhihu.com/p/540171344

[2]：https://blog.csdn.net/phenixyf/article/details/125675637

&nbsp;



<center><b> <font color ="blue">欢迎关注【嵌入式艺术】，董哥原创！</font></b></center>
<div align=center><img src="https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/blog.png" alt="img" width = "60%" height ="10%"/>
</div>
