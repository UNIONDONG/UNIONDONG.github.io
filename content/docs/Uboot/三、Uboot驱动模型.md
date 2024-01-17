---
date: '2024-01-17T21:28:52+08:00'
title:       '三、Uboot驱动模型'
description: ""
author:      "Donge"
image:       ""
tags:        ["Uboot开发详解"]
categories:  ["Tech" ]
weight: 3
---

# 三、Uboot驱动模型

![Uboot驱动模型](https://cdn.jsdelivr.net/gh/UNIONDONG/Get_Pic_Url/Media202201221422561.jpg)

> 全文耗时一周，精心汇总，希望对大家有所帮助，感觉可以的点赞，关注，不迷路，后续还有更多干货！
>
> 看文章前，答应我，静下心来，慢慢品！

## 3.1、什么是Uboot驱动模型

学过Linux的朋友基本都知道Linux的设备驱动模型，Uboot根据Linux的驱动模型架构，也引入了Uboot的驱动模型（**driver model ：DM**）。

**这种驱动模型为驱动的定义和访问接口提供了统一的方法。**提高了驱动之间的兼容性以及访问的标准型，uboot驱动模型和kernel中的设备驱动模型类似。

## 3.2、为什么要有驱动模型呢

> 无论是Linux还是Uboot，一个新对象的产生必定有其要解决的问题，驱动模型也不例外！

- **提高代码的可重用性**：为了能够使代码在不同硬件平台，不同体系架构下运行，必须要最大限度的提高代码的可重用性。
- **高内聚，低耦合**：分层的思想也是为了达到这一目标，低耦合体现在对外提供统一的抽象访问接口，高内聚将相关度紧密的集中抽象实现。
- **便于管理**：在不断发展过程中，硬件设备越来越多，驱动程序也越来越多，为了更好的管理驱动，也需要一套优秀的驱动架构！

## 3.3、如何使用uboot的DM模型

> DM模型的使用，可以通过menuconfig来配置。
>
> `make menuconfig`

### ①：menuconfig配置全局DM模型

```
Device Drivers ->  Generic Driver Options -> Enable Driver Model  
```

通过上面的路径来打开`Driver Model`模型，最终配置在`.config`文件中，`CONFIG_DM=y`

### ②：指定某个驱动的DM模型

全局的DM模型打开后，我们对于不通的驱动模块，使能或者失能DM功能。如MMC驱动为例：

```
Device Drivers -> MMC Host controller Support -> Enable MMC controllers using Driver Model
```

最终反映在`.config`文件中的`CONFIG_DM_MMC=y`

在对应的驱动中，可以看到判断`#if !CONFIG_IS_ENABLED(DM_MMC)`，来判断是否打开DM驱动模型。

在管理驱动的`Makefile`文件中，也能看到`obj-$(CONFIG_$(SPL_)DM_MMC) += mmc-uclass.o`，来判断是否将驱动模型加入到编译选项中。

总之，我们要打开DM模型，最后反映在几个配置信息上：

- `CONFIG_DM=y`，全局DM模型打开
- `CONFIG_DM_XXX=y`，某个驱动的DM模型的打开
- 可以通过`Kconifg`、`Makefile`来查看对应宏的编译情况

![img](https://i.loli.net/2021/12/02/dXOn3fe91FZQWzq.jpg)

## 3.4、DM模型数据结构

要想了解DM模型整套驱动框架，我们必须先了解它的一砖一瓦！也就是组成驱动框架的各个数据结构。

### ① global_data

```c
typedef struct global_data {
...
#ifdef CONFIG_DM
    struct udevice	*dm_root;	/* Root instance for Driver Model */
    struct udevice	*dm_root_f;	/* Pre-relocation root instance */
    struct list_head uclass_root;	/* Head of core tree */
#endif
...
}
```

`global_data`，管理着整个Uboot的全局变量，其中`dm_root`，`dm_root_f`，`uclass_root`用来管理整个DM模型。这几个变量代表什么意思呢？

- `dm_root`：DM模型的根设备
- `dm_root_f`：重定向前的根设备
- `uclass_root`：`uclass`链表的头

这几个变量，最终要的作用就是：管理整个模型中的`udevice`设备信息和`uclass`驱动类。

### ② uclass

我们首先看一下`uclass`这个结构体

```c
/**
 * struct uclass - a U-Boot drive class, collecting together similar drivers
 *
 * A uclass provides an interface to a particular function, which is
 * implemented by one or more drivers. Every driver belongs to a uclass even
 * if it is the only driver in that uclass. An example uclass is GPIO, which
 * provides the ability to change read inputs, set and clear outputs, etc.
 * There may be drivers for on-chip SoC GPIO banks, I2C GPIO expanders and
 * PMIC IO lines, all made available in a unified way through the uclass.
 *
 * @priv: Private data for this uclass
 * @uc_drv: The driver for the uclass itself, not to be confused with a
 * 'struct driver'
 * @dev_head: List of devices in this uclass (devices are attached to their
 * uclass when their bind method is called)
 * @sibling_node: Next uclass in the linked list of uclasses
 */
struct uclass {
    void *priv;								//uclass的私有数据
    struct uclass_driver *uc_drv;			//uclass类的操作函数集合
    struct list_head dev_head;				//该uclass的所有设备
    struct list_head sibling_node;			//下一个uclass的节点
};
```

根据注释，我们就可以了解到，`uclass`相当于老师，管理着==对应某一个类别下==的所有的`udevice`。

> 例如：一个IIC驱动程序，其驱动程序框架是一致的，只有一种，但是IIC驱动的设备可以有很多，如EEPROM，MCU6050等；
>
> 所有在这里呢，`dev_head`链表就是用来管理该驱动类下的所有的设备。

**总结：**`uclass`，来管理该类型下的所有设备，并且有对应的`uclass_driver`驱动。

- #### 定义

`uclass`是`uboot`自动生成的，并且不是所有`uclass`都会生成，有对应`uclass_driver`并且有被`udevice`匹配到的`uclass`才会生成。

- #### 存放

所有生成的uclass都会被挂载`gd->uclass_root`链表上。

- #### 相关API

> 直接遍历链表`gd->uclass_root`链表并且根据`uclass_id`来获取到相应的`uclass`。

```c
int uclass_get(enum uclass_id key, struct uclass **ucp);
// 从gd->uclass_root链表获取对应的ucla ss
```

### ③ uclass_driver

正如上面，我们看到了`uclass`类所包含`uclass_driver`结构体，`uclass_driver`正如其名，它就是`uclass`的驱动程序。其主要作用是：为`uclass`提供统一管理的接口，结构体如下：

```c
/**
 * struct uclass_driver - Driver for the uclass
 *
 * A uclass_driver provides a consistent interface to a set of related
 * drivers.
 */
struct uclass_driver {
    const char *name; // 该uclass_driver的命令
    enum uclass_id id; // 对应的uclass id
/* 以下函数指针主要是调用时机的区别 */
    int (*post_bind)(struct udevice *dev); // 在udevice被绑定到该uclass之后调用
    int (*pre_unbind)(struct udevice *dev); // 在udevice被解绑出该uclass之前调用
    int (*pre_probe)(struct udevice *dev); // 在该uclass的一个udevice进行probe之前调用
    int (*post_probe)(struct udevice *dev); // 在该uclass的一个udevice进行probe之后调用
    int (*pre_remove)(struct udevice *dev);// 在该uclass的一个udevice进行remove之前调用
    int (*child_post_bind)(struct udevice *dev); // 在该uclass的一个udevice的一个子设备被绑定到该udevice之后调用
    int (*child_pre_probe)(struct udevice *dev); // 在该uclass的一个udevice的一个子设备进行probe之前调用
    int (*init)(struct uclass *class); // 安装该uclass的时候调用
    int (*destroy)(struct uclass *class); // 销毁该uclass的时候调用
    int priv_auto_alloc_size; // 需要为对应的uclass分配多少私有数据
    int per_device_auto_alloc_size; //
    int per_device_platdata_auto_alloc_size; //
    int per_child_auto_alloc_size; //
    int per_child_platdata_auto_alloc_size;  //
    const void *ops; //操作集合
    uint32_t flags;   // 标识为
};
```

- #### 定义

`uclass_driver`主要通过`UCLASS_DRIVER`来定义，这里就简单说明一下底层代码，耐心看哦！

> 下面以pinctrl为例

```c
UCLASS_DRIVER(pinctrl) = {
    .id = UCLASS_PINCTRL,
    .post_bind = pinctrl_post_bind,
    .flags = DM_UC_FLAG_SEQ_ALIAS,
    .name = "pinctrl",
};
```

```c
/* Declare a new uclass_driver */
#define UCLASS_DRIVER(__name)						\
    ll_entry_declare(struct uclass_driver, __name, uclass)

#define ll_entry_declare(_type, _name, _list)				\
    _type _u_boot_list_2_##_list##_2_##_name __aligned(4)		\
            __attribute__((unused,				\
            section(".u_boot_list_2_"#_list"_2_"#_name)))
```

**上面基本上就是我们的底层代码了，稍微有点绕，但是也不难！我们只需要将宏进行替换就行了！**

通过上面的定义，我们替换掉宏之后，最终得到的定义如下：

```c
struct uclass_driver _u_boot_list_2_uclass_2_pinctrl = {
    .id = UCLASS_PINCTRL,
    .post_bind = pinctrl_post_bind,
    .flags = DM_UC_FLAG_SEQ_ALIAS,
    .name = "pinctrl",
}
//同时存放在段._u_boot_list_2_uclass_2_pinctrl中，也就是section段的内容
```

- #### 存放

由上面结构体可得，其定义之后都被存放在了段`._u_boot_list_2_uclass_2_pinctrl`中，那么去哪里可以看到呢？

在`u-boot.map`文件中搜索，`._u_boot_list_2_uclass_2_pinctrl`，就可以查到程序中定义的所有驱动程序。

这里相信大家会有疑问，为什么是`uclass_2`呢？我们大概看一下，也会看到`uclass_1`和`uclass_3`，这两个代表什么呢？往下看！

![image-20220112085428516](https://s2.loli.net/2022/01/12/QGf5hjwN1Dvcd7H.png)

- #### 相关API

> 想要获取uclass\_driver需要先获取uclass\_driver table。

```c
struct uclass_driver *uclass =
        ll_entry_start(struct uclass_driver, uclass); 
// 会根据.u_boot_list_2_uclass_1的段地址来得到uclass_driver table的地址

    const int n_ents = ll_entry_count(struct uclass_driver, uclass);
// 获得uclass_driver table的长度

struct uclass_driver *lists_uclass_lookup(enum uclass_id id)
// 从uclass_driver table中获取uclass id为id的uclass_driver。
```

正如注释描述，上文中提到的`uclass_1`和`uclass_3`起到定位作用，用于计算`uclass_2`的长度！

上述的API，主要用于根据`uclass_id`来查找到对应的`uclass_driver`，进而操作对应的`uclass`下的`udevice`。

### ④ uclass_id

我们在`uclass_driver`中，看到一个`uclass_id`类型，这种类型与`uclass`有什么关系呢？

我们知道，`uclass`代表驱动的一个类别，`uclass_driver`是`uclass`的驱动程序，为`uclass`提供统一操作接口。而对于不同类型的驱动，就需要`uclass_id`来区分了！

事实上，每一种类型的设备`uclass`都有唯一对应的`uclass_id`，贯穿设备模型，也是`udevice`与`uclass`相关联的关键之处。

```c
enum uclass_id {
    /* These are used internally by driver model */
    UCLASS_ROOT = 0,
    UCLASS_DEMO,
    UCLASS_TEST,
    UCLASS_TEST_FDT,
    UCLASS_TEST_BUS,
    UCLASS_TEST_PROBE,
......
    /* U-Boot uclasses start here - in alphabetical order */
    UCLASS_ACPI_PMC,	/* (x86) Power-management controller (PMC) */
    UCLASS_ADC,		/* Analog-to-digital converter */
    UCLASS_AHCI,		/* SATA disk controller */
    UCLASS_AUDIO_CODEC,	/* Audio codec with control and data path */
    UCLASS_AXI,		/* AXI bus */
    UCLASS_BLK,		/* Block device */
    UCLASS_BOARD,		/* Device information from hardware */
......
};
```

**在这里，我们就把他当作一个设备识别的标志即可！**

> 最后，压轴的两个结构体出来了，也是DM模型最终操作的对象。

### ⑤ udevice

```c
/**
 * struct udevice - An instance of a driver
 *
 * This holds information about a device, which is a driver bound to a
 * particular port or peripheral (essentially a driver instance).
 *
 */
struct udevice {
    const struct driver *driver;		//device 对应的driver
    const char *name;					//device 的名称
    void *platdata;
    void *parent_platdata;
    void *uclass_platdata;
    ofnode node;						//设备树节点
    ulong driver_data;
    struct udevice *parent;				//父设备
    void *priv;							// 私有数据的指针
    struct uclass *uclass;				//驱动所属的uclass
    void *uclass_priv;
    void *parent_priv;
    struct list_head uclass_node;
    struct list_head child_head;
    struct list_head sibling_node;
    uint32_t flags;
    int req_seq;
    int seq;
#ifdef CONFIG_DEVRES
    struct list_head devres_head;
#endif
};
```

- #### 定义

  - **硬编码：**代码中调用`U_BOOT_DEVICE`宏来定义设备资源，实际为一个设备实例。
  - **设备树：**将设备描述信息写在对应的DTS文件中，然后编译成DTB，最终由uboot解析设备树后动态生成的。
  - **传参方式：通过命令行或者接口将设备资源信息传递进来，非常灵活。**

- #### 存放

`udevice`是最基础的一个设备单元，我们把它作为一个独立的个体，上层所有的操作，最终都与该结构体有关。

我们创建一个设备后，为了服从统一的管理，该结构体会被连接到DM模型下，并入到机制中。那么`udevice`会被连接到哪里呢？

- 将`udevice`连接到对应的`uclass`中，`uclass`主要用来管理着同一类的驱动
- 除此之外，有父子关系的`udevice`，还会连接到`udevice->child_head`链表下，方便调用

**大概可以理解为下面这样：**

![image-20220110200005987](https://s2.loli.net/2022/01/10/5NemOR1aPMhjFA3.png)

- #### 相关API

```c
#define uclass_foreach_dev(pos, uc) \
    list_for_each_entry(pos, &uc->dev_head, uclass_node)

#define uclass_foreach_dev_safe(pos, next, uc)  \
    list_for_each_entry_safe(pos, next, &uc->dev_head, uclass_node)

int uclass_get_device(enum uclass_id id, int index, struct udevice **devp); // 通过索引从uclass中获取udevice
int uclass_get_device_by_name(enum uclass_id id, const char *name, // 通过设备名从uclass中获取udevice
                  struct udevice **devp);
int uclass_get_device_by_seq(enum uclass_id id, int seq, struct udevice **devp);
int uclass_get_device_by_of_offset(enum uclass_id id, int node,
                   struct udevice **devp);
int uclass_get_device_by_phandle(enum uclass_id id, struct udevice *parent,
                 const char *name, struct udevice **devp);
int uclass_first_device(enum uclass_id id, struct udevice **devp);
int uclass_first_device_err(enum uclass_id id, struct udevice **devp);
int uclass_next_device(struct udevice **devp);
int uclass_resolve_seq(struct udevice *dev);
```

这些相关的API，主要作用就是根据`uclass_id`，查找对应的`uclass`，然后根据索引值或者名称，来查找到对应的`udevice`

### ③ driver

```c
struct driver {
    char *name;							//驱动名称
    enum uclass_id id;					//驱动所对应的uclass_id	
    const struct udevice_id *of_match;	//匹配函数
    int (*bind)(struct udevice *dev);	//绑定函数
    int (*probe)(struct udevice *dev);	//注册函数
    int (*remove)(struct udevice *dev);
    int (*unbind)(struct udevice *dev);
    int (*ofdata_to_platdata)(struct udevice *dev);
    int (*child_post_bind)(struct udevice *dev);
    int (*child_pre_probe)(struct udevice *dev);
    int (*child_post_remove)(struct udevice *dev);
    int priv_auto_alloc_size;
    int platdata_auto_alloc_size;
    int per_child_auto_alloc_size;
    int per_child_platdata_auto_alloc_size;
    const void *ops;	/* driver-specific operations */
    uint32_t flags;
#if CONFIG_IS_ENABLED(ACPIGEN)
    struct acpi_ops *acpi_ops;
#endif
};
```

- #### 定义

`driver`对象，主要通过`U_BOOT_DRIVER`来定义

> 以pinctrl来举例

```c
U_BOOT_DRIVER(xxx_pinctrl) = {
    .name		= "xxx_pinctrl",
    .id		= UCLASS_PINCTRL,
    .of_match	= arobot_pinctrl_match,
    .priv_auto_alloc_size = sizeof(struct xxx_pinctrl),
    .ops		= &arobot_pinctrl_ops,
    .probe		= arobot_v2s_pinctrl_probe,
    .remove 	= arobot_v2s_pinctrl_remove,
};
```

```c
/* Declare a new U-Boot driver */
#define U_BOOT_DRIVER(__name)						\
    ll_entry_declare(struct driver, __name, driver)


#define ll_entry_declare(_type, _name, _list)				\
    _type _u_boot_list_2_##_list##_2_##_name __aligned(4)		\
            __attribute__((unused,				\
            section(".u_boot_list_2_"#_list"_2_"#_name)))
```

**通过上面的定义，最终我们定义的结构体如下：**

```c
struct driver _u_boot_list_2_driver_2_xxx_pinctrl = {
    .name		= "xxx_pinctrl",
    .id		= UCLASS_PINCTRL,
    .of_match	= arobot_pinctrl_match,
    .priv_auto_alloc_size = sizeof(struct xxx_pinctrl),
    .ops		= &arobot_pinctrl_ops,
    .probe		= arobot_v2s_pinctrl_probe,
    .remove 	= arobot_v2s_pinctrl_remove,
}
//同时存放在段._u_boot_list_2_driver_2_xxx_pinctrl中
```

- #### 存放

由上面结构体可得，其定义之后都被存放在了段`._u_boot_list_2_driver_2_xxx`中，那么去哪里可以看到呢？

在`u-boot.map`文件中搜索，`._u_boot_list_2_driver`，就可以查到程序中定义的所有驱动程序。

![image-20220331082429756](https://cdn.jsdelivr.net/gh/UNIONDONG/Get_Pic_Url/Media202203310824866.png)

最终，所有driver结构体以列表的形式被放在`.u_boot_list_2_driver_1`和`.u_boot_list_2_driver_3`的区间中。

- #### 相关API

```c
 
/*先获取driver table 表*/
struct driver *drv =
        ll_entry_start(struct driver, driver);		// 会根据.u_boot_list_2_driver_1的段地址来得到uclass_driver table的地址
  const int n_ents = ll_entry_count(struct driver, driver);		// 通过.u_boot_list_2_driver_3的段地址 减去 .u_boot_list_2_driver_1的段地址 获得driver table的长度

/*遍历所有的driver*/
struct driver *lists_driver_lookup_name(const char *name)	// 从driver table中获取名字为name的driver。
```

正如注释描述，上文中提到的`driver_1`和`driver_3`起到定位作用，用于计算`driver_2`的长度！

上述的API，主要用于根据`name`来查找到对应的`driver`驱动程序。

综上，DM模型相关的数据结构介绍完毕，整体设计的架构如下：

![image-20220112090637141](https://s2.loli.net/2022/01/12/I6etk9T2aZyfSvK.png)

正如红线部分，如何实现`driver`和`udevice`的绑定、`uclass`、`uclass_driver`的绑定呢？

要想真正搞懂这些，我们不得不去深入到DM的初始化流程。

## 3.5、DM驱动模型之上帝视角

> 对于DM模型，我们站在上帝视角来观察整套模型框架是如何的！

从**对象设计**的角度来看，Uboot的驱动模型可以分为**静态形式和动态形式**。

- **静态模式：**对象是离散的，和其他对象分隔开，减小对象复杂度，利于模块化设计。

- **动态模式：**运行态表达形式的对象是**把所有的静态对象组合成层次视图，有清晰的数据关联视图**

**在静态模式下**，驱动模型主要将对象分为`udevice`和`driver`，即设备和驱动程序，两个就像火车的两条轨道，永远也不会产生交集，驱动和设备可以想注册多少就注册多少。

![image-20220110112235895](https://s2.loli.net/2022/01/10/OYR9UD3f26J8KzX.png)

我们看一下`udevice`的描述：

```c
/**
 * struct udevice - An instance of a driver
 *
 * This holds information about a device, which is a driver bound to a
 * particular port or peripheral (essentially a driver instance).
 *
 */
```

`udevice`是`driver`的一个实例，两个不相交的铁轨，终归也是想要发生爱情的。那么如何让其产生交集呢？这就是动态模式需要做的工作了！

**在动态模式下，**引入了`uclass`和`uclass_driver`两个数据结构，实现了对`udevice`和`driver`的管理。

看一下`uclass`和`uclass_driver`两个结构体的说明：

```c
/**
 * struct uclass - a U-Boot drive class, collecting together similar drivers
 *
 */


/**
 * struct uclass_driver - Driver for the uclass
 *
 * A uclass_driver provides a consistent interface to a set of related
 * drivers.
 *
 */
```

- \*\*uclass：\*\*设备组公共属性对象，作为`udevice`的一个属性，主要用来管理某个驱动类的所有的设备。
- \*\*uclass_driver：\*\*设备组公共行为对象，`uclass`的驱动程序，主要将`uclass`管理的设备和驱动实现绑定、注册，移除等操作。

通过这两个结构体的引入，可以将毫不相关的`udevice`是`driver`关联起来！

`udevice`与`driver`的绑定：通过驱动的`of_match`和`compatible`属性来配对，绑定。

![image-20220120202638750](https://cdn.jsdelivr.net/gh/UNIONDONG/Get_Pic_Url/Media202201202026789.png)

`udevice`与`uclass`的绑定：`udevice`内的`driver`下的`uclass_id`，来与`uclass`对应的`uclass_driver`的`uclass_id`进行匹配。

`uclass`与`uclass_driver`的绑定：已知`udevice`内的`driver`下的`uclass_id`，创建`uclass`的同时，通过``uclass_id`找到对应的`uclass_driver`对象，然后将`uclass_driver`绑定到`uclass`上！

**整体结构如下：**

![image-20220120203453935](https://cdn.jsdelivr.net/gh/UNIONDONG/Get_Pic_Url/Media202201202034015.png)

![DM下的接口调用流程](https://img-blog.csdn.net/20161119201742692)

## 3.6、DM模型——Udevice与driver绑定

> 相信站在上帝视角看完DM的整体架构，大家都对DM框架有一定了解，下面我们来看看具体的实现细节！

DM的初始化分为两个部分，一个是在`relocate`重定向之前的初始化：`initf_dm`，一个是在`relocate`重定向之后的初始化：`initr_dm`。

**我们对比这两个函数：**

```c
static int initf_dm(void)
{
#if defined(CONFIG_DM) && CONFIG_VAL(SYS_MALLOC_F_LEN)
    int ret;

    bootstage_start(BOOTSTAGE_ID_ACCUM_DM_F, "dm_f");
    ret = dm_init_and_scan(true);					//这里为true
    bootstage_accum(BOOTSTAGE_ID_ACCUM_DM_F);
    if (ret)
        return ret;
#endif
#ifdef CONFIG_TIMER_EARLY
    ret = dm_timer_init();
    if (ret)
        return ret;
#endif

    return 0;
}

static int initr_dm(void)
{
    int ret;

    /* Save the pre-reloc driver model and start a new one */
    gd->dm_root_f = gd->dm_root;
    gd->dm_root = NULL;
#ifdef CONFIG_TIMER
    gd->timer = NULL;
#endif
    bootstage_start(BOOTSTAGE_ID_ACCUM_DM_R, "dm_r");
    ret = dm_init_and_scan(false);						//这里为false
    bootstage_accum(BOOTSTAGE_ID_ACCUM_DM_R);
    if (ret)
        return ret;

    return 0;
}

```

两个均调用了`dm_init_and_scan`这个接口，这两个的关键区别在于参数的不同。

- 首先说明一下dts节点中的“`u-boot,dm-pre-reloc`”属性，当设置了这个属性时，则表示这个设备在`relocate`之前就需要使用。
- 当dm\_init\_and_scan的参数为`true`时，只会对带有“`u-boot,dm-pre-reloc`”属性的节点进行解析。而当参数为`false`的时候，则会对所有节点都进行解析。

**DM初始化的大体步骤如下：**

![image-20220122134027436](https://cdn.jsdelivr.net/gh/UNIONDONG/Get_Pic_Url/Media202201221340003.png)

> 如上程序执行流程图，下面我们详细讲解几个函数。

#### ① dm_init

```c
int dm_init(bool of_live)
{
    int ret;

    if (gd->dm_root) {
        dm_warn("Virtual root driver already exists!\n");
        return -EINVAL;
    }
    INIT_LIST_HEAD(&DM_UCLASS_ROOT_NON_CONST);

#if defined(CONFIG_NEEDS_MANUAL_RELOC)
    fix_drivers();
    fix_uclass();
    fix_devices();
#endif

    ret = device_bind_by_name(NULL, false, &root_info, &DM_ROOT_NON_CONST);		//查找root_driver驱动，并绑定
    if (ret)
        return ret;
#if CONFIG_IS_ENABLED(OF_CONTROL)
# if CONFIG_IS_ENABLED(OF_LIVE)
    if (of_live)
        DM_ROOT_NON_CONST->node = np_to_ofnode(gd->of_root);
    else
#endif
        DM_ROOT_NON_CONST->node = offset_to_ofnode(0);
#endif
    ret = device_probe(DM_ROOT_NON_CONST);										//probe激活root_driver驱动
    if (ret)
        return ret;

    return 0;
}
```

`dm_init`这个函数，名字起的容易让人误导，这个函数主要做的就是初始化了根设备`root_driver`，根据这个跟设备，初始化了`global_data`中的`dm_root`、`uclass_root`。

#### ② lists\_bind\_fdt

> 我们通常会使用设备树来定义各种设备，所以这个函数才是主角。

这个函数主要用来查找子设备，并且根据查找到的子设备，进而查找对应驱动进行绑定！即：实现了`driver`和`device`的绑定。

```c
int lists_bind_fdt(struct udevice *parent, ofnode node, struct udevice **devp,
           bool pre_reloc_only)
{
    struct driver *driver = ll_entry_start(struct driver, driver);				//获得驱动列表的起始地址
    const int n_ents = ll_entry_count(struct driver, driver);					//获得驱动列表的总数量
    const struct udevice_id *id;
    struct driver *entry;
    struct udevice *dev;
    bool found = false;
    const char *name, *compat_list, *compat;
    int compat_length, i;
    int result = 0;
    int ret = 0;

    if (devp)
        *devp = NULL;
    name = ofnode_get_name(node);
    log_debug("bind node %s\n", name);

    compat_list = ofnode_get_property(node, "compatible", &compat_length);		//得到compatible属性，用于匹配driver驱动
    if (!compat_list) {
        if (compat_length == -FDT_ERR_NOTFOUND) {
            log_debug("Device '%s' has no compatible string\n",
                  name);
            return 0;
        }

        dm_warn("Device tree error at node '%s'\n", name);
        return compat_length;
    }

    /*
     * Walk through the compatible string list, attempting to match each
     * compatible string in order such that we match in order of priority
     * from the first string to the last.
     */
    for (i = 0; i < compat_length; i += strlen(compat) + 1) {
        compat = compat_list + i;
        log_debug("   - attempt to match compatible string '%s'\n",
              compat);

        for (entry = driver; entry != driver + n_ents; entry++) {				//循环判断所有驱动是否匹配	
            ret = driver_check_compatible(entry->of_match, &id,
                              compat);
            if (!ret)
                break;
        }
        if (entry == driver + n_ents)
            continue;

        if (pre_reloc_only) {
            if (!ofnode_pre_reloc(node) &&
                !(entry->flags & DM_FLAG_PRE_RELOC)) {
                log_debug("Skipping device pre-relocation\n");
                return 0;
            }
        }

        log_debug("   - found match at '%s': '%s' matches '%s'\n",
              entry->name, entry->of_match->compatible,
              id->compatible);
        ret = device_bind_with_driver_data(parent, entry, name,
                           id->data, node, &dev);								//该函数，用于创建udevice对象，并与查找到的driver绑定
        if (ret == -ENODEV) {
            log_debug("Driver '%s' refuses to bind\n", entry->name);
            continue;
        }
        if (ret) {
            dm_warn("Error binding driver '%s': %d\n", entry->name,
                ret);
            return ret;
        } else {
            found = true;
            if (devp)
                *devp = dev;
        }
        break;
    }

    if (!found && !result && ret != -ENODEV)
        log_debug("No match for node '%s'\n", name);

    return result;
}
```

`lists_bind_fdt`这个函数，主要用来扫描设备树中的各个节点；

根据扫描到的`udevice`设备信息，通过`compatible`来匹配`compatible`相同的`driver`，匹配成功后，就会创建对应的`struct udevice`结构体，它会同时指向设备资源和driver，这样设备资源和driver就绑定在一起了。

## 3.7、DM模型——probe探测函数的执行

> 上述，完成了DM模型的初始化，但是我们只是建立了`driver`和`udevice`的绑定关系，那么何时调用到我们驱动中的`probe`探测函数呢？`uclass`与`driver`又何时匹配的呢？

上文呢，`dm_init`只是负责初始化并绑定了`udevice`和`driver`，那么`probe`探测函数的执行，当然是在该驱动初始化的时候喽！

> 下文以mmc驱动为例！其初始化流程如下：

![image-20220122135318237](https://cdn.jsdelivr.net/gh/UNIONDONG/Get_Pic_Url/Media202201221353293.png)

详细代码在这里就不展开来叙述了！

在MMC驱动初始化后，有没有注意到`mmc_probe`这个函数，该函数就是间接调用了我们驱动编写的`probe`函数。

执行流程在上面已经很清楚了：根据`uclass_id`，调用``uclass\_get\_device\_by\_seq`来得到`udevice`，进而调用`device_probe`来找到对应驱动的`probe`。

```c
int device_probe(struct udevice *dev)
{
    const struct driver *drv;
    int ret;
    int seq;

    if (!dev)
        return -EINVAL;

    if (dev->flags & DM_FLAG_ACTIVATED)
        return 0;

    drv = dev->driver;													//获取driver
    assert(drv);

    ret = device_ofdata_to_platdata(dev);
    if (ret)
        goto fail;

    /* Ensure all parents are probed */
    if (dev->parent) {													//父设备probe
        ret = device_probe(dev->parent);
        if (ret)
            goto fail;

        /*
         * The device might have already been probed during
         * the call to device_probe() on its parent device
         * (e.g. PCI bridge devices). Test the flags again
         * so that we don't mess up the device.
         */
        if (dev->flags & DM_FLAG_ACTIVATED)
            return 0;
    }

    seq = uclass_resolve_seq(dev);
    if (seq < 0) {
        ret = seq;
        goto fail;
    }
    dev->seq = seq;

    dev->flags |= DM_FLAG_ACTIVATED;

    /*
     * Process pinctrl for everything except the root device, and
     * continue regardless of the result of pinctrl. Don't process pinctrl
     * settings for pinctrl devices since the device may not yet be
     * probed.
     */
    if (dev->parent && device_get_uclass_id(dev) != UCLASS_PINCTRL)
        pinctrl_select_state(dev, "default");

    if (CONFIG_IS_ENABLED(POWER_DOMAIN) && dev->parent &&
        (device_get_uclass_id(dev) != UCLASS_POWER_DOMAIN) &&
        !(drv->flags & DM_FLAG_DEFAULT_PD_CTRL_OFF)) {
        ret = dev_power_domain_on(dev);
        if (ret)
            goto fail;
    }

    ret = uclass_pre_probe_device(dev);
    if (ret)
        goto fail;

    if (dev->parent && dev->parent->driver->child_pre_probe) {
        ret = dev->parent->driver->child_pre_probe(dev);
        if (ret)
            goto fail;
    }

    /* Only handle devices that have a valid ofnode */
    if (dev_of_valid(dev)) {
        /*
         * Process 'assigned-{clocks/clock-parents/clock-rates}'
         * properties
         */
        ret = clk_set_defaults(dev, 0);
        if (ret)
            goto fail;
    }

    if (drv->probe) {												
        ret = drv->probe(dev);										//调用驱动的probe
        if (ret)
            goto fail;
    }

    ret = uclass_post_probe_device(dev);
    if (ret)
        goto fail_uclass;

    if (dev->parent && device_get_uclass_id(dev) == UCLASS_PINCTRL)
        pinctrl_select_state(dev, "default");

    return 0;
fail_uclass:
    if (device_remove(dev, DM_REMOVE_NORMAL)) {
        dm_warn("%s: Device '%s' failed to remove on error path\n",
            __func__, dev->name);
    }
fail:
    dev->flags &= ~DM_FLAG_ACTIVATED;

    dev->seq = -1;
    device_free(dev);

    return ret;
}
```

**主要工作归纳如下：**

- 根据`udevice`获取`driver`
- 然后判断是否父设备被`probe`
- 对父设备进行probe
- 调用driver的probe函数

## 3.8、DM模型——uclass与uclass_driver绑定

> 上述完成了`driver`的`probe`函数调用，基本底层都已经准备好了，`uclass`何时与`uclass_driver`绑定，给上层提供统一的API呢？

`uclass`与`uclass_driver`绑定，也是在驱动`probe`之后，确保该驱动存在，设备存在，最后为该驱动绑定`uclass`与`uclass_driver`，为上层提供统一接口。

> 以根据MMC驱动为例

回到上文的驱动流程图，看到`mmc_do_preinit`这个函数了嘛？里面调用了`ret = uclass_get(UCLASS_MMC, &uc);`，该函数才是真正的将`uclass`与`uclass_driver`绑定。

```c
int uclass_get(enum uclass_id id, struct uclass **ucp)
{
    struct uclass *uc;

    *ucp = NULL;
    uc = uclass_find(id);
    if (!uc)
        return uclass_add(id, ucp);
    *ucp = uc;

    return 0;
}
```

**`uclass_get`主要实现了**：根据`uclass_id`查找对应的`uclass`是否被添加到`global_data->uclass_root`链表中，如果没有添加到，就调用`uclass_add`函数，实现`uclass`与`uclass_driver`的绑定，并将其添加到`global_data->uclass_root`链表中。

```c
static int uclass_add(enum uclass_id id, struct uclass **ucp)
{
    struct uclass_driver *uc_drv;
    struct uclass *uc;
    int ret;

    *ucp = NULL;
    uc_drv = lists_uclass_lookup(id);					//根据uclass_id查找到对应的driver
    if (!uc_drv) {
        debug("Cannot find uclass for id %d: please add the UCLASS_DRIVER() declaration for this UCLASS_... id\n",
              id);
        /*
         * Use a strange error to make this case easier to find. When
         * a uclass is not available it can prevent driver model from
         * starting up and this failure is otherwise hard to debug.
         */
        return -EPFNOSUPPORT;
    }
    uc = calloc(1, sizeof(*uc));
    if (!uc)
        return -ENOMEM;
    if (uc_drv->priv_auto_alloc_size) {
        uc->priv = calloc(1, uc_drv->priv_auto_alloc_size);
        if (!uc->priv) {
            ret = -ENOMEM;
            goto fail_mem;
        }
    }
    uc->uc_drv = uc_drv;												//uclass与uclass_driver绑定
    INIT_LIST_HEAD(&uc->sibling_node);
    INIT_LIST_HEAD(&uc->dev_head);
    list_add(&uc->sibling_node, &DM_UCLASS_ROOT_NON_CONST);				//添加到global_data->uclass_root链表中

    if (uc_drv->init) {
        ret = uc_drv->init(uc);
        if (ret)
            goto fail;
    }

    *ucp = uc;

    return 0;
fail:
    if (uc_drv->priv_auto_alloc_size) {
        free(uc->priv);
        uc->priv = NULL;
    }
    list_del(&uc->sibling_node);
fail_mem:
    free(uc);

    return ret;
}
```

好啦，到这里基本就把Uboot的DM模型全部理清楚啦，耗时一个周，总感觉想要自己去讲明白，真的不是一件容易的事情呢！

如果对你们有帮助，记得点个赞哦！

## 3.9 参考文档

\[1\] : https://www.dazhuanlan.com/archevalier/topics/1323360

\[2\] : https://www.cnblogs.com/gs1008612/p/8253213.html

\[3\] : https://blog.csdn.net/kunkliu/article/details/103168591

\[4\] : https://blog.csdn.net/ooonebook/article/details/53234020

<center><b> <font color ="blue">欢迎关注【嵌入式艺术】，董哥原创！</font></b></center>

<div align=center><img src="https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/Embeded_Art.gif" alt="img" width = "60%" height ="10%"/>
</div>
