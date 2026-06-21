import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.code});

  final String message;
  final int? statusCode;
  final int? code;

  @override
  String toString() => message;
}

/// HTTP API 封装服务
/// 封装所有后端 RESTful API 调用，统一处理认证、错误、超时
/// 所有接口自动附加 Authorization: Bearer <token> Header
class ApiService {
  /// 单例实例
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  /// HTTP 客户端（可复用连接池）
  final http.Client _client = http.Client();

  /// 认证令牌（由 AuthService 登录后设置）
  String? _token;

  /// 设置认证令牌（登录成功后调用）
  void setToken(String? token) {
    _token = token;
  }

  /// 获取当前认证令牌
  String? get token => _token;

  /// 构建请求头（包含认证信息和内容类型）
  Map<String, String> _buildHeaders() {
    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
    };
    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  /// 发送 GET 请求（通用封装）
  ///
  /// [endpoint] API 路径（如 /user/profile）
  /// [queryParams] URL 查询参数（可选）
  /// 返回解析后的 JSON 数据（Map 或 List）
  /// 异常：抛出 Exception 包含错误信息
  Future<dynamic> get(String endpoint,
      {Map<String, String>? queryParams}) async {
    var uri = Uri.parse('${Constants.API_BASE_URL}$endpoint');
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }

