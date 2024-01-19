---
date: '2024-01-19T21:43:13+08:00'
title:       '【一文秒懂】Linux设备树详解'
description: ""
author:      "Donge"
image:       ""
tags:        ["Linux设备树详解", "Linux驱动开发基础"]
categories:  ["Tech" ]
weight: 2
---

# 【一文秒懂】Linux设备树详解

## 1、Linux设备树概念

Linux内核是从V2.6开始引入设备树的概念，其起源于`OF:OpenFirmware`， 用于**描述一个硬件平台的硬件资源信息**，这些信息包括：CPU的数量和类别、内存基地址和大小、总线和桥、外设连接、中断控制器和中断使用情况、GPIO控制器和GPIO使用情况、Clock控制器和Clock使用情况等等。

<span style="color: blue;">**官方说明**：</span>

> The "Open Firmware Device Tree", or simply Device Tree (DT), is a data structure and language for describing hardware.
> 
> 设备树是一种数据结构和一种用于描述硬件信息的语言。

**设备树的特点**：

- **实现驱动代码与设备硬件信息相分离**。
- 通过被`bootloader(uboot)`和`Linux`传递到内核， 内核可以从设备树中获取对应的硬件信息。
- 对于同一SOC的不同主板，只需更换设备树文件即可实现不同主板的无差异支持，而无需更换内核文件，实现了**内核和不同板级硬件数据的拆分**。

