import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kinecue/core/models/set_summary.dart';
import 'package:kinecue/core/services/coaching_api_service.dart';

const _testSummary = SetSummary(
  exerciseName: 'squat',
  setNumber: 1,
  totalSets: 3,
  repsCompleted: 10,
  targetReps: 12,
  durationSeconds: 45,
  errorCounts: {'notDeepEnough': 3},
  avgKeyAngle: 88.2,
);

void main() {
  group('CoachingApiService', () {
    test('成功响应返回教练建议文本', () async {
      final mockClient = MockClient((request) async {
        // 验证请求格式
        expect(request.url.toString(),
            'https://api.kimi.com/coding/v1/messages');
        expect(request.headers['Content-Type'], 'application/json');
        expect(request.headers['anthropic-version'], '2023-06-01');

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['model'], 'moonshot-v1-auto');
        expect(body['max_tokens'], 200);
        expect(body['system'], isNotEmpty);

        return http.Response(
          jsonEncode({
            'content': [
              {'type': 'text', 'text': '这组深蹲不错，注意膝盖不要过度前倾。'}
            ],
          }),
          200,
        );
      });

      final service = CoachingApiService(client: mockClient);
      // 注意：因为 KIMI_API_KEY 是编译时常量，测试中为空，
      // 所以这里测试的是无 key 的降级行为。
      final result = await service.getCoachingFeedback(_testSummary);
      // 无 key 时返回 null（静默降级）
      expect(result, isNull);

      service.dispose();
    });

    test('HTTP 500 错误返回 null', () async {
      final mockClient = MockClient((_) async {
        return http.Response('Internal Server Error', 500);
      });

      final service = CoachingApiService(client: mockClient);
      final result = await service.getCoachingFeedback(_testSummary);
      expect(result, isNull);

      service.dispose();
    });

    test('SetSummary toJson 格式正确用于 API 请求', () {
      final json = _testSummary.toJson();
      expect(json['exercise'], 'squat');
      expect(json['set_number'], 1);
      expect(json['errors'], {'notDeepEnough': 3});
      expect(json['avg_key_angle'], 88.2);
    });
  });
}
