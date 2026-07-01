import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static StatusChip forChargeStatus(String status) {
    return switch (status) {
      'paid'      => const StatusChip(label: 'Pagado', color: Colors.green),
      'partial'   => const StatusChip(label: 'Parcial', color: Colors.orange),
      'pending'   => const StatusChip(label: 'Pendiente', color: Colors.red),
      'cancelled' => const StatusChip(label: 'Anulado', color: Colors.grey),
      _           => StatusChip(label: status, color: Colors.grey),
    };
  }

  static StatusChip forMaintenanceStatus(String status) {
    return switch (status) {
      'pending'     => const StatusChip(label: 'Pendiente', color: Colors.orange),
      'in_progress' => const StatusChip(label: 'En proceso', color: Colors.blue),
      'resolved'    => const StatusChip(label: 'Resuelto', color: Colors.green),
      'closed'      => const StatusChip(label: 'Cerrado', color: Colors.grey),
      'rejected'    => const StatusChip(label: 'Rechazado', color: Colors.red),
      _             => StatusChip(label: status, color: Colors.grey),
    };
  }

  static StatusChip forBookingStatus(String status) {
    return switch (status) {
      'pending'   => const StatusChip(label: 'En revisión', color: Colors.orange),
      'approved'  => const StatusChip(label: 'Aprobada', color: Colors.green),
      'rejected'  => const StatusChip(label: 'Rechazada', color: Colors.red),
      'cancelled' => const StatusChip(label: 'Cancelada', color: Colors.grey),
      _           => StatusChip(label: status, color: Colors.grey),
    };
  }

  static StatusChip forWorkOrderStatus(String status) {
    return switch (status) {
      'pending'   => const StatusChip(label: 'Pendiente', color: Colors.orange),
      'on_the_way'=> const StatusChip(label: 'En camino', color: Colors.blue),
      'in_progress'=> const StatusChip(label: 'En progreso', color: Colors.indigo),
      'resolved'  => const StatusChip(label: 'Resuelto', color: Colors.green),
      'approved'  => const StatusChip(label: 'Aprobado', color: Colors.teal),
      'rejected'  => const StatusChip(label: 'Rechazado', color: Colors.red),
      _           => StatusChip(label: status, color: Colors.grey),
    };
  }
}