![设备树](https://doc.embedfire.com/linux/imx6/quick_start/zh/latest/_images/device_tree001.png)

&nbsp;

## 2、设备树的由来

明白了设备树的概念，不妨思考一下：<span style="color: red;">**为什么要引入设备树？**</span>

在`Linux`内核v2.6版本以前，`ARM`架构用于描述不同的硬件信息的文件都存放在`arch/arm/plat-xxx`和`arch/arm/mach-xxx`文件夹下，如下：

![image-20220802090504275](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/image-20220802090504275.png)

在这些文件内，都是通过手动定义不同的硬件设备，步骤非常繁琐

![image-20220802091036378](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/image-20220802091036378.png)

这样就导致了`Linux`内核代码中充斥着大量的垃圾代码，因为不同的板级他们的硬件信息都不相同，这些都是硬件特有的信息，对内核而言没有任何的意义，但是往往这部分代码特别的多，造成内核的冗余。

<span style="color: blue;">**设备树的引入就是为了解决这个问题**</span>，通过引入设备树，我们可以直接通过它来传递给`Linux`，而不再需要内核中大量的垃圾代码。

&nbsp;

## 3、设备树组成

> 整个设备树牵涉面比较广，即增加了新的用于描述设备硬件信息的文本格式，又增加了编译这个文本的工具，同时还得支持`Bootloader`解析设备树，并将信息传递给内核。

整个设备树包含`DTC（device tree compiler）`，`DTS（device tree source）`和`DTB（device tree blob）`。

![image-20220802091430298](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/image-20220802091430298.png)

- **DTS（device tree source）**

`DTS`是一种`ASCII`文本格式的设备树描述，在`ARM Linux`中，一个`dts`文件对应一个`ARM`的设备，该文件一般放在`arch/arm/boot/dts/`目录中。

![image-20220802091900520](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/image-20220802091900520.png)

> 当然，我们还会看到一些`dtsi`文件，这些文件有什么用呢？
> 
> **Dtsi**：由于一个`SoC`可能对应多个设备（一个SoC可以对应多个产品和电路板），这些.dts文件势必须包含许多共同的部分，Linux内核为了简化，把<span style="color: red;">**SoC公用的部分或者多个设备共同的部分一般提炼为.dtsi**</span>，类似于C语言的头文件。其他的设备对应的.dts就包括这个.dtsi 。

- **DTC（device tree compiler）**

`DTC`是将`.dts`编译为`.dtb`的工具，相当于gcc。

`DTC`的源代码位于内核的`scripts/dtc`目录中， 在`Linux`内核使能了设备树的情况下， 编译内核的时候，工具`DTC`会被编译出来， 对应于`scripts/dtc/Makefile`中`hostprogs-y:=dtc`这一编译目标。

该工具一般在编译内核的时候，默认会自动执行编译操作，<span style="color: red;">**如果我们想单独编译设备树，该怎么办呢？**</span>

> 两条编译命令：

**将dts文件编译为dtb**

```bash
dtc -I dts -O dtb xxx.dtb xxx.dts
```

**将dtb文件反编译为dts**

```bash
dtc -I dtb -O dts xxx.dts xxx.dtb
```

- **DTB（device tree blob）**

dtb文件是.dts 被 DTC 编译后的二进制格式的设备树文件，它由Linux内核解析，也可以被bootloader进行解析。

> 通常在我们为电路板制作NAND、SD启动映像时，会为.dtb文件单独留下一个很小的区域以存放之，之后bootloader在引导内核的过程中，会先读取该.dtb到内存。

<span style="color: blue;">**总之，三者关系如下**：</span>

![image-20220802091438853](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/image-20220802091438853.png)

&nbsp;

## 4、设备树语法

`dts`文件是一种`ASCII`文本格式的设备树描述，它有以下几种特性：

- 每个设备树文件都有一个根节点，每个设备都是一个节点。
    
- 节点间可以嵌套，形成父子关系，这样就可以方便的描述设备间的关系。
    
- 每个设备的属性都用一组key-value对(键值对)来描述。
    
- 每个属性的描述用;结束
    

> 记住上面的几个核心特性，往下看！

### 4.1 数据格式

```dtd
/dts-v1/;

/ {
    node1 {
        a-string-property = "A string";
        a-string-list-property = "first string", "second string";
        // hex is implied in byte arrays. no '0x' prefix is required
        a-byte-data-property = [01 23 34 56];
        child-node1 {
            first-child-property;
            second-child-property = <1>;
            a-string-property = "Hello, world";
        };
        child-node2 {
        };
    };
    node2 {
        an-empty-property;
        a-cell-property = <1 2 3 4>; /* each number (cell) is a uint32 */
        child-node1 {
        };
    };
};
```

- `/`：表示根节点
- `node1`、`node2`：表示根节点下的两个子节点
- `child-node1`、`child-node2`：表示子节点`node1`下的两个子节点
- `a-string-property = "A string";`：字符串属性，用**双引号**表示
- `cell-property = <0xbeef 123 0xabcd1234>;`：32bit的无符号整数，用**尖括号**表示
- `binary-property = [0x01 0x23 0x45 0x67];`：二进制数据用**方括号**表示
- `a-string-list-property = "first string", "second string";`：用**逗号**表示字符串列表

&nbsp;

### 4.2 数据结构

![image-20220805084615794](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/image-20220805084615794.png)

`DeviceTree`的结构非常简单，由两种元素组成：`Node`(节点)和`Property`(属性)。

```dtd
[label:] node-name[@unit-address] {
    [properties definitions]
    [child nodes]
}
```

> 想象一下，一棵大树，每一个树干都认为是一个节点，每一片树叶，想作一个属性！

- **label**：节点的一个标签，可以作为别名
- **node-name**：节点的名称
- **unit-address**：单元地址，也就是控制器的地址
- **properties**：属性名称
- **definitions**：属性的值

&nbsp;

### 4.3 属性介绍

```dtd
/dts-v1/;

/ {
    compatible = "acme,coyotes-revenge";
    #address-cells = <1>;
    #size-cells = <0>;
    cpus {
        cpu@0 {
            compatible = "arm,cortex-a9";
            reg = <0>;
        };
        cpu@1 {
            compatible = "arm,cortex-a9";
            reg = <1>;
        };
    };

    serial@101f0000 {
    	#address-cells = <1>;
    	#size-cells = <1>;
        compatible = "arm,pl011";
        reg = <0x101f0000 0x1000 >;
    };

};

```

#### 4.3.1 基本属性之compatible、name、unit-address

> <span style="color: blue;">**下面几个属性是基本属性**</span>

- `/dts-v1/;`：表示一个`dts`设备树文件
- `/`：表示根节点
- `compatible = "acme,coyotes-revenge";`
    - `compatible`： “兼容性” 属性，这是非常重要的一个属性兼容属性，由该属性值来匹配对应的驱动代码。
    - `"acme,coyotes-revenge"`：该值遵循`"manufacturer,model"`格式`manufacturer`表示芯片厂商，`model`表示驱动名称

> `compatible`是一个字符串列表。列表中的第一个字符串指定节点在表单中表示的确切设备`"<manufacturer>,<model>"`。
> 
> 例如，飞思卡尔 MPC8349 片上系统 (SoC) 有一个串行设备，可实现 National Semiconductor ns16550 寄存器接口。因此，MPC8349 串行设备的 compatible 属性应为：`compatible = "fsl,mpc8349-uart", "ns16550"`. 在这种情况下，`fsl,mpc8349-uart`指定确切的设备，并`ns16550`声明它与 National Semiconductor 16550 UART 的寄存器级兼容。

- `cpus`：表示一个子节点，该子节点下又有两个子节点，分别为`cpu0`和`cpu1`。
- `cpu@0`：遵循`<name>[@<unit-address>`\]格式
    - `<name>`：ascii字符串，表示节点名称
    - `<unit-address>`：单元地址，设备的私有地址，在节点`reg`属性中描述。

