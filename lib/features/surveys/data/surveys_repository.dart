import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../models/survey.dart';

final surveysRepositoryProvider = Provider<SurveysRepository>((ref) {
  return SurveysRepository(ref.read(apiClientProvider).dio);
});

class SurveysRepository {
  SurveysRepository(this._dio);

  final Dio _dio;

  Future<List<Survey>> getSurveys({String? status}) async {
    final response = await _dio.get(
      '/encuestas',
      queryParameters: {
        if (status != null) 'status': status,
        'per_page': 50,
      },
    );
    final raw = response.data;
    final list = raw is Map ? (raw['data'] ?? []) : (raw ?? []);
    return (list as List)
        .map((e) => Survey.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Survey> getSurvey(int id) async {
    final response = await _dio.get('/encuestas/$id');
    final raw = response.data as Map<String, dynamic>;
    final data = raw['data'] as Map<String, dynamic>? ?? raw;
    return Survey.fromJson(data);
  }

  /// [answers] — lista de `{question_id, value}`. value es String o `List<String>`.
  Future<void> respond(int surveyId, List<Map<String, dynamic>> answers) async {
    await _dio.post(
      '/encuestas/$surveyId/responder',
      data: {'respuestas': answers},
    );
  }
}
