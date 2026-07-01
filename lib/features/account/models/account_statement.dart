import 'charge.dart';

class AccountStatement {
  const AccountStatement({
    required this.apartmentId,
    required this.balanceDue,
    required this.hasDebt,
    required this.pazYSalvo,
    required this.charges,
  });

  factory AccountStatement.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final chargesJson = data['charges'] as List<dynamic>? ?? [];
    return AccountStatement(
      apartmentId: data['apartment_id'] as int? ?? 0,
      balanceDue: _toDouble(data['balance_due']),
      hasDebt: data['has_debt'] as bool? ?? false,
      pazYSalvo: data['paz_y_salvo'] as bool? ?? true,
      charges: chargesJson
          .map((e) => Charge.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final int apartmentId;
  final double balanceDue;
  final bool hasDebt;
  final bool pazYSalvo;
  final List<Charge> charges;

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}