#### 4.3.2 寻址属性之address-cells、size-cells、reg、range

> <span style="color: blue;">**下面几个属性与寻址相关的**</span>

- `#address-cells` ：表示`reg`属性中**表示地址字段的单元个数，每个单元32bit**，即用多少个`32bit`单元表示地址信息。
    
- `#size-cells`：表示`reg`属性中**表示长度字段的单元个数，每个单元32bit**，即用多少个`32bit`单元表示长度信息。
    
- `reg`：该属性一般用于**描述设备地址空间资源信息**，一般都是某个外设的寄存器地址范围信息。其式为`reg = <address1 length1 [address2 length2] [address3 length3] ... >`。每个地址值都是一个或多个 32 位整数的列表，称为*单元格*。同样，长度值可以是单元格列表，也可以是空的。
    

&nbsp;

> <span style="color: blue;">**以`cpu`节点为例**：</span>

```dtd
    cpu@0 {
        compatible = "arm,cortex-a9";
        reg = <0>;
    };
```

其`#address-cells=1`表示`reg`属性中描述地址字段，所需`32bit`的单元个数为1，`#size-cells=0`表示`reg`属性中没有表示长度的单元，即`reg=<0>`

&nbsp;

> <span style="color: blue;">**再以`serial`节点为例**：</span>

```dtd
    serial@101f0000 {
    	#address-cells = <1>;
    	#size-cells = <1>;
        compatible = "arm,pl011";
        reg = <0x101f0000 0x1000 >;
    };
```

> <span style="color: red;">**该设备都被分配一个基址，以及被分配区域的大小**</span>

其`#address-cells=1`表示`reg`属性中描述地址字段需要1个`32bit`单元，`#size-cells=1`表示`reg`属性中描述长度字段需要2个单元，即`reg=<0x101f0000 0x1000>`

- `0x101f0000`：表示`serial`的控制器起始地址
- `0x1000`：表示`serial`控制器所占用的大小

&nbsp;

<span style="color: blue;">**地址映射部分还要了解一个属性`<range>`，为什么要引入这个属性呢**？</span>

根节点与根节点的直接子节点，都使用了`CPU`的地址分配空间，但是根节点的非直接子节点，并不会自动实用`CPU`的地址空间，因此需要手动用`<range>`属性分配。

如上述的`serial`节点，属于根节点下的直接子节点，无需手动再次分配地址空间，而下面所述的 `external-bus`节点，其内部的子节点就需要再次分配！

```dtd
/dts-v1/;

/ {
    compatible = "acme,coyotes-revenge";
    #address-cells = <1>;
    #size-cells = <1>;
    ...
    external-bus {
        #address-cells = <2>;
        #size-cells = <1>;
        ranges = <0 0  0x10100000   0x10000     // Chipselect 1, Ethernet
                  1 0  0x10160000   0x10000     // Chipselect 2, i2c controller
                  2 0  0x30000000   0x1000000>; // Chipselect 3, NOR Flash

        ethernet@0,0 {
            compatible = "smc,smc91c111";
            reg = <0 0 0x1000>;
        };

        i2c@1,0 {
            compatible = "acme,a1234-i2c-bus";
            #address-cells = <1>;
            #size-cells = <0>;
            reg = <1 0 0x1000>;
            rtc@58 {
                compatible = "maxim,ds1338";
                reg = <58>;
            };
        };

        flash@2,0 {
            compatible = "samsung,k8f1315ebm", "cfi-flash";
            reg = <2 0 0x4000000>;
        };
    };
};
```

