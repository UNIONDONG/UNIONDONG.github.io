---
date: '2024-01-19T20:27:37+08:00'
title:       '【LED子系统深度剖析】三、硬件驱动层详解'
description: ""
author:      "Donge"
image:       ""
tags:        ["LED子系统", "LED子系统深度剖析", "Linux驱动开发", "LED驱动开发"]
categories:  ["Tech" ]
weight: 3
---

# 【LED子系统深度剖析】三、硬件驱动层详解

> 上篇文章我们了解了子系统的框架，下面我们来分析驱动框架中每层的实现以及作用。

![image-20230417084033734](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/image-20230417084033734.png)

在`LED`子系统中，硬件驱动层相关文件在包括：`kernel/drivers/leds/` 目录下，其主要的函数有：`led-gpio.c`、`led-xxx.c`，其中`led-gpio.c`为通用的平台驱动程序，`led-xxx.c`为不同厂家提供的平台驱动程序。

> 我们在这里主要分析`led-gpio.c`

## 1、gpio\_led\_probe分析

打开该文件，直接找到加载驱动的入口函数`gpio_led_probe`

### 1.1 相关数据结构

#### 1.1.1 gpio\_led\_platform_data

```C
struct gpio_led_platform_data {
    int 		num_leds;
    const struct gpio_led *leds;

#define GPIO_LED_NO_BLINK_LOW	0	/* No blink GPIO state low */
#define GPIO_LED_NO_BLINK_HIGH	1	/* No blink GPIO state high */
#define GPIO_LED_BLINK		2	/* Please, blink */
    gpio_blink_set_t	gpio_blink_set;
};
```

**结构体名称**：`gpio_led_platform_data`

**文件位置**：`include/linux/leds.h`

**主要作用**：`LED`的平台数据，用于对`LED`硬件设备的统一管理

> 这个结构体用于父节点向子节点传递的数据时使用

#### 1.1.2 gpio\_leds\_priv

```C
struct gpio_leds_priv {
    int num_leds;
    struct gpio_led_data leds[];
};
```

**结构体名称**：`gpio_leds_priv`

**文件位置**：`drivers/leds/leds-gpio.c`

**主要作用**：`LED`驱动的私有数据类型，管理全部的`LED`设备。

> 这里的`num_leds`通过解析设备树的子节点的个数来获取
> 
> `leds[]`根据获取的`num_leds`个数，分配对应的空间，来初始化相关数据

### 1.2 实现流程

```c
static int gpio_led_probe(struct platform_device *pdev)
{
    struct gpio_led_platform_data *pdata = dev_get_platdata(&pdev->dev);		//	检索设备的平台数据
    struct gpio_leds_priv *priv;
    int i, ret = 0;

    if (pdata && pdata->num_leds) {												//	判断平台数据LED数量
        priv = devm_kzalloc(&pdev->dev,
                sizeof_gpio_leds_priv(pdata->num_leds),
                    GFP_KERNEL);
        if (!priv)
            return -ENOMEM;

        priv->num_leds = pdata->num_leds;
        for (i = 0; i < priv->num_leds; i++) {
            ret = create_gpio_led(&pdata->leds[i], &priv->leds[i],
                          &pdev->dev, NULL,
                          pdata->gpio_blink_set);
            if (ret < 0)
                return ret;
        }
    } else {
        priv = gpio_leds_create(pdev);											//	创建LED设备	
        if (IS_ERR(priv))
            return PTR_ERR(priv);
    }

    platform_set_drvdata(pdev, priv);

    return 0;
}
```

**函数介绍**：`gpio_led_probe`是`LED`驱动的入口函数，也是`LED`子系统中，硬件设备和驱动程序匹配后，第一个执行的函数。

**实现思路**：

1.  通过`dev_get_platdata`检索设备的平台数据，如果平台数据中的`LED`数量大于零，则使用`devm_kzalloc`为其分配内存空间，并且使用`create_gpio_led`进行初始化
2.  如果平台数据不存在或`LED`的数量为零，则使用`gpio_leds_create`创建LED。
3.  最后，设置驱动程序数据，并返回0，表示操作成功。

