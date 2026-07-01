class Charge {
  const Charge({
    required this.id,
    required this.type,
    required this.description,
    required this.amount,
    required this.paidAmount,
    required this.dueDate,
    required this.status,
    this.periodYear,
    this.periodMonth,
  });

  factory Charge.fromJson(Map<String, dynamic> json) => Charge(
        id: json['id'] as int,
        type: json['type'] as String? ?? '',
        description: json['description'] as String? ?? '',
        amount: _toDouble(json['amount']),
        paidAmount: _toDouble(json['paid_amount']),
        dueDate: json['due_date'] as String? ?? '',
        status: json['status'] as String? ?? 'pending',
        periodYear: json['period_year'] as int?,
        periodMonth: json['period_month'] as int?,
      );

  final int id;
  final String type;
  final String description;
  final double amount;
  final double paidAmount;
  final String dueDate;
  final String status;
  final int? periodYear;
  final int? periodMonth;

  double get balanceDue => amount - paidAmount;
  bool get isPaid => status == 'paid';

  bool get isOverdue {
    if (isPaid || dueDate.isEmpty) return false;
    try {
      return DateTime.parse(dueDate).isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  String get typeLabel => switch (type) {
        'admin_fee' => 'Cuota administración',
        'fine' => 'Multa',
        'interest' => 'Interés de mora',
        'extraordinary_fee' => 'Cuota extraordinaria',
        'area_booking' => 'Cobro área común',
        _ => type,
      };

  String? get periodLabel {
    if (periodYear == null || periodMonth == null) return null;
    const months = [
      '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
    ];
    return '${months[periodMonth!]} $periodYear';
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}