> **该总线使用了不同的寻址方式，分析一下`external-bus`节点**：

- `#address-cells = <2>`：用两个单元表示地址
- `#size-cells = <1>`：用一个单元表示长度
- `reg = <0 0 0x1000>`：第一个`0`表示片选号，第二个`0`表示基于片选的偏移，第三个表示偏移的大小

&nbsp;

**这种抽象的表示，如何映射到`CPU`地址区域呢？\`\`<range>\`属性来帮助！</range>**

```dtd
   ranges = <0 0  0x10100000   0x10000     // Chipselect 1, Ethernet
             1 0  0x10160000   0x10000     // Chipselect 2, i2c controller
             2 0  0x30000000   0x1000000>; // Chipselect 3, NOR Flash
```

**range**：表示了不同设备的地址空间范围，表中的每一项都是一个元组，包含**子地址、父地址以及子地址空间中区域的大小**，这三个字段。

- **子地址字段**：由子节点的`#address-cells`决定，如前面的`0 0`、`0 1`
- **父地址字段**：由父节点的`#address-cells`决定，如`0x10100000`、`0x10160000`
- **子地址空间字段**：描述子节点的空间大小，由父节点的`#size-cells`决定，如`0x10000`、`0x10000`

经过映射后，总线的地址映射如下：

> - Offset 0 from chip select 0 is mapped to address range 0x10100000..0x1010ffff
> - Offset 0 from chip select 1 is mapped to address range 0x10160000..0x1016ffff
> - Offset 0 from chip select 2 is mapped to address range 0x30000000..0x30ffffff

#### 4.3.3 中断属性之interrupt-controller、interrupt-cells、interrupt-parent、interrupts

```dtd
/dts-v1/;

/ {
    compatible = "acme,coyotes-revenge";
    #address-cells = <1>;
    #size-cells = <1>;
    interrupt-parent = <&intc>;

    cpus {
        #address-cells = <1>;
        #size-cells = <0>;
        cpu@0 {
            compatible = "arm,cortex-a9";
            reg = <0>;
        };
        cpu@1 {
            compatible = "arm,cortex-a9";
            reg = <1>;
        };
    };

    serial@101f0000 {
        compatible = "arm,pl011";
        reg = <0x101f0000 0x1000 >;
        interrupts = < 1 0 >;
    };

    intc: interrupt-controller@10140000 {
        compatible = "arm,pl190";
        reg = <0x10140000 0x1000 >;
        interrupt-controller;
        #interrupt-cells = <2>;
    };
};
```

如上

- `interrupt-controller`：声明一个节点是接收中断信号的设备，也就是中断控制器
- `#interrupt-cells`：`interrupt-controller`节点下的一个属性，表明中断标识符用多少个单元表示
- `interrupt-parent`：设备节点中的一个属性，选择哪个中断控制器
- `interrupts`：设备节点的一个属性，中断标识符列表，其单元个数取决于`#interrupt-cells`

根据设备树，我们了解到：

- 该机器有一个中断控制器`interrupt-controller@10140000`
- `intc`标签，为中断控制器的别名，方便引用
- `#interrupt-cells = <2>;`：中断标识符用两个单元格表示
- `interrupt-parent = <&intc>;`：选择中断控制器
- `interrupts = < 1 0 >;`：表示一个中断，第一个值用于表明**中断线编号**，第二个值表明中断类型，如高电平，低电平，跳变沿等

#### 4.3.4 其他属性之aliases、chosen

```dtd
    aliases {
        ethernet0 = &eth0;
        serial0 = &serial0;
    };
```

`aliases`：正如其名，别名属性，使用方式：`property = &label;`

&nbsp;

```
    chosen {
        bootargs = "root=/dev/nfs rw nfsroot=192.168.1.1 console=ttyS0,115200";
    };
```

`chosen`：该属性并不表示一个真实的设备，但是提供一个空间，用于传输固件和`Linux`之间的数据，像启动参数，

&nbsp;

## 5、设备树的加载流程

> 我们知道，`dts`文件经过`dtc`工具编译为`dtb`，内核加载并解析`dtb`文件，最终获得设备树的信息。