**数据结构**：该函数主要包括了两个数据结构`gpio_led_platform_data`和`gpio_leds_priv`

## 2、gpio\_leds\_create分析

### 2.1 相关数据结构

#### 2.1.1 gpio_led

```C
/* For the leds-gpio driver */
struct gpio_led {
    const char *name;					// LED名称
    const char *default_trigger;		// 默认触发类型	
    unsigned 	gpio;					// GPIO编号
    unsigned	active_low : 1;			// 低电平有效
    unsigned	retain_state_suspended : 1;
    unsigned	panic_indicator : 1;
    unsigned	default_state : 2;		// 默认状态
    unsigned	retain_state_shutdown : 1;
    /* default_state should be one of LEDS_GPIO_DEFSTATE_(ON|OFF|KEEP) */
    struct gpio_desc *gpiod;			// GPIO Group
};
```

**结构体名称**：`gpio_led`

**文件位置**：`include/linux/leds.h`

**主要作用**：`LED`的硬件描述结构，包括名称，`GPIO`编号，有效电平等等信息。

> 该结构体的信息大多由解析设备树获得，将设备树中`label`解析为`name`，`gpios`解析为`gpiod`，`linux,default-trigger`解析为`default_trigger`等

#### 2.1.2 gpio\_led\_data

```C
struct gpio_led_data {
    struct led_classdev cdev;		// LED Class
    struct gpio_desc *gpiod;		// GPIO description
    u8 can_sleep;					
    u8 blinking;					// 闪烁
    gpio_blink_set_t platform_gpio_blink_set;	// 闪烁设置
};
```

**结构体名称**：`gpio_led_data`

**文件位置**：`drivers/leds/leds-gpio.c`

**主要作用**：`LED`相关数据信息，主要在于`led_classdev`，用于注册设备节点信息

> 由设备树解析出来的`gpio_led`，然后将部分属性赋值到`gpio_led_data`中，并且初始化`led_classdev`相关属性，并且实现`led_classdev`结构体中的部分函数。

### 2.2 实现流程

```c
static struct gpio_leds_priv *gpio_leds_create(struct platform_device *pdev)
{
    struct device *dev = &pdev->dev;
    struct fwnode_handle *child;
    struct gpio_leds_priv *priv;
    int count, ret;

    count = device_get_child_node_count(dev);		//	获取子节点数量
    if (!count)
        return ERR_PTR(-ENODEV);

    priv = devm_kzalloc(dev, sizeof_gpio_leds_priv(count), GFP_KERNEL);
    if (!priv)
        return ERR_PTR(-ENOMEM);

    device_for_each_child_node(dev, child) {
        struct gpio_led_data *led_dat = &priv->leds[priv->num_leds];	//	与gpio_leds_priv结构体关联
        struct gpio_led led = {};
        const char *state = NULL;
        struct device_node *np = to_of_node(child);

        ret = fwnode_property_read_string(child, "label", &led.name);	//	读设备树属性，赋值gpio_led结构体
        if (ret && IS_ENABLED(CONFIG_OF) && np)
            led.name = np->name;
        if (!led.name) {
            fwnode_handle_put(child);
            return ERR_PTR(-EINVAL);
        }

        led.gpiod = devm_fwnode_get_gpiod_from_child(dev, NULL, child,
                                 GPIOD_ASIS,
                                 led.name);
        if (IS_ERR(led.gpiod)) {
            fwnode_handle_put(child);
            return ERR_CAST(led.gpiod);
        }

        fwnode_property_read_string(child, "linux,default-trigger",
                        &led.default_trigger);

        if (!fwnode_property_read_string(child, "default-state",
                         &state)) {
            if (!strcmp(state, "keep"))
                led.default_state = LEDS_GPIO_DEFSTATE_KEEP;
            else if (!strcmp(state, "on"))
                led.default_state = LEDS_GPIO_DEFSTATE_ON;
            else
                led.default_state = LEDS_GPIO_DEFSTATE_OFF;
        }

        if (fwnode_property_present(child, "retain-state-suspended"))
            led.retain_state_suspended = 1;
        if (fwnode_property_present(child, "retain-state-shutdown"))
            led.retain_state_shutdown = 1;
        if (fwnode_property_present(child, "panic-indicator"))
            led.panic_indicator = 1;

        ret = create_gpio_led(&led, led_dat, dev, np, NULL);	//	将gpio_led结构体、gpio_led_data关联起来
        if (ret < 0) {
            fwnode_handle_put(child);
            return ERR_PTR(ret);
        }
        led_dat->cdev.dev->of_node = np;
        priv->num_leds++;
    }

    return priv;
}
```