    try {
      final response = await _client.get(uri, headers: _buildHeaders()).timeout(
            const Duration(seconds: Constants.READ_TIMEOUT),
            onTimeout: () => throw Exception('请求超时，请检查网络连接'),
          );
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } on SocketException {
      throw Exception('网络连接失败，请检查网络设置');
    } catch (e) {
      throw Exception('GET 请求失败: $e');
    }
  }

  /// 发送 POST 请求（通用封装）
  ///
  /// [endpoint] API 路径（如 /auth/phone-login）
  /// [body] 请求体（Map，自动转换为 JSON）
  /// 返回解析后的 JSON 数据
  Future<dynamic> post(String endpoint, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('${Constants.API_BASE_URL}$endpoint');

    try {
      final response = await _client
          .post(
            uri,
            headers: _buildHeaders(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(
            const Duration(seconds: Constants.READ_TIMEOUT),
            onTimeout: () => throw Exception('请求超时，请检查网络连接'),
          );
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } on SocketException {
      throw Exception('网络连接失败，请检查网络设置');
    } catch (e) {
      throw Exception('POST 请求失败: $e');
    }
  }

  /// 发送 PUT 请求（通用封装）
  Future<dynamic> put(String endpoint, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('${Constants.API_BASE_URL}$endpoint');

    try {
      final response = await _client
          .put(
            uri,
            headers: _buildHeaders(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(
            const Duration(seconds: Constants.READ_TIMEOUT),
            onTimeout: () => throw Exception('请求超时，请检查网络连接'),
          );
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } on SocketException {
      throw Exception('网络连接失败，请检查网络设置');
    } catch (e) {
      throw Exception('PUT 请求失败: $e');
    }
  }

  /// 统一响应处理（解析状态码、错误码、数据提取）
  ///
  /// 后端统一响应格式：
  /// { "code": 0, "message": "ok", "data": { ... } }
  /// code = 0 表示成功，非0 表示错误（需要弹出提示）
  ///
  /// 返回 data 字段内容（如果存在），否则返回完整响应
  dynamic _handleResponse(http.Response response) {
    dynamic decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        throw const ApiException('服务器返回了无法识别的数据');
      }
    }

    final responseMap = decoded is Map<String, dynamic> ? decoded : null;
    final businessCode = responseMap?['code'] as int?;
    final backendMessage = responseMap?['message'] as String?;
    final isHttpSuccess =
        response.statusCode >= 200 && response.statusCode < 300;

    if (!isHttpSuccess || (businessCode != null && businessCode != 0)) {
      throw ApiException(
        backendMessage ?? '请求失败 (${response.statusCode})',
        statusCode: response.statusCode,
        code: businessCode,
      );
    }

    return responseMap?['data'] ?? decoded;
  }

  // ==================== 认证相关 API ====================

  /// 发送手机验证码
  /// POST /api/auth/send-sms
  Future<dynamic> sendSms(String phone) async {
    return post('/auth/send-sms', body: {'phone': phone});
  }

  /// 手机号验证码登录
  /// POST /api/auth/phone-login
  /// 返回：{ token, user }
  Future<dynamic> phoneLogin(String phone, String code) async {
    return post('/auth/phone-login', body: {'phone': phone, 'code': code});
  }

  /// 微信授权登录（预留接口，实际接入需集成微信SDK）
  /// POST /api/auth/wechat-login
  Future<dynamic> wechatLogin(String wxCode) async {
    return post('/auth/wechat-login', body: {'code': wxCode});
  }

  /// 刷新 JWT Token
  /// GET /api/auth/refresh
  Future<dynamic> refreshToken() async {
    return get('/auth/refresh');
  }

  // ==================== 用户相关 API ====================

  /// 获取个人资料
  /// GET /api/user/profile
  Future<dynamic> getProfile() async {
    return get('/user/profile');
  }

  /// 更新昵称/头像
  /// PUT /api/user/profile
  Future<dynamic> updateProfile({String? nickname, String? avatar}) async {
    return put('/user/profile', body: {
      if (nickname != null) 'nickname': nickname,
      if (avatar != null) 'avatar': avatar,
    });
  }

  /// 获取金币流水（分页）
  /// GET /api/user/gold-history?page=1&pageSize=20
  Future<dynamic> getGoldHistory({int page = 1, int pageSize = 20}) async {
    return get('/user/gold-history', queryParams: {
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    });
  }

  /// 获取游戏历史记录（分页）
  Future<dynamic> getGameHistory({int page = 1, int pageSize = 20}) async {
    return get('/user/game-history', queryParams: {
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    });
  }

  /// 获取提现记录
  Future<dynamic> getWithdrawHistory({int page = 1, int pageSize = 20}) async {
    return get('/user/withdraw-history', queryParams: {
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    });
  }

  // ==================== 金币/广告相关 API ====================

  /// 广告观看完成奖励（后端校验防刷）
  /// POST /api/gold/ad-reward
  /// Body: { ad_type: string, transaction_id?: string }
  Future<dynamic> adReward(String adType, {String? transactionId}) async {
    return post('/gold/ad-reward', body: {
      'ad_type': adType,
      if (transactionId != null) 'transaction_id': transactionId,
    });
  }

  /// 游戏结算金币奖励
  /// POST /api/gold/game-reward
  /// Body: { rounds: number, is_record: boolean }
  /// 每日签到（含翻倍逻辑）
  /// POST /api/gold/sign-in
  Future<dynamic> signIn() async {
    return post('/gold/sign-in');
  }

  /// 转盘抽奖
  /// POST /api/gold/spin
  Future<dynamic> spin() async {
    return post('/gold/spin');
  }

  /// 获取今日任务进度与领取状态
  /// GET /api/gold/tasks
  Future<dynamic> getDailyTasks() async {
    return get('/gold/tasks');
  }

  /// 领取今日任务奖励
  /// POST /api/gold/tasks/:taskKey/claim
  Future<dynamic> claimDailyTask(String taskKey) async {
    return post('/gold/tasks/$taskKey/claim');
  }

  // ==================== 游戏相关 API ====================

  /// 开始新游戏
  /// GET /api/game/start?difficulty=easy|normal|hard
  /// 返回：{ game_id: string, start_idiom: Idiom }
  Future<dynamic> startGame(String difficulty) async {
    return get('/game/start', queryParams: {'difficulty': difficulty});
  }

  /// 验证玩家接龙
  /// POST /api/game/validate
  /// Body: { game_id, idiom, previous_idiom }
  Future<dynamic> validateGame(
    String gameId,
    String idiom,
    String previousIdiom,
  ) async {
    return post('/game/validate', body: {
      'game_id': gameId,
      'idiom': idiom,
      'previous_idiom': previousIdiom,
    });
  }

  /// 获取提示（可接成语）
  /// POST /api/game/hint
  Future<dynamic> getHint(String gameId, String currentIdiom) async {
    return post('/game/hint', body: {
      'game_id': gameId,
      'current_idiom': currentIdiom,
    });
  }

  /// 结束游戏，保存记录
  /// POST /api/game/end
  /// Body: { game_id, rounds, chain, reason }
  Future<dynamic> endGame(
    String gameId,
    int rounds,
    List<String> chain,
    String reason,
  ) async {
    return post('/game/end', body: {
      'game_id': gameId,
      'rounds': rounds,
      'chain': chain,
      'reason': reason,
    });
  }

  /// 获取排行榜（按轮数排行）
  /// GET /api/game/leaderboard?page=1
  Future<dynamic> getLeaderboard({int page = 1}) async {
    return get('/game/leaderboard', queryParams: {'page': page.toString()});
  }

  // ==================== 提现相关 API ====================

  /// 提交提现申请
  /// POST /api/withdraw/apply
  /// Body: { amount, method, account_info }
  Future<dynamic> applyWithdraw(
    int amount,
    String method,
    String accountInfo,
  ) async {
    return post('/withdraw/apply', body: {
      'amount': amount,
      'method': method,
      'account_info': accountInfo,
    });
  }

  /// 获取提现配置（门槛、比例、限制）
  /// GET /api/withdraw/config
  Future<dynamic> getWithdrawConfig() async {
    return get('/withdraw/config');
  }

  // ==================== 配置/公告 API ====================

  /// 获取前端配置（广告ID、金币比例、公告等）
  /// GET /api/config
  Future<dynamic> getConfig() async {
    return get('/config');
  }

  /// 获取活跃公告列表
  /// GET /api/announcements
  Future<dynamic> getAnnouncements() async {
    return get('/config/announcements');
  }

  /// 关闭资源（应用退出时调用）
  void dispose() {
    _client.close();
  }
}
