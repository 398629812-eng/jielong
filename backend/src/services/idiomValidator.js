/**
 * 成语接龙验证算法核心模块（idiomValidator.js）
 * --------------------------------------------------
 * 本模块负责加载成语数据、验证接龙规则、查找后续成语等核心逻辑。
 * 数据加载到内存 Map，利用拼音索引实现 O(1) 级别的首字匹配查询。
 * 所有方法均包含详细中文注释，说明算法意图和边界情况。
 */

const fs = require('fs');
const path = require('path');

// 成语数据 Map：键为成语本身，值为成语详情对象
const idiomMap = new Map();
// 尾字拼音索引 Map：键为尾字拼音（无声调），值为成语数组
// 用于快速查找"可以接龙"的候选成语
const tailPinyinIndex = new Map();
// 首字拼音索引 Map：键为首字拼音（无声调），值为成语数组
const firstPinyinIndex = new Map();

/**
 * 模块初始化：加载 idioms.json 到内存索引
 * 路径相对于 backend 目录，向上两级到 jielong 根目录下的 shared/data/idioms.json
 */
function loadIdioms() {
  // 尝试多种可能的路径（适配 git worktree 和常规目录结构）
  const candidates = [
    path.join(__dirname, '..', '..', '..', 'shared', 'data', 'idioms.json'),      // 常规结构: backend/src/services -> jielong/shared/data
    path.join(__dirname, '..', '..', '..', '..', 'shared', 'data', 'idioms.json'), // git worktree 多一层
    path.join(process.cwd(), 'shared', 'data', 'idioms.json')                       // 从运行目录查找
  ];

  let idiomPath = null;
  for (const p of candidates) {
    if (fs.existsSync(p)) {
      idiomPath = p;
      break;
    }
  }

  if (!idiomPath) {
    console.warn('⚠️ 成语数据文件未找到，尝试路径:', candidates.join(', '));
    return;
  }

  const raw = fs.readFileSync(idiomPath, 'utf-8');
  const idioms = JSON.parse(raw);

  for (const item of idioms) {
    // 1. 存入成语总表
    idiomMap.set(item.idiom, item);

    // 2. 按尾字拼音（无声调）建立索引，用于查找"下一个可接成语"
    const tailNoTone = item.last_pinyin_no_tone;
    if (!tailPinyinIndex.has(tailNoTone)) {
      tailPinyinIndex.set(tailNoTone, []);
    }
    tailPinyinIndex.get(tailNoTone).push(item);

    // 3. 按首字拼音（无声调）建立索引，用于查找"以某拼音开头的成语"
    const firstNoTone = item.first_pinyin_no_tone;
    if (!firstPinyinIndex.has(firstNoTone)) {
      firstPinyinIndex.set(firstNoTone, []);
    }
    firstPinyinIndex.get(firstNoTone).push(item);
  }

  console.log(`✅ 成语数据加载完成：共 ${idiomMap.size} 条成语，索引构建完毕`);
}

// 立即执行加载
try {
  loadIdioms();
} catch (err) {
  console.error('❌ 成语数据加载失败:', err.message);
}

/**
 * 验证玩家输入的成语是否合法
 * --------------------------------------------------
 * 规则：
 * 1. 成语必须存在于成语库中（防止伪造）；
 * 2. 成语首字拼音必须与上一个成语的尾字拼音匹配（接龙规则）；
 * 3. 成语不能已经被使用过（防止重复接龙）。
 *
 * @param {string} idiom - 玩家输入的成语
 * @param {string} previousTailPinyin - 上一个成语的尾字拼音（无声调，如 'shi'）
 * @param {Set<string>} usedIdioms - 本局游戏中已使用的成语集合
 * @param {boolean} allowDifferentTone - 是否允许同音不同调（默认 false，严格匹配声调）
 * @returns {object} { valid: boolean, message?: string, detail?: object }
 */