**函数介绍**：`gpio_leds_create`主要用于创建`LED`设备。

**实现思路**：

1.  通过`device_get_child_node_count`获取设备树中`LED`子节点的数量，根据获取到的子节点数量，分配`LED`设备对应的内存空间
2.  通过`device_for_each_child_node`遍历每个子节点，并为每个子节点创建对应的`LED`设备
3.  对于每个子节点，使用`fwnode_property_read_string`接口，读取设备树中相关的属性信息，如：`label`、`linux,default-trigger`等，将这些信息赋值给`gpio_led`结构体中
4.  最后将遍历的每个`LED`，调用`create_gpio_led`进行设备的创建

## 3、create\_gpio\_led分析

### 3.1 相关数据结构

#### 3.1.1 led_classdev

> 该数据结构属于核心层，在硬件驱动层需要与其进行关联，遂在此介绍。

```C
struct led_classdev {
    const char		*name;
    enum led_brightness	 brightness;
    enum led_brightness	 max_brightness;
    int			 flags;

    /* Lower 16 bits reflect status */
#define LED_SUSPENDED		BIT(0)
#define LED_UNREGISTERING	BIT(1)
    /* Upper 16 bits reflect control information */
#define LED_CORE_SUSPENDRESUME	BIT(16)
#define LED_SYSFS_DISABLE	BIT(17)
#define LED_DEV_CAP_FLASH	BIT(18)
#define LED_HW_PLUGGABLE	BIT(19)
#define LED_PANIC_INDICATOR	BIT(20)
#define LED_BRIGHT_HW_CHANGED	BIT(21)
#define LED_RETAIN_AT_SHUTDOWN	BIT(22)

    /* set_brightness_work / blink_timer flags, atomic, private. */
    unsigned long		work_flags;

#define LED_BLINK_SW			0
#define LED_BLINK_ONESHOT		1
#define LED_BLINK_ONESHOT_STOP		2
#define LED_BLINK_INVERT		3
#define LED_BLINK_BRIGHTNESS_CHANGE 	4
#define LED_BLINK_DISABLE		5

    /* Set LED brightness level
     * Must not sleep. Use brightness_set_blocking for drivers
     * that can sleep while setting brightness.
     */
    void		(*brightness_set)(struct led_classdev *led_cdev,
                      enum led_brightness brightness);
    /*
     * Set LED brightness level immediately - it can block the caller for
     * the time required for accessing a LED device register.
     */
    int (*brightness_set_blocking)(struct led_classdev *led_cdev,
                       enum led_brightness brightness);
    /* Get LED brightness level */
    enum led_brightness (*brightness_get)(struct led_classdev *led_cdev);

    /*
     * Activate hardware accelerated blink, delays are in milliseconds
     * and if both are zero then a sensible default should be chosen.
     * The call should adjust the timings in that case and if it can't
     * match the values specified exactly.
     * Deactivate blinking again when the brightness is set to LED_OFF
     * via the brightness_set() callback.
     */
    int		(*blink_set)(struct led_classdev *led_cdev,
                     unsigned long *delay_on,
                     unsigned long *delay_off);

    struct device		*dev;
    const struct attribute_group	**groups;

    struct list_head	 node;			/* LED Device list */
    const char		*default_trigger;	/* Trigger to use */

    unsigned long		 blink_delay_on, blink_delay_off;
    struct timer_list	 blink_timer;
    int			 blink_brightness;
    int			 new_blink_brightness;
    void			(*flash_resume)(struct led_classdev *led_cdev);

    struct work_struct	set_brightness_work;
    int			delayed_set_value;

#ifdef CONFIG_LEDS_TRIGGERS
    /* Protects the trigger data below */
    struct rw_semaphore	 trigger_lock;

    struct led_trigger	*trigger;
    struct list_head	 trig_list;
    void			*trigger_data;
    /* true if activated - deactivate routine uses it to do cleanup */
    bool			activated;
#endif

#ifdef CONFIG_LEDS_BRIGHTNESS_HW_CHANGED
    int			 brightness_hw_changed;
    struct kernfs_node	*brightness_hw_changed_kn;
#endif

    /* Ensures consistent access to the LED Flash Class device */
    struct mutex		led_access;
};
```

