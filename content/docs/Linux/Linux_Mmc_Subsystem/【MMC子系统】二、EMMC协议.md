---
date: '2024-01-19T21:14:30+08:00'
title:       '【MMC子系统】二、EMMC协议'
description: ""
author:      "Donge"
image:       ""
tags:        ["MMC子系统", "MMC/SD/SDIO", "Linux驱动开发"]
categories:  ["Tech" ]
weight: 2
---

# 【MMC子系统】 二、EMMC协议

## 1、前言

在上一节，我们知道`EMMC`、`SD`、`SDIO`三种规范都是在`MMC`规范之上发展而来，协议相差不大，所以`Linux Kernel`才能使用`MMC`子系统来统一管理！

下面，我们以`MMC`协议为例，来了解一下相关协议!

&nbsp;

## 2、EMMC基本了解

### 2.1 物理线路

![Card Concept(eMMC)](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/202210312033341.gif)

![image-20231025163714473](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/image-20231025163714473.png)

| 物理接口 | 接口含义                                                     |
| -------- | ------------------------------------------------------------ |
| CLK      | 时钟线，此信号的每一周期控制**命令线**上的 1 bit 传输，以及所有**数据线**上 1 bit（1x） 或 2 bit（2x）传输。 |
| CMD      | 命令线，此信号是双向命令通道，用于设备初始化和命令传输。CMD信号有两种工 作模式：用于初始化模式**开漏模式**和快速命令传输**推拉模式**。 |
| DAT0-7   | 这些是双向的数据通道。DAT 信号以**推拉模式**工作。缺省状态，只有DAT0处于推拉模式，DAT1-7处于上拉（内含上拉），进入4bit后，DAT0-3处于推拉 |

&nbsp;

### 2.2 EMMC相关寄存器了解

![image-20220215111031546](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/202210312033046.png)

&nbsp;

### 2.3 其他特性了解

- **读写模式**：单块读写，多块读写

- **寻址方式**：字节寻址和扇区寻址，字节寻址允许最大2GB，容量超过2GB的，使用扇区（512B）寻址

- **电压模式**：支持高电压和双电压模式

- **支持增强分区模式等**

&nbsp;

## 3、总线协议

### 3.1 基础了解

- **命令**：启动一种操作的Token，命令从主机发往设备，在CMD线路上串行传输。
- **应答**：从设备发往主机作为对上一命令的回答的Token，在CMD线路上串行传输。
- **数据**：在主从机之间双向传输，总线宽度可以是1-bit（缺省）、4-bit 和 8-bit

&nbsp;

### 3.2 命令格式

