class Booking {
  const Booking({
    required this.id,
    required this.commonAreaId,
    this.commonAreaName,
    this.apartmentId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.cancelReason,
  });

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        id: json['id'] as int,
        commonAreaId: json['common_area_id'] as int,
        commonAreaName:
            (json['common_area'] as Map<String, dynamic>?)?['name'] as String?,
        apartmentId: json['apartment_id'] as int?,
        date: json['date'] as String? ?? '',
        startTime: json['start_time'] as String? ?? '',
        endTime: json['end_time'] as String? ?? '',
        status: json['status'] as String? ?? 'pending',
        cancelReason: json['cancel_reason'] as String?,
      );

  final int id;
  final int commonAreaId;
  final String? commonAreaName;
  final int? apartmentId;
  final String date;
  final String startTime;
  final String endTime;
  final String status;
  final String? cancelReason;

  bool get canCancel => status == 'approved' || status == 'pending';
}