**结构体名称**：`led_classdev`

**文件位置**：`include/linux/leds.h`

**主要作用**：该结构体所包括的内容较多，主要有以下几个功能

- `brightness`当前亮度值，`max_brightness`最大亮度
- `LED`闪烁功能控制：`blink_timer`、`blink_brightness`、`new_blink_brightness`等
- `attribute_group`：创建`sysfs`文件节点，向上提供用户访问接口

> 由上面可知，在创建`gpio_led_data`时，顺便初始化 `led_classdev`结构体，赋值相关属性以及部分回调函数，最终将`led_classdev`注册进入`LED`子系统框架中，在`sysfs`中创建对应的文件节点。

### 3.2 实现流程

```C
static int create_gpio_led(const struct gpio_led *template,
    struct gpio_led_data *led_dat, struct device *parent,
    struct device_node *np, gpio_blink_set_t blink_set)
{
    int ret, state;

    led_dat->gpiod = template->gpiod;
    if (!led_dat->gpiod) {
        /*
         * This is the legacy code path for platform code that
         * still uses GPIO numbers. Ultimately we would like to get
         * rid of this block completely.
         */
        unsigned long flags = GPIOF_OUT_INIT_LOW;

        /* skip leds that aren't available */
        if (!gpio_is_valid(template->gpio)) {								//	判断是否gpio合法
            dev_info(parent, "Skipping unavailable LED gpio %d (%s)\n",
                    template->gpio, template->name);
            return 0;
        }

        if (template->active_low)
            flags |= GPIOF_ACTIVE_LOW;

        ret = devm_gpio_request_one(parent, template->gpio, flags,
                        template->name);
        if (ret < 0)
            return ret;

        led_dat->gpiod = gpio_to_desc(template->gpio);						//	获取gpio组
        if (!led_dat->gpiod)
            return -EINVAL;
    }

    led_dat->cdev.name = template->name;									//	赋值一些属性信息
    led_dat->cdev.default_trigger = template->default_trigger;
    led_dat->can_sleep = gpiod_cansleep(led_dat->gpiod);
    if (!led_dat->can_sleep)
        led_dat->cdev.brightness_set = gpio_led_set;						//	设置LED
    else
        led_dat->cdev.brightness_set_blocking = gpio_led_set_blocking;
    led_dat->blinking = 0;
    if (blink_set) {
        led_dat->platform_gpio_blink_set = blink_set;
        led_dat->cdev.blink_set = gpio_blink_set;
    }
    if (template->default_state == LEDS_GPIO_DEFSTATE_KEEP) {
        state = gpiod_get_value_cansleep(led_dat->gpiod);
        if (state < 0)
            return state;
    } else {
        state = (template->default_state == LEDS_GPIO_DEFSTATE_ON);
    }
    led_dat->cdev.brightness = state ? LED_FULL : LED_OFF;
    if (!template->retain_state_suspended)
        led_dat->cdev.flags |= LED_CORE_SUSPENDRESUME;
    if (template->panic_indicator)
        led_dat->cdev.flags |= LED_PANIC_INDICATOR;
    if (template->retain_state_shutdown)
        led_dat->cdev.flags |= LED_RETAIN_AT_SHUTDOWN;

    ret = gpiod_direction_output(led_dat->gpiod, state);
    if (ret < 0)
        return ret;

    return devm_of_led_classdev_register(parent, np, &led_dat->cdev);		//	将LED设备注册到子系统中
}
```