![image-20220215112109330](https://img-blog.csdnimg.cn/img_convert/e4f540b09494fc3b1f185ab8d34d09a1.png)

每一个Token，都是由一个**起始位**（’0’）前导，以一个停止位（’1’）终止。**总长度是 48 比特**。每一个 Token 都用**CRC**保护，因此可以检测到传输错误，可重复操作。

![在这里插入图片描述](https://img-blog.csdnimg.cn/e4a7558a097f4e9286a51dcd9f39c7d7.png?x-oss-process=image/watermark,type_d3F5LXplbmhlaQ,shadow_50,text_Q1NETiBA5Y2Q5LiA5Y2B5LqM55S75Y2Q,size_20,color_FFFFFF,t_70,g_se,x_16)

![image-20220215114113034](https://img-blog.csdnimg.cn/img_convert/a1f0da4989de074a495183edc43f1b8b.png)

`命令索引`：也就是前面CMDX的0，1，2，3等命令编号。

`命令参数`：有些命令需要参数，例如地址信息等。

&nbsp;

### 3.3 命令格式

① 无应答广播命令（bc）

② 有应答广播命令（bcr）

③ 点对点寻址命令（ac），无DAT数据

④ 寻址数据传输命令（adtc），有DAT数据

&nbsp;

### 3.4 应答格式

所有的应答均通过命令线CMD发送，编码的长度取决于应答类型，应答`Token`类型有有 5 种编码方案，分别为R1、R2、R3、R4、R5。`Token` 长度是 48 或 136 比特。

#### ① R1（正常应答类型）

![image-20220221104224360](https://img-blog.csdnimg.cn/img_convert/a04c2a4f1c93ae92cda56f0a68d9d03d.png)

编码长度`48bit`，`bits 45:40` 表示应答相对的命令索引，`bit 8:39`表示欲发送设备的状态信息。

&nbsp;

#### ② R2（CID CSD寄存器）

![image-20220221104552038](https://img-blog.csdnimg.cn/img_convert/d25af5c7e2b89cd59bd3ed5bc411ed05.png)

编码长度`136bit`，`CID`寄存器的内容，作为对`CMD2`和`CMD10`的应答发送。`CSD`寄存器内容作为对`CMD9`应答发送。并且`CID`和`CSD`寄存器只有`bit 127:1`被发送。

&nbsp;

#### ③ R3（OCR寄存器）

![image-20220221104728934](https://img-blog.csdnimg.cn/img_convert/187795d916f52eb48be00c8d1798e9fa.png)

编码长度`48bit`，`OCR`寄存器作为对`CMD1`的应答发送。

&nbsp;

#### ④ R4（快速I/O）

![image-20220221104846382](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/202210312035968.png)

编码长度`48bit`，参数域包含了被寻址设备的`RCA`、要读写的寄存器地址和内容。

&nbsp;

#### ⑤ R5（中断请求）

![image-20220221105026759](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/202210312035064.png)

编码长度`48bit`，如果应答是主机生成的，参数的RCA应为0。

&nbsp;

## 4、工作模式

> 主机和设备之间的通信，都由主机控制发起，主机发送命令，引起设备的应答。

**EMMC工作模式也定义了5种**：

- **引导模式**：使设备处于引导状态
- **设备识别模式**：引导模式结束，设备再次模式下，接受`SET_RCA`命令，进行识别设备。
- **数据传输模式**：分配`RCA`后，设备进入数据传输模式，准备数据通信
- **中断模式**：主机与设备同时进入，无数据传输，只允许消息来自主机或从机的中断请求
- **非活动模式**：如果设备工作电压范围和访问模式无效，则进入非活动模式。

![image-20231025164858180](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/image-20231025164858180.png)



> 每一种模式，都有其各自的特点，我们主要来了解一下设备识别过程和数据传输过程。

&nbsp;

> 更多干货可见：[高级工程师聚集地](https://t.zsxq.com/0eUcTOhdO)，助力大家更上一层楼！

&nbsp;

### 4.1 设备识别模式

![image-20220222110331024](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/6292e9b455574f80e056b1e1fbd345c6.png)

> 乍一看图，肯定大家都一脸懵逼，不仔细分析协议，单看图还是有一定理解难度的。

总体来说，设备识别模式下，主机要想识别到卡，主要步骤有如下几步：

- **复位设备**
- **验证工作电压及访问模式**
- **识别设备并分配相对设备地址`RCA`**

- **使设备进入数据传输模式**

&nbsp;

#### 4.1.1 复位

**EMMC控制器**通过发送`CMD0`，参数为`0x00000000`，使设备进入`Idle`状态。

同时，为了向后兼容，在除`Inactive`的任何状态，接收 非`0XFFFFFFFA`或`0XF0F0F0F0`的参数，都作为`CMD0`。



#### 4.1.2 验证工作电压及访问模式

**EMMC控制器**通过发送`CMD1`，参数为`OCR寄存器`，该寄存器种包含了`2bit`的存储器访问模式。

![image-20231025164950622](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/image-20231025164950622.png)

如上，`bit[30：29]`表示访问模式，通过`CMD1`发送该数据目的是向存储器同步寻址类型。

**EMMC设备**同时也应以固定模式`0x00FF8080` 或 `0x40FF8080`（如果设备忙）、`0x80FF8080`（容量小于等于 2GB）或 `0xC0FF8080`（容量大于 2GB）应答。

同时，`bit31`用来判忙，如果为1，说明**EMMC设备**仍然处于复位过程中，主机也同时重复发送`CMD1`来确保该忙位清除。



#### 4.1.3 识别设备分配RCA

通过`CMD1`进行检查后，不符合的设备就进入了`Inactive`状态。而符合的设备就进入了`Ready`状态。

进而，**EMMC控制器**发送`CMD2`，请求符合要求的设备发送**唯一设备标识**`CID`号。`CID`号对于每一张卡，都是唯一的。

发送`CID`成功的设备，就进入到了`Identification`状态。

进而，**EMMC控制器**发送`CMD3`，赋予设备一个相对设备地址`RCA`，从设备一旦接收到`RCA`，设备就变为`Stand-by`状态，即**空闲态**。

&nbsp;

### 4.2 数据传输过程

![image-20220222113633761](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/99b99dc63ff70034ecf65be946033cf0.png)

分配完`RCA`后，从设备接收到`RCA`，立即处于`stand-by`状态时，`CMD`和`DAT`线路，均变为推拉模式。

&nbsp;

#### 4.2.1 获取CSD寄存器信息

`CMD9`：主机发送该命令，以获取设备专用寄存器`CSD`的数据，如块长度，存储容量，最大时钟速率等。

&nbsp;

#### 4.2.2 获取CID寄存器信息

`CMD10`：主机发送该命令，以获取设备专用寄存器`CID`的数据，获取设备识别号。

&nbsp;

#### 4.2.3 切换为Transfer状态

`CMD7`：主机发送该命令，选定该设备，使其切换到发送数据状态。

&nbsp;

#### 4.2.4 查看EXT_CSD扩展寄存器

`CMD8`：主机发送该命令，设备作为数据块发送其 `EXT_CSD`寄存器的数据，设备将数据作为一个512字节的数据块发送。

&nbsp;

#### 4.2.5 修改EXT_CSD扩展寄存器的值

`CMD6`：主机发送该命令，用于切换工作模式，或者修改`EXT_CSD`寄存器。

`CMD6`，这个命令，参数的设置有很大讲究呢！

&nbsp;

`[31:26]`：正如手册所写，直接设置为0

`[25:24]`：访问模式选择，那么访问模式有哪几种呢？

![image-20220224133752283](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/32918843a9efb0a9ccb91ef0fc7fd9e8.png)

如果 `SWITCH` 命令用于更换命令集（`[25:24]为00`），Index 和 Value 域被忽略（`[23:16]、[15:8]忽略`），且 EXT_CSD 不会被写。

如果 `SWITCH`命令用于写 EXT_CSD寄存器，Cmd Set 域被忽略`[2:0] 忽略`，命令集保持不变。

`[23:16]`：索引，指的是`EXT_CSD`寄存器中，所要修改字节的索引。

`[15:8]`：要写入的值

`[2:0]`：命令集选择，命令集有如下几种类别，相关手册可以查阅。

&nbsp;

**举个栗子**：

如果我们想要操作总线长度，我们该怎么修改呢？

`CMD6`命令，发送`args=03B70200`，即可修改。

`03`：代表访问模式为`写字节`

`B7`：转换为十进制183，对应`EXT_CSD`总线宽度模式的字节。

![image-20220224135045096](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/9e1df24065cc170eee8fc74698f8f21d.png)

`02`：设置该字节的值为02，即`8位数据总线`

![image-20220224135119903](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/496db308a84e8e5ba2eae14e094e6382.png)

`00`：写字节访问模式下，该位无效。

&nbsp;

#### 4.2.6 读数据

- **单块读**

`CMD17`：直接发送读命令，参数为要写入的**数据地址信息**，只读一个块。



- **多块读**

`CMD18`：直接发送读命令，参数为要写入的**数据地址信息**，并且一直读下去。

`CMD12`：停止命令，停止传输。

![image-20220224140703465](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/f7007507ceeb03b2a906c96793a5e4b2.png)



#### 4.2.7 写数据

> 确保设备处于发送状态，即主机发送`CMD7`命令

- **单块写**

`CMD24`：直接发送写命令，参数为要写入的**数据地址信息**，只写一个块。



- **多块写**

多块写的模式有两种：

**① 一种是**：设置要传输的数据块的个数，达到个数后，自动停止

`CMD16`：设置要传输的块长度

`CMD25`：开始发送`CMD16`指定长度的数据块，直到达到设置的数据块写入完成。



**②另一种是**：一直传输数据，直到接收停止数据的命令

`CMD25`：开始发送数据块，一直等待数据发送完全

`CMD12`：停止命令，停止传输。

![image-20220224140713849](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/0c1ba6acbca3da4cd7adecb5002db0a9.png)

好啦，到这里我们基本了解了`MMC`的协议，这也有助于我们去分析`EMMC`的框架。

<center><b> <font color ="blue">欢迎关注【嵌入式艺术】，董哥原创！</font></b></center>
<div align=center><img src="https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/blog.png" alt="img" width = "60%" height ="10%"/>
</div>
