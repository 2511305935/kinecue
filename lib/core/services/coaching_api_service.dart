import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:kinecue/core/models/set_summary.dart';
import 'package:kinecue/core/utils/logger.dart';

/// 调用 Kimi API（Anthropic Messages 兼容格式）生成中文教练建议。
///
/// API key 通过 `--dart-define=KIMI_API_KEY=sk-kimi-...` 传入。
/// 无 key / 网络错误 / 超时时静默返回 null，调用方使用通用文案降级。
class CoachingApiService {
  CoachingApiService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  static const _apiKey = String.fromEnvironment('KIMI_API_KEY');
  static const _baseUrl = 'https://api.kimi.com/coding/v1/messages';
  static const _model = 'moonshot-v1-auto';
  static const _timeout = Duration(seconds: 10);

  static const _systemPrompt =
      '你是一个专业的中文健身教练。根据用户的训练数据，给出简短鼓励性建议（50-100字）。'
      '针对用户的错误动作给出具体改进方法。只用中文回复。不要使用 markdown 格式。';

  /// 根据单组训练数据生成教练建议。
  ///
  /// 返回中文建议文本，或在任何错误时返回 null��
  Future<String?> getCoachingFeedback(SetSummary summary) async {
    if (_apiKey.isEmpty) {
      Log.w('KIMI_API_KEY not configured, skipping AI coaching', tag: 'API');
      return null;
    }

    try {
      final body = jsonEncode({
        'model': _model,
        'max_tokens': 200,
        'system': _systemPrompt,
        'messages': [
          {
            'role': 'user',
            'content': '以下是我刚完成的一组训练数据：\n${jsonEncode(summary.toJson())}',
          },
        ],
      });

      final response = await _client
          .post(
            Uri.parse(_baseUrl),
            headers: {
              'Content-Type': 'application/json',
              'x-api-key': _apiKey,
              'anthropic-version': '2023-06-01',
            },
            body: body,
          )
          .timeout(_timeout);

      if (response.statusCode != 200) {
        Log.e(
          'API error: ${response.statusCode} ${response.body}',
          tag: 'API',
        );
        return null;
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final content = json['content'] as List<dynamic>?;
      if (content != null && content.isNotEmpty) {
        final text = content[0]['text'] as String?;
        return text;
      }

      Log.w('API response missing content', tag: 'API');
      return null;
    } catch (e, st) {
      Log.e('API call failed', tag: 'API', error: e, stackTrace: st);
      return null;
    }
  }

  void dispose() {
    _client.close();
  }
}