**函数介绍**：`create_gpio_led`创建`LED`设备的核心函数

**实现思路**：

1.  先通过`gpio_is_valid`接口，判断`GPIO`是否合法
2.  将上层从设备树解析出来的信息，填充到`gpio_led_data`字段中，并且初始化部分字段，如：`led_classdev`、`gpio_desc`等
3.  填充回调函数，实现相应的动作，如：`gpio_led_set`、`gpio_led_set_blocking`、`gpio_blink_set`等
4.  最后调用`devm_of_led_classdev_register`接口，将`LED`设备注册到`LED`框架之中。

## 4、回调函数分析

> 硬件驱动层，肯定包括最终操作硬件的部分，也就是上面提到的一些回调函数，属于我们驱动工程师开发的内容。

### 4.1 gpio\_blink\_set

```C
static int gpio_blink_set(struct led_classdev *led_cdev,
    unsigned long *delay_on, unsigned long *delay_off)
{
    struct gpio_led_data *led_dat = cdev_to_gpio_led_data(led_cdev);

    led_dat->blinking = 1;
    return led_dat->platform_gpio_blink_set(led_dat->gpiod, GPIO_LED_BLINK,
                        delay_on, delay_off);
}
```

**函数介绍**：`gpio_blink_set`主要用于设置闪烁的时延

### 4.2 gpio\_led\_set 和gpio\_led\_set_blocking

```c
static inline struct gpio_led_data *
            cdev_to_gpio_led_data(struct led_classdev *led_cdev)
{
    return container_of(led_cdev, struct gpio_led_data, cdev);
}

static void gpio_led_set(struct led_classdev *led_cdev,
    enum led_brightness value)
{
    struct gpio_led_data *led_dat = cdev_to_gpio_led_data(led_cdev);
    int level;

    if (value == LED_OFF)
        level = 0;
    else
        level = 1;

    if (led_dat->blinking) {
        led_dat->platform_gpio_blink_set(led_dat->gpiod, level,
                         NULL, NULL);
        led_dat->blinking = 0;
    } else {
        if (led_dat->can_sleep)
            gpiod_set_value_cansleep(led_dat->gpiod, level);
        else
            gpiod_set_value(led_dat->gpiod, level);
    }
}

static int gpio_led_set_blocking(struct led_classdev *led_cdev,
    enum led_brightness value)
{
    gpio_led_set(led_cdev, value);
    return 0;
}
```

**函数介绍**：`gpio_led_set` 和`gpio_led_set_blocking`主要用于设置亮度，区别在于`gpio_led_set` 是不可睡眠的，`gpio_led_set_blocking`是可休眠的。

## 5、总结

上面我们了解了硬件驱动层的实现流程以及相关数据结构，总结来看：

### 5.1 数据结构之间的关系如下

![LED子系统-LED数据结构.drawio](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/LED%E5%AD%90%E7%B3%BB%E7%BB%9F-LED%E6%95%B0%E6%8D%AE%E7%BB%93%E6%9E%84.drawio.png)

### 5.2 函数实现流程如下

```C
gpio_led_probe(drivers/leds/leds-gpio.c)
    |--> gpio_leds_create
        |--> create_gpio_led            //  创建LED设备
            |--> devm_of_led_classdev_register      
```

### 5.3 主要作用如下

1.  从设备树获取`LED`相关属性信息，赋值给`gpio_led`结构体
2.  将`gpio_led`、`gpio_leds_priv`、`led_classdev`等数据结构关联起来
3.  将`LED`设备注册进入`LED`子系统中


<center><b> <font color ="blue">欢迎关注【嵌入式艺术】，董哥原创！</font></b></center>
<div align=center><img src="https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/blog.png" alt="img" width = "60%" height ="10%"/>
</div>
