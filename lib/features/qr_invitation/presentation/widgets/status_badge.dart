import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.estado, this.large = false});

  final String estado;
  final bool large;

  static const _config = {
    'activo': (Color(0xFF2E7D32), Color(0xFFE8F5E9), 'Activo'),
    'usado': (Color(0xFF1565C0), Color(0xFFE3F2FD), 'Usado'),
    'expirado': (Color(0xFFE65100), Color(0xFFFFF3E0), 'Expirado'),
    'revocado': (Color(0xFFC62828), Color(0xFFFFEBEE), 'Revocado'),
  };

  @override
  Widget build(BuildContext context) {
    final cfg = _config[estado] ??
        (const Color(0xFF616161), const Color(0xFFF5F5F5), estado);
    final (textColor, bgColor, label) = cfg;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 16 : 8,
        vertical: large ? 6 : 3,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(large ? 12 : 10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: large ? 14 : 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