function validateIdiom(idiom, previousTailPinyin, usedIdioms, allowDifferentTone = false) {
  // 空值检查
  if (!idiom || typeof idiom !== 'string') {
    return { valid: false, message: '成语不能为空' };
  }

  // 去除首尾空白，统一使用原始字符串（成语通常含空格，但数据中不带空格）
  const trimmed = idiom.trim();
  if (trimmed.length === 0) {
    return { valid: false, message: '成语不能为空' };
  }

  // 规则 1：检查成语是否存在于成语库
  const detail = idiomMap.get(trimmed);
  if (!detail) {
    return { valid: false, message: `「${trimmed}」不是有效的成语，请重新输入` };
  }

  // 规则 3：检查成语是否已被使用
  if (usedIdioms && usedIdioms.has(trimmed)) {
    return { valid: false, message: `「${trimmed}」已经在本局游戏中使用过，请换一个成语` };
  }

  // 规则 2：检查首字拼音是否匹配上一个成语的尾字拼音
  // 如果 previousTailPinyin 为空（如第一回合），则跳过匹配检查
  if (previousTailPinyin) {
    const prevTail = previousTailPinyin.trim().toLowerCase();
    const currFirst = allowDifferentTone
      ? detail.first_pinyin_no_tone.toLowerCase()
      : detail.first_pinyin.toLowerCase();

    if (allowDifferentTone) {
      // 宽松模式：仅比较无声调拼音（如 'shi' === 'shi'）
      if (currFirst !== prevTail) {
        return {
          valid: false,
          message: `接龙错误：「${trimmed}」首字拼音为「${detail.first_pinyin}」，需要接「${previousTailPinyin}」开头的成语`,
          detail
        };
      }
    } else {
      // 严格模式：比较带声调拼音（如 'shí' === 'shí'）
      // 这里将 previousTailPinyin 视为带声调或不带声调均可，优先严格匹配
      const strictMatch = detail.first_pinyin.toLowerCase() === prevTail;
      const looseMatch = detail.first_pinyin_no_tone.toLowerCase() === prevTail;
      if (!strictMatch && !looseMatch) {
        return {
          valid: false,
          message: `接龙错误：「${trimmed}」首字拼音为「${detail.first_pinyin}」，需要接「${previousTailPinyin}」开头的成语`,
          detail
        };
      }
    }
  }

  return { valid: true, detail };
}

/**
 * 查找可接龙的后续成语
 * --------------------------------------------------
 * 根据上一个成语的尾字拼音，查找所有可以接龙的成语。
 * 根据难度参数对结果进行筛选和排序：
 * - easy（简单）：随机返回，不限定范围，让玩家有更多选择；
 * - normal（普通）：倾向于返回尾字生僻的成语，压缩后续可选范围；
 * - hard（困难）：大幅压缩可选范围，返回尾字非常生僻的成语，或可选数量极少的尾字。
 *
 * @param {string} tailPinyin - 上一个成语的尾字拼音（无声调，如 'shi'）
 * @param {Set<string>} usedIdioms - 已使用的成语集合（避免重复）
 * @param {boolean} allowDifferentTone - 是否允许同音不同调
 * @param {string} difficulty - 难度：'easy' | 'normal' | 'hard'，默认 'easy'
 * @returns {Array<object>} 可接龙的成语列表（按难度排序后）
 */
