---
date: '2024-01-19T21:15:18+08:00'
title:       '【MMC子系统】四、MMC控制器驱动层'
description: ""
author:      "Donge"
image:       ""
tags:        ["MMC子系统", "MMC/SD/SDIO", "Linux驱动开发"]
categories:  ["Tech" ]
weight: 4
---

# 【MMC子系统】四、MMC控制器驱动层

`MMC`控制器驱动层一般为`chip manufacturer`做的事，不同的芯片实现方式不尽相同。

> `Linux`内核源码，相当大的一部分都是由`Device Drivers`程序代码组成，其次另一大部分就是那些你从来都没有听说过的`Filesystem Format`组成，真正核心的代码非常短小精悍的。

当然，设备驱动程序也有一套既定的框架，按照框架来编写，实现对应的接口就可以了，在这里，我们主要分析一下`MMC`控制器驱动的实现框架，不拘泥于细节。

> 下文以`sunxi-mmc.c`为例来分析，基于`Linux4.19`

&nbsp;

## 4.1 通用驱动框架

```c
static int sunxi_mmc_probe(struct platform_device *pdev) {
    .....
}

static const struct of_device_id sunxi_mmc_of_match[] = {
    { .compatible = "allwinner,sun4i-a10-mmc", .data = &sun4i_a10_cfg },
    { .compatible = "allwinner,sun5i-a13-mmc", .data = &sun5i_a13_cfg },
    { .compatible = "allwinner,sun7i-a20-mmc", .data = &sun7i_a20_cfg },
    { .compatible = "allwinner,sun8i-a83t-emmc", .data = &sun8i_a83t_emmc_cfg },
    { .compatible = "allwinner,sun9i-a80-mmc", .data = &sun9i_a80_cfg },
    { .compatible = "allwinner,sun50i-a64-mmc", .data = &sun50i_a64_cfg },
    { .compatible = "allwinner,sun50i-a64-emmc", .data = &sun50i_a64_emmc_cfg },
    { /* sentinel */ }
};
MODULE_DEVICE_TABLE(of, sunxi_mmc_of_match);


static const struct dev_pm_ops sunxi_mmc_pm_ops = {
    SET_RUNTIME_PM_OPS(sunxi_mmc_runtime_suspend,
               sunxi_mmc_runtime_resume,
               NULL)
};

static struct platform_driver sunxi_mmc_driver = {
    .driver = {
        .name	= "sunxi-mmc",
        .of_match_table = of_match_ptr(sunxi_mmc_of_match),
        .pm = &sunxi_mmc_pm_ops,
    },
    .probe		= sunxi_mmc_probe,
    .remove		= sunxi_mmc_remove,
};
module_platform_driver(sunxi_mmc_driver);

MODULE_DESCRIPTION("Allwinner's SD/MMC Card Controller Driver");
MODULE_LICENSE("GPL v2");
MODULE_AUTHOR("David Lanzendörfer <david.lanzendoerfer@o2s.ch>");
MODULE_ALIAS("platform:sunxi-mmc");
```

这套基本的框架，老生常谈，其主要功能就是：按照`of_match_table`匹配表，来实现`platform_device`和`platform_driver`的匹配，然后执行`probe`函数。

&nbsp;

## 4.2 注册与注销函数

```c
static int sunxi_mmc_probe(struct platform_device *pdev) {
    .....
}

static int sunxi_mmc_remove(struct platform_device *pdev) {
    ......
}
```

比较重要的两个函数，我们一般`insmod xxx.ko`后，执行完`_init`函数后，最终如果设备树和驱动匹配成功，会调用`probe`函数，相同，卸载驱动时，也会调用到`remove`函数。

### 4.2.1 probe函数

> `probe`函数很长，我们挑重点来了解

```c
static int sunxi_mmc_probe(struct platform_device *pdev)
{
    struct sunxi_mmc_host *host;
    struct mmc_host *mmc;
    int ret;

    mmc = mmc_alloc_host(sizeof(struct sunxi_mmc_host), &pdev->dev);
    if (!mmc) {
        dev_err(&pdev->dev, "mmc alloc host failed\n");
        return -ENOMEM;
    }
    platform_set_drvdata(pdev, mmc);

    host = mmc_priv(mmc);
    host->dev = &pdev->dev;
    host->mmc = mmc;
    spin_lock_init(&host->lock);

    // 1. 获取设备树资源
    ret = sunxi_mmc_resource_request(host, pdev);
    if (ret)
        goto error_free_host;

    ......

    // 2. 初始化MMC控制器
    mmc->ops		= &sunxi_mmc_ops;
    mmc->max_blk_count	= 8192;
    mmc->max_blk_size	= 4096;
    mmc->max_segs		= PAGE_SIZE / sizeof(struct sunxi_idma_des);
    mmc->max_seg_size	= (1 << host->cfg->idma_des_size_bits);
    mmc->max_req_size	= mmc->max_seg_size * mmc->max_segs;
    /* 400kHz ~ 52MHz */
    mmc->f_min		=   400000;
    mmc->f_max		= 52000000;
    mmc->caps	       |= MMC_CAP_MMC_HIGHSPEED | MMC_CAP_SD_HIGHSPEED |
                  MMC_CAP_ERASE | MMC_CAP_SDIO_IRQ;

    if (host->cfg->clk_delays || host->use_new_timings)
        mmc->caps      |= MMC_CAP_1_8V_DDR | MMC_CAP_3_3V_DDR;

    ret = mmc_of_parse(mmc);
    if (ret)
        goto error_free_dma;

    /* TODO: This driver doesn't support HS400 mode yet */
    mmc->caps2 &= ~MMC_CAP2_HS400;

    ret = sunxi_mmc_init_host(host);
    if (ret)
        goto error_free_dma;
    
    .......

    // 3. 将mmc控制器加入到子系统中
    ret = mmc_add_host(mmc);
    if (ret)
        goto error_free_dma;

    dev_info(&pdev->dev, "initialized, max. request size: %u KB%s\n",
         mmc->max_req_size >> 10,
         host->use_new_timings ? ", uses new timings mode" : "");

    return 0;

error_free_dma:
    dma_free_coherent(&pdev->dev, PAGE_SIZE, host->sg_cpu, host->sg_dma);
error_free_host:
    mmc_free_host(mmc);
    return ret;
}


```

