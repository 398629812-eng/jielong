# 成语接龙游戏数据

本目录包含成语接龙游戏的核心数据文件及生成/验证脚本。

## 文件说明

| 文件 | 说明 |
|------|------|
| `idioms.json` | 主数据文件，包含 10000+ 条常用四字成语，用于游戏接龙验证与提示 |
| `generate_idioms.py` | 数据生成脚本，从开源成语数据库下载并筛选、格式化 |
| `validate_idioms.py` | 数据验证脚本，检查数量、重复、字段完整性、接龙覆盖率 |
| `README.md` | 本文件 |

## 数据字段

每条成语包含以下字段：

```json
{
  "idiom": "一心一意",
  "pinyin": "yī xīn yī yì",
  "pinyin_no_tones": "yi xin yi yi",
  "first_char": "一",
  "first_pinyin": "yī",
  "first_pinyin_no_tone": "yi",
  "last_char": "意",
  "last_pinyin": "yì",
  "last_pinyin_no_tone": "yi",
  "meaning": "心思、意念专一。"
}
```

## 数据质量

- **总数**：10,010 条（≥ 10,000 要求）
- **格式**：全部为标准四字成语
- **拼音**：带声调拼音，经严格字符校验
- **接龙覆盖率**：100%（每条成语的尾字拼音均能在库中找到 ≥ 3 条可接成语）
- **死胡同**：0 条
- **重复**：0 条
- **首字拼音种类**：370 种
- **尾字拼音种类**：32 种

## 数据来源与处理

原始数据来源于开源项目 [crazywhalecc/idiom-database](https://github.com/crazywhalecc/idiom-database)，
该项目基于 [chinese-xinhua](https://github.com/pwxcoo/chinese-xinhua) 进行优化，
包含 30,000+ 条成语，已预先标注无调拼音和首尾字母拼音。

处理流程：

1. 从 CDN 下载原始 JSON（约 14.8 MB，30,895 条）
2. 筛选有效四字成语（29,502 条）
3. 过滤拼音异常字符（如 `@`、`?` 等）
4. 排除尾字为 `也、乎、于、之、矣、焉、哉` 等难以接龙的成语
5. 按尾字拼音频率排序，优先保留高频尾字（更容易接龙）
6. 迭代验证接龙覆盖率，确保每条尾字拼音都有 ≥ 3 条可接成语
7. 取前 10,010 条，生成最终 JSON

## 运行脚本

```bash
# 重新生成数据（需要联网）
python generate_idioms.py

# 验证数据质量
python validate_idioms.py
```

## 验证报告摘要

- 总数检查：10,010 条 ✅
- 重复检查：0 条重复 ✅
- 字段完整性：100% 完整 ✅
- 四字成语检查：100% 标准四字 ✅
- 接龙覆盖率：100%（10,010/10,010）✅
- 死胡同数量：0 条 ✅

可接龙链示例（10 步）：

```
1. 一丁不识
2. 识微见远
3. 远志高歌
4. 歌功颂德
5. 德重恩弘
6. 弘奖风流
7. 流连忘返
8. 返老还童
9. 童心未泯
10. 泯然众人
```

*注：接龙链为随机生成，每次运行可能不同。*

## 使用方式

Flutter 客户端可将 `idioms.json` 打包到 assets 目录，游戏启动时加载到内存：

```dart
final idioms = jsonDecode(await rootBundle.loadString('assets/idioms.json'));
```

后端 API 亦可将此数据导入 MySQL，用于服务端验证和提示算法。
