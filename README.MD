RDbItems
===========

只适合于 WOW 1.12 版本，数据提取自以前 N 服 MySql，因此没有 Turtle Wow 的新物品数据。

- 显示物品相对应的中/英文名称，和物品等级

- 当`shift + 点击` 物品或任务（依赖pfQuest）时可选择中文或英文标题

- 显示物品出售价格（ShaguTweaks，pfUI 或其它插件已经提供了此功能）

  如果你使用了别的插件用于"显示物品价格"，可以运行如下语句

  ```
  # 关闭此插件的 "显示物品价格"
  /run RDbItemsCfg.NoPrice = 1
  
  # 如果你想恢复显示
  /run RDbItemsCfg.NoPrice = nil
  ```

对于 pfUI 如果你看不见汉字，需要将 `ESC -> pfUI Config -> Setting(默认设置) -> Stand text font(标准字体)` 设为 "ARIALN" 或者 "FRIZQT"

## 更新

2.2.X :
  修正了 "AtlasLoot 专业技能相关物品" 的显示

2.2.3 :
  修正了由于 "数量" 导致的价格显示错误

2.2.2 :
  移除了邮箱物品的 Tooltip 显示（错误无效的 API）
  添加了对 PfQuest 的支持

2.2.1 : 修正了点击链接的翻译
2.2.0 : 兼容 pfUI