**函数作用**：从设备树获取配置信息，并初始化`mmc`控制器，最后将`mmc`加入到子系统中。

> 上面代码已经作了简单注释

### 4.2.2 remove函数

`remove`函数看起来就比较简单了，就是`probe`函数的反操作

```c
static int sunxi_mmc_remove(struct platform_device *pdev)
{
    struct mmc_host	*mmc = platform_get_drvdata(pdev);
    struct sunxi_mmc_host *host = mmc_priv(mmc);

    // 1. 移除子系统
    mmc_remove_host(mmc);
    pm_runtime_force_suspend(&pdev->dev);
    disable_irq(host->irq);
    sunxi_mmc_disable(host);
    dma_free_coherent(&pdev->dev, PAGE_SIZE, host->sg_cpu, host->sg_dma);
    
    // 2. 释放mmc内存
    mmc_free_host(mmc);

    return 0;
}

```

**函数作用**：将`mmc`移除子系统，并释放内存。

&nbsp;

> 更多干货可见：[高级工程师聚集地](https://t.zsxq.com/0eUcTOhdO)，助力大家更上一层楼！

&nbsp

## 4.3 ops函数实现

了解过基本驱动框架的都知道，最为核心的就是`ops`相关的接口了，上层调用底层代码，全靠它。

在`probe`函数中，我们看到`mmc->ops = &sunxi_mmc_ops`的代码，就是注册了`ops`结构体，最后通过`mmc_add_host`接口，打通核心层与`MMC`控制器驱动层的界限。

```c
static const struct mmc_host_ops sunxi_mmc_ops = {
    .request	 = sunxi_mmc_request,
    .set_ios	 = sunxi_mmc_set_ios,
    .get_ro		 = mmc_gpio_get_ro,
    .get_cd		 = mmc_gpio_get_cd,
    .enable_sdio_irq = sunxi_mmc_enable_sdio_irq,
    .start_signal_voltage_switch = sunxi_mmc_volt_switch,
    .hw_reset	 = sunxi_mmc_hw_reset,
    .card_busy	 = sunxi_mmc_card_busy,
};

```

- `.request`：上层发送命令请求
- `.set_ios`：上层设置时钟频率，总线数量的接口
- `.get_ro`：表示卡的读写状态
- `.get_cd`：检测卡是否存在的接口
- `.enable_sdio_irq`：提供给上层打开`sdio`中断的接口
- `.hw_reset`：硬件重置接口
- `.card_busy`：反映卡的状态接口

具体怎么实现，就是`chip manufacturer`做的事情，我们这里只需要知道，上层通过封装的接口，最终通过`ops->xxx`函数来将控制寄存器进行数据传输。

## 4.4 PM接口

`PM`就是我们说的`Power Manager`电源管理，用于功耗控制。

```c
#ifdef CONFIG_PM
static int sunxi_mmc_runtime_resume(struct device *dev)
{
    struct mmc_host	*mmc = dev_get_drvdata(dev);
    struct sunxi_mmc_host *host = mmc_priv(mmc);
    int ret;

    ret = sunxi_mmc_enable(host);
    if (ret)
        return ret;

    sunxi_mmc_init_host(host);
    sunxi_mmc_set_bus_width(host, mmc->ios.bus_width);
    sunxi_mmc_set_clk(host, &mmc->ios);
    enable_irq(host->irq);

    return 0;
}

static int sunxi_mmc_runtime_suspend(struct device *dev)
{
    struct mmc_host	*mmc = dev_get_drvdata(dev);
    struct sunxi_mmc_host *host = mmc_priv(mmc);

    /*
     * When clocks are off, it's possible receiving
     * fake interrupts, which will stall the system.
     * Disabling the irq  will prevent this.
     */
    disable_irq(host->irq);
    sunxi_mmc_reset_host(host);
    sunxi_mmc_disable(host);

    return 0;
}
#endif

```

**其主要功能就是**：确保休眠时，所有外设的时钟使能需要关闭，来确保功耗最低。

&nbsp;

`MMC`控制器驱动就是就是这么简单，不需要过多了解的，咱们就先不关心，聚焦于整个框架。


<center><b> <font color ="blue">欢迎关注【嵌入式艺术】，董哥原创！</font></b></center>
<div align=center><img src="https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/blog.png" alt="img" width = "60%" height ="10%"/>
</div>