<span style="color: red;">**那么`Linux`如何加载\`\`dtb文件，并生成对应节点的呢？**</span>

&nbsp;

### 5.1 设备树地址设置

我们一般通过`Bootloader`引导启动`Kernel`，在启动`Kernel`之前，`Bootloader`必须将`dtb`文件的首地址传输给`Kernel`，以供使用。

1.  `Bootloader`将`dtb`二进制文件的起始地址写入`r2`寄存器中
2.  `Kernel`在第一个启动文件`head.S/head-common.S`中，读取`r2`寄存器中的值，获取`dtb`文件起始地址
3.  跳转入口函数`start_kernel`执行C语言代码

&nbsp;

### 5.2 获取设备树中的平台信息——machine\_desc

在`dts`文件中，在根节点中有一个compatible属性，该属性的值是一系列的字符串，比如`compatible = “samsung，smdk2440”“samsung,smdk2410,samsung，smdk24xx”;`，该属性就是告诉内核要选择什么样的`machine_desc`，因为`machine_desc`结构体中有一个`dt_compat`成员，该成员表示`machine_desc`支持哪些单板，所以内核会把`compatible`中的字符串与`dt_compat`进行依次比较。

```C
start_kernel // init/main.c
    setup_arch(&command_line);  // arch/arm/kernel/setup.c
        mdesc = setup_machine_fdt(__atags_pointer);  // arch/arm/kernel/devtree.c
                    early_init_dt_verify(phys_to_virt(dt_phys)  // 判断是否有效的dtb, drivers/of/ftd.c
                                    initial_boot_params = params;
                    mdesc = of_flat_dt_match_machine(mdesc_best, arch_get_next_mach);  // 找到最匹配的machine_desc, drivers/of/ftd.c
                                    while ((data = get_next_compat(&compat))) {
                                        score = of_flat_dt_match(dt_root, compat);
                                        if (score > 0 && score < best_score) {
                                            best_data = data;
                                            best_score = score;
                                        }
                                    }
                    
        machine_desc = mdesc;
```

&nbsp;

### 5.3 获取设备树的配置信息

> 在前面，我们也知道设备树中的`chosen`属性，用于传输固件和`Linux`之间的数据，包含一些启动参数，那么我们该如何解析出来呢？

1.  `/chosen`节点中`bootargs`属性的值, 存入全局变量： `boot_command_line`
2.  确定根节点的这2个属性的值: `#address-cells`, `#size-cells`
3.  存入全局变量: `dt_root_addr_cells`, `dt_root_size_cells`
4.  解析`/memory`中的`reg`属性, 提取出`"base, size"`, 最终调用`memblock_add(base, size);`

&nbsp;

### 5.4 设备树节点解析

**dtb文件会在内存中一直存在着，不会被内核或者应用程序占用，我们需要使用的时候可以直接使用dtb文件。dtb文件的内容会被解析生成多个device\_node，然后这些device\_node构成一棵树, 根节点为: of\_root**

> **每一个节点都以TAG(FDT\_BEGIN\_NODE, 0x00000001)开始, 节点内部可以嵌套其他节点,  
> 每一个属性都以TAG(FDT\_PROP, 0x00000003)开始**

&nbsp;

- <span style="color: red;">**设备树中的每一个节点，都会被转换为`device_node`结构体**</span>

```c
 struct device_node {
            const char *name;  // 来自节点中的name属性, 如果没有该属性, 则设为"NULL"
            const char *type;  // 来自节点中的device_type属性, 如果没有该属性, 则设为"NULL"
            phandle phandle;
            const char *full_name;  // 节点的名字, node-name[@unit-address]
            struct fwnode_handle fwnode;

            struct  property *properties;  // 节点的属性
            struct  property *deadprops;    /* removed properties */
            struct  device_node *parent;   // 节点的父亲
            struct  device_node *child;    // 节点的孩子(子节点)
            struct  device_node *sibling;  // 节点的兄弟(同级节点)
        #if defined(CONFIG_OF_KOBJ)
            struct  kobject kobj;
        #endif
            unsigned long _flags;
            void    *data;
        #if defined(CONFIG_SPARC)
            const char *path_component_name;
            unsigned int unique_id;
            struct of_irq_controller *irq_trans;
        #endif
        };

```

&nbsp;

- <span style="color: red;">**将`device_node`转换为`platform_device`**</span>

> **那么多的device\_node，哪些会被转化为platform\_device呢？**
> 
> 1.  根节点下的子节点，且该子节点必须包含compatible属性；
> 2.  如果一个节点的`compatile`属性含有这些特殊的值(“simple-bus”,“simple-mfd”,“isa”,“arm,amba-bus”)之一，那么它的子结点(需含compatile属性)也可以转换为platform\_device。

```C
struct platform_device {
    const char	*name;
    int		id;
    bool		id_auto;
    struct device	dev;
    u32		num_resources;
    struct resource	*resource;

    const struct platform_device_id	*id_entry;
    char *driver_override; /* Driver name to force a match */

    /* MFD cell pointer */
    struct mfd_cell *mfd_cell;

    /* arch specific additions */
    struct pdev_archdata	archdata;
};
```

转换完成之后，

- 设备树中的`reg/irq`等属性，都存放在了`platform_device->resource`结构体中
- 设备树中的其他属性，都存在在了`platform_device.dev->of_node`结构体中

&nbsp;

- <span style="color: red;">**C代码获取设备树属性**</span>

转换完成之后，内核提供了一些`API`来直接获取设备树中对应的属性。如：

- `of_property_read_u32_index`：获取设备树中某个属性的值
- `of_property_read_string`：获取设备树中某个属性的字符串的值
- `of_get_address`：获取设备树中的某个节点的地址信息

**整体总结下来，有几个类别**：

```C
a. 处理DTB
of_fdt.h // dtb文件的相关操作函数, 我们一般用不到, 因为dtb文件在内核中已经被转换为device_node树(它更易于使用)

b. 处理device_node
of.h // 提供设备树的一般处理函数, 比如 of_property_read_u32(读取某个属性的u32值), of_get_child_count(获取某个device_node的子节点数)
of_address.h // 地址相关的函数, 比如 of_get_address(获得reg属性中的addr, size值)
of_match_device(从matches数组中取出与当前设备最匹配的一项)
of_dma.h // 设备树中DMA相关属性的函数
of_gpio.h // GPIO相关的函数
of_graph.h // GPU相关驱动中用到的函数, 从设备树中获得GPU信息
of_iommu.h // 很少用到
of_irq.h // 中断相关的函数
of_mdio.h // MDIO (Ethernet PHY) API
of_net.h // OF helpers for network devices.
of_pci.h // PCI相关函数
of_pdt.h // 很少用到
of_reserved_mem.h // reserved_mem的相关函数

c. 处理 platform_device
of_platform.h // 把device_node转换为platform_device时用到的函数,
// 比如of_device_alloc(根据device_node分配设置platform_device),
// of_find_device_by_node (根据device_node查找到platform_device),
// of_platform_bus_probe (处理device_node及它的子节点)
of_device.h // 设备相关的函数, 比如 of_match_device

```

&nbsp;

上述总结下来，流程为<span style="color: red;">**dts->dtb->device\_node->platform\_device**</span>

![image-20220805090415993](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/image-20220805090415993.png)

&nbsp;

## 6、设备树调试

- **查看原始的`dtb`文件**

```bash
ls /sys/firmware/fdt 
hexdump -C /sys/firmware/fdt
```

&nbsp;

- **查看设备树信息**

```bash
ls /sys/firmware/devicetree
ls /proc/device-tree
```

> 以目录结构程现的dtb文件, 根节点对应`base`目录, 每一个节点对应一个目录, 每一个属性对应一个文件
> 
> `/proc/device-tree` 是链接文件, 指向 `/sys/firmware/devicetree/base`

&nbsp;

- **查看所有硬件信息**

```bash
ls /sys/devices/platform 
```

> 系统中所有的platform\_device, 有来自设备树的, 也有来有.c文件中注册的。

&nbsp;

## 7\. 参考地址

\[1\]：https://elinux.org/Device_Tree_Usage

\[2\]：https://www.kernel.org/doc/Documentation/devicetree/usage-model.txt

\[3\]：https://blog.csdn.net/zj82448191/article/details/109195364


<center><b> <font color ="blue">欢迎关注【嵌入式艺术】，董哥原创！</font></b></center>
<div align=center><img src="https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/blog.png" alt="img" width = "60%" height ="10%"/>
</div>