function findNextIdioms(tailPinyin, usedIdioms, allowDifferentTone = false, difficulty = 'easy') {
  if (!tailPinyin) {
    return [];
  }

  const target = tailPinyin.trim().toLowerCase();
  // 从首字拼音索引中查找所有匹配的成语
  let candidates = firstPinyinIndex.get(target) || [];

  if (allowDifferentTone && candidates.length === 0) {
    // 宽松模式下，如果严格匹配无结果，尝试遍历所有同音字（无声调相同）
    // 注意：这里 target 已经是无声调拼音，所以直接查 firstPinyinIndex 即可
    // 如果无结果，则返回空数组
  }

  // 过滤掉已使用的成语
  candidates = candidates.filter(item => !usedIdioms || !usedIdioms.has(item.idiom));

  if (candidates.length === 0) {
    return [];
  }

  // 根据难度进行筛选/排序
  if (difficulty === 'easy') {
    // 简单模式：随机打乱，让玩家有丰富选择
    // Fisher-Yates 洗牌算法
    for (let i = candidates.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [candidates[i], candidates[j]] = [candidates[j], candidates[i]];
    }
    return candidates;
  }

  if (difficulty === 'normal') {
    // 普通模式：倾向于返回尾字拼音对应成语数量较少的成语
    // 即：选择后续接龙范围更窄的成语，增加难度但不至于无解
    candidates.sort((a, b) => {
      const aNextCount = (tailPinyinIndex.get(a.last_pinyin_no_tone) || []).length;
      const bNextCount = (tailPinyinIndex.get(b.last_pinyin_no_tone) || []).length;
      return aNextCount - bNextCount; // 尾字后续选择少的排在前面
    });
    return candidates;
  }

  if (difficulty === 'hard') {
    // 困难模式：大幅压缩可选范围
    // 优先选择尾字拼音对应的后续成语数量极少（<=3）或完全没有的成语
    // 同时打乱，增加不可预测性
    const hardCandidates = candidates.filter(item => {
      const nextCount = (tailPinyinIndex.get(item.last_pinyin_no_tone) || []).length;
      return nextCount <= 3; // 尾字几乎无解或极难接的成语
    });

    if (hardCandidates.length > 0) {
      // 在困难候选中随机打乱
      for (let i = hardCandidates.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [hardCandidates[i], hardCandidates[j]] = [hardCandidates[j], hardCandidates[i]];
      }
      return hardCandidates;
    }

    // 如果没有极端困难的，退而求其次，返回尾字后续选择最少的
    candidates.sort((a, b) => {
      const aNextCount = (tailPinyinIndex.get(a.last_pinyin_no_tone) || []).length;
      const bNextCount = (tailPinyinIndex.get(b.last_pinyin_no_tone) || []).length;
      return aNextCount - bNextCount;
    });
    return candidates.slice(0, Math.max(1, Math.floor(candidates.length * 0.3)));
  }

  return candidates;
}

/**
 * 获取随机起始成语
 * --------------------------------------------------
 * 用于游戏开始时给玩家或系统一个起始成语。
 * 起始成语应尽量选择尾字后续选择较多的成语，避免游戏一开始就没有可接的成语。
 *
 * @returns {object|null} 随机选中的成语详情，如果数据为空则返回 null
 */
function getRandomStartIdiom() {
  if (idiomMap.size === 0) {
    return null;
  }

  // 将成语总表转换为数组
  const allIdioms = Array.from(idiomMap.values());

  // 简单策略：随机选择，但尽量确保尾字有可接的成语（至少有一个）
  // 最多尝试 50 次，避免死循环
  for (let attempt = 0; attempt < 50; attempt++) {
    const idx = Math.floor(Math.random() * allIdioms.length);
    const candidate = allIdioms[idx];
    const nextCount = (firstPinyinIndex.get(candidate.last_pinyin_no_tone) || []).length;
    if (nextCount > 0) {
      return candidate;
    }
  }

  // 如果 50 次都没找到合适的，直接返回一个随机成语（可能无法继续）
  return allIdioms[Math.floor(Math.random() * allIdioms.length)];
}

/**
 * 获取成语详情
 * --------------------------------------------------
 * 根据成语字符串查询完整详情，包括拼音、释义等。
 *
 * @param {string} idiom - 成语
 * @returns {object|null} 成语详情对象，不存在则返回 null
 */
function getIdiomDetail(idiom) {
  if (!idiom || typeof idiom !== 'string') {
    return null;
  }
  return idiomMap.get(idiom.trim()) || null;
}

/**
 * 获取当前已加载的成语总数
 * @returns {number} 成语总数
 */
function getIdiomCount() {
  return idiomMap.size;
}

module.exports = {
  validateIdiom,
  findNextIdioms,
  getRandomStartIdiom,
  getIdiomDetail,
  getIdiomCount
};
