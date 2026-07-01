import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../models/account_statement.dart';

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepository(ref.read(apiClientProvider).dio);
});

class AccountRepository {
  AccountRepository(this._dio);

  final Dio _dio;

  Future<AccountStatement> getStatement(int apartmentId) async {
    final response = await _dio.get('/apartments/$apartmentId/statement');
    return AccountStatement.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Uint8List> downloadReceipt(int apartmentId, int chargeId) async {
    final response = await _dio.get(
      '/apartments/$apartmentId/charges/$chargeId/receipt',
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data as List<int>);
  }

  Future<Uint8List> downloadPazYSalvo(int apartmentId) async {
    final response = await _dio.get(
      '/apartments/$apartmentId/paz-y-salvo',
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data as List<int>);
  }

  Future<Uint8List> downloadStatement(int apartmentId) async {
    final response = await _dio.get(
      '/apartments/$apartmentId/statement/pdf',
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data as List<int>);
  }
}
