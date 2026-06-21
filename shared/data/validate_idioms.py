#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
验证成语数据文件质量
检查项：
1. 总数 >= 10000
2. 无重复成语
3. 每条成语字段完整
4. 尾字拼音可接数量分布（找出死胡同）
5. 生成可接龙链示例
"""

import json
import os
import random
import sys

DATA_FILE = os.path.join(os.path.dirname(__file__), 'idioms.json')


def load_data():
    with open(DATA_FILE, 'r', encoding='utf-8') as f:
        return json.load(f)


def check_count(data):
    total = len(data)
    passed = total >= 10000
    print(f"[1] 总数检查：{total} 条成语 {'✅ 通过' if passed else '❌ 失败（要求>=10000）'}")
    return passed, total


def check_duplicates(data):
    seen = set()
    duplicates = []
    for item in data:
        word = item['idiom']
        if word in seen:
            duplicates.append(word)
        seen.add(word)
    passed = len(duplicates) == 0
    print(f"[2] 重复检查：发现 {len(duplicates)} 条重复 {'✅ 通过' if passed else '❌ 失败'}")
    if duplicates:
        print(f"    重复示例：{duplicates[:10]}")
    return passed, len(duplicates)


def check_fields(data):
    required_fields = [
        'idiom', 'pinyin', 'pinyin_no_tones',
        'first_char', 'first_pinyin', 'first_pinyin_no_tone',
        'last_char', 'last_pinyin', 'last_pinyin_no_tone',
        'meaning'
    ]
    bad_items = []
    for i, item in enumerate(data):
        missing = [f for f in required_fields if not item.get(f)]
        if missing:
            bad_items.append((i, item.get('idiom', 'UNKNOWN'), missing))
    passed = len(bad_items) == 0
    print(f"[3] 字段完整性：发现 {len(bad_items)} 条字段缺失 {'✅ 通过' if passed else '❌ 失败'}")
    if bad_items:
        print(f"    缺失示例：{bad_items[:5]}")
    return passed, len(bad_items)


def check_four_char(data):
    bad = []
    for item in data:
        word = item['idiom']
        if len(word) != 4 or not all('\u4e00' <= c <= '\u9fff' for c in word):
            bad.append(word)
    passed = len(bad) == 0
    print(f"[4] 四字成语检查：发现 {len(bad)} 条非标准四字成语 {'✅ 通过' if passed else '❌ 失败'}")
    if bad:
        print(f"    异常示例：{bad[:10]}")
    return passed, len(bad)


def analyze_coverage(data, min_count=3):
    """分析尾字拼音可接数量分布"""
    # 建立首字拼音到成语列表的映射
    first_map = {}
    for item in data:
        fp = item['first_pinyin_no_tone']
        first_map.setdefault(fp, []).append(item['idiom'])

    # 统计每个尾字拼音的可接数量
    coverage_stats = {}
    dead_ends = []
    for item in data:
        lp = item['last_pinyin_no_tone']
        count = len(first_map.get(lp, []))
        coverage_stats[lp] = coverage_stats.get(lp, 0) + 1
        if count < min_count:
            dead_ends.append((item['idiom'], lp, count))

    ok_count = len(data) - len(dead_ends)
    coverage_ratio = ok_count / len(data) if data else 0

    print(f"[5] 接龙覆盖率分析：")
    print(f"    满足可接数量>=3的成语：{ok_count}/{len(data)} ({coverage_ratio:.2%})")
    print(f"    死胡同数量：{len(dead_ends)}")
    if dead_ends:
        print(f"    死胡同示例（前10条）：{dead_ends[:10]}")

    # 分布统计
    print(f"    首字拼音种类：{len(first_map)}")
    print(f"    尾字拼音种类：{len(set(item['last_pinyin_no_tone'] for item in data))}")

    # 可接数量分布直方图
    dist = {}
    for item in data:
        lp = item['last_pinyin_no_tone']
        count = len(first_map.get(lp, []))
        bucket = min(count // 10, 10) * 10
        dist[bucket] = dist.get(bucket, 0) + 1

    print(f"    可接数量分布（按尾字拼音）：")
    for bucket in sorted(dist.keys()):
        upper = bucket + 9 if bucket < 100 else '100+'
        print(f"      [{bucket:>3}-{upper:>3}] : {dist[bucket]:>5} 条")

    return coverage_ratio, dead_ends, first_map


def build_chain(data, first_map, length=10):
    """生成一条可接龙链示例"""
    random.seed(42)
    start = random.choice(data)
    chain = [start['idiom']]
    current = start

    for _ in range(length - 1):
        lp = current['last_pinyin_no_tone']
        candidates = first_map.get(lp, [])
        if not candidates:
            break
        # 选一个还没用过的
        next_idiom = random.choice(candidates)
        if next_idiom in chain:
            # 尝试找没用过的
            unused = [c for c in candidates if c not in chain]
            if not unused:
                break
            next_idiom = random.choice(unused)
        chain.append(next_idiom)
        # 更新 current
        for item in data:
            if item['idiom'] == next_idiom:
                current = item
                break

    return chain


def main():
    print("=" * 60)
    print("成语数据验证报告")
    print("=" * 60)

    if not os.path.exists(DATA_FILE):
        print(f"❌ 数据文件不存在：{DATA_FILE}")
        sys.exit(1)

    data = load_data()
    print(f"数据文件加载成功：{DATA_FILE}")
    print(f"文件大小：{os.path.getsize(DATA_FILE) / 1024 / 1024:.2f} MB")
    print()

    # 执行各项检查
    results = []
    results.append(check_count(data))
    results.append(check_duplicates(data))
    results.append(check_fields(data))
    results.append(check_four_char(data))

    coverage_ratio, dead_ends, first_map = analyze_coverage(data)
    passed = coverage_ratio >= 0.80
    results.append((passed, f"覆盖率 {coverage_ratio:.2%}"))

    print()

    # 生成接龙链示例
    chain = build_chain(data, first_map, 10)
    print(f"[6] 可接龙链示例（{len(chain)} 步）：")
    for i, word in enumerate(chain):
        print(f"    {i+1}. {word}")
    print()

    # 汇总
    print("=" * 60)
    print("验证汇总")
    print("=" * 60)
    all_passed = all(r[0] for r in results)
    for i, (passed, detail) in enumerate(results, 1):
        status = '✅ 通过' if passed else '❌ 失败'
        print(f"  检查项 {i}：{status} ({detail})")

    print()
    if all_passed:
        print("🎉 所有验证项通过！")
    else:
        print("⚠️ 部分验证项未通过，请检查数据质量。")

    return 0 if all_passed else 1


if __name__ == '__main__':
    sys.exit(main())
