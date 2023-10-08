RDbItems
===========

只适合于 WOW 1.12 版本，数据提取自以前 N 服 MySql，因此没有 Turtle Wow 的新物品数据。

## 安装

1. 首先下载 [RDbItems-master](https://github.com/likesc/RDbItems/archive/refs/heads/master.zip), 如果是乌龟服(turtle)则下载 [RDbItems-turtle](https://github.com/likesc/RDbItems/archive/refs/heads/turtle.zip)
2. 之后解压到 `Interface\AddOns` 目录下,
3. 把解压后的文件夹名更改为 `RDbItems` 即可

## 设置

- 在 GameTooltip 上显示物品相对应的中/英文名称

  ```
  # 关闭
  /run RDbItemsCfg.NoName = 1

  # 开启(默认)
  /run RDbItemsCfg.NoName = nil
  ```

- 当`shift + 点击` 物品或任务（依赖pfQuest）时可选择中文或英文标题

- 在 GameTooltip 上显示物品出售价格(ShaguTweaks, pfUI 或其它插件已经提供了此功能), 和物品等级

  如果你使用了别的同类型插件, 可以如下关闭或启用

  ```
  # 关闭
  /run RDbItemsCfg.NoPrice = 1

  # 开启(默认)
  /run RDbItemsCfg.NoPrice = nil
  ```

- 高亮背包中最便宜的垃圾物品，打开背包按下 `Ctrl` 键即可 (注意是灰色的垃圾物品而不是白色物品)

  ```
  # 关闭, 需要重载插件
  /run RDbItemsCfg.NoCheapest = 1

  # 开启(默认), 需要重载插件
  /run RDbItemsCfg.NoCheapest = nil

  # 重载插件
  /console reloadui
  ```

对于 pfUI 如果你看不见汉字，需要将 `ESC -> pfUI Config -> Setting(默认设置) -> Stand text font(标准字体)` 设为 "ARIALN" 或者 "FRIZQT"

## 更新

2.2.X :
  - 添加了查找背包内 "最便宜的垃圾物品", 目前仅可用于：原始背包, pfUI, Bagnon, OneBag, SUCC_bag(未测试)
  - 修正了 "AtlasLoot 专业技能相关物品" 的显示

2.2.3 :
  - 修正了由于 "数量" 导致的价格显示错误

2.2.2 :
  - 移除了邮箱物品的 Tooltip 显示（错误无效的 API）
  - 添加了对 PfQuest 的支持

2.2.1 : 修正了点击链接的翻译
2.2.0 : 兼容 pfUI
