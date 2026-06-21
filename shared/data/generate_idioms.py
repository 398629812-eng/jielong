#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
生成成语接龙游戏数据文件
数据来源：idiom-database (crazywhalecc/idiom-database)
基于 chinese-xinhua 项目，包含 30000+ 成语，优化了接龙所需的拼音字段
"""

import json
import os
import random
import urllib.request
import ssl

TARGET_DIR = os.path.join(os.path.dirname(__file__), '.')
OUTPUT_FILE = os.path.join(TARGET_DIR, 'idioms.json')

# 难以接龙的尾字，优先排除
BAD_ENDING_CHARS = set('也乎于之矣焉哉兮耳欤耶吁')

# 最小可接数量（保证每个尾字拼音能找到至少这么多可接成语）
MIN_COVERAGE = 3

# 目标成语数量
TARGET_COUNT = 10000


def download_data():
    """从 CDN 下载原始成语数据"""
    url = "https://cdn.jsdelivr.net/gh/crazywhalecc/idiom-database@master/data/idiom.json"
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE

    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    resp = urllib.request.urlopen(req, timeout=30, context=ctx)
    return json.loads(resp.read().decode('utf-8'))


def extract_tones(pinyin_str):
    """从拼音字符串中提取首字和尾字的带调拼音"""
    parts = pinyin_str.strip().split()
    if len(parts) >= 4:
        return parts[0], parts[-1]
    return '', ''


def validate_coverage(idioms, min_count=3):
    """验证接龙覆盖率：每个成语的尾字拼音能否在库中找到至少 min_count 个可接成语"""
    first_map = {}
    for item in idioms:
        fp = item.get('first_pinyin_no_tone', '')
        first_map.setdefault(fp, []).append(item)

    ok_count = 0
    dead_ends = []
    for item in idioms:
        lp = item.get('last_pinyin_no_tone', '')
        count = len(first_map.get(lp, []))
        if count >= min_count:
            ok_count += 1
        else:
            dead_ends.append((item['idiom'], lp, count))

    return ok_count, len(idioms), dead_ends, first_map


def build_database(raw_data):
    """构建高质量的成语接龙数据库"""
    # 1. 筛选有效的四字成语
    four_char = []
    for item in raw_data:
        word = item.get('word', '')
        exp = item.get('explanation', '')
        py = item.get('pinyin', '')
        if (len(word) == 4
                and all('\u4e00' <= c <= '\u9fff' for c in word)
                and py
                and exp
                and exp not in ('无', '暂无', '暂无释义', 'NULL', '')):
            four_char.append(item)

    # 2. 分离优质成语和难以接龙的成语
    good = []
    bad = []
    for item in four_char:
        last_char = item['word'][3]
        if last_char in BAD_ENDING_CHARS:
            bad.append(item)
        else:
            good.append(item)

    # 3. 按尾字拼音频率排序，频率高的优先保留（更容易接龙）
    last_freq = {}
    for item in good:
        lp = item.get('last', '')
        last_freq[lp] = last_freq.get(lp, 0) + 1

    good_sorted = sorted(good, key=lambda x: (-last_freq.get(x.get('last', ''), 0), x['word']))

    # 4. 迭代取词，确保覆盖率达标
    target_size = TARGET_COUNT
    selected = good_sorted[:target_size]
    ok_count, total, dead_ends, first_map = validate_coverage(
        [{
            'idiom': x['word'],
            'first_pinyin_no_tone': x.get('first', ''),
            'last_pinyin_no_tone': x.get('last', '')
        } for x in selected],
        MIN_COVERAGE
    )
    coverage_ratio = ok_count / total if total > 0 else 0

    # 如果覆盖率不足，扩大选取范围
    while coverage_ratio < 0.80 and target_size < len(good_sorted):
        target_size += 500
        selected = good_sorted[:target_size]
        ok_count, total, dead_ends, _ = validate_coverage(
            [{
                'idiom': x['word'],
                'first_pinyin_no_tone': x.get('first', ''),
                'last_pinyin_no_tone': x.get('last', '')
            } for x in selected],
            MIN_COVERAGE
        )
        coverage_ratio = ok_count / total if total > 0 else 0

    # 最终取 TARGET_COUNT 条（如果扩大后更多，取前 TARGET_COUNT）
    final_selected = selected[:TARGET_COUNT]
    if len(final_selected) < TARGET_COUNT:
        needed = TARGET_COUNT - len(final_selected)
        remaining = [x for x in good if x not in final_selected]
        final_selected.extend(remaining[:needed])

    # 5. 转换为输出格式
    output = []
    for item in final_selected:
        word = item['word']
        pinyin = item['pinyin']
        pinyin_no_tones = item.get('pinyin_r', '')
        first_pinyin_tone, last_pinyin_tone = extract_tones(pinyin)
        first_char = word[0]
        last_char = word[3]
        first_pinyin_no_tone = item.get('first', '')
        last_pinyin_no_tone = item.get('last', '')
        meaning = item.get('explanation', '')

        output.append({
            "idiom": word,
            "pinyin": pinyin,
            "pinyin_no_tones": pinyin_no_tones,
            "first_char": first_char,
            "first_pinyin": first_pinyin_tone,
            "first_pinyin_no_tone": first_pinyin_no_tone,
            "last_char": last_char,
            "last_pinyin": last_pinyin_tone,
            "last_pinyin_no_tone": last_pinyin_no_tone,
            "meaning": meaning
        })

    return output


def main():
    print("开始下载成语数据...")
    raw_data = download_data()
    print(f"下载完成，共 {len(raw_data)} 条原始数据")

    print("开始构建数据库...")
    output = build_database(raw_data)
    print(f"构建完成，共 {len(output)} 条成语")

    # 验证覆盖率
    ok_count, total, dead_ends, first_map = validate_coverage(output, MIN_COVERAGE)
    coverage_ratio = ok_count / total if total > 0 else 0
    print(f"接龙覆盖率验证：{ok_count}/{total} = {coverage_ratio:.2%}")
    if dead_ends:
        print(f"死胡同示例（前10条）：{dead_ends[:10]}")

    # 写入文件
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        json.dump(output, f, ensure_ascii=False, indent=2)

    print(f"数据已写入：{OUTPUT_FILE}")
    print(f"文件大小：{os.path.getsize(OUTPUT_FILE) / 1024 / 1024:.2f} MB")


if __name__ == '__main__':
    main()
