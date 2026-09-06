import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/apartment_lookup.dart';
import '../../../../core/widgets/apartment_picker.dart';
import '../../data/porteria_repository.dart';
import '../../models/access_request.dart';
import '../../providers/porteria_provider.dart';

/// QA #10: portero solicita autorización remota antes de dejar entrar a un
/// visitante — el residente aprueba/rechaza por push, el portero ve el
/// resultado en vivo (Reverb) sin recargar la pantalla.
class NewAccessRequestScreen extends ConsumerStatefulWidget {
  const NewAccessRequestScreen({super.key});

  @override
  ConsumerState<NewAccessRequestScreen> createState() =>
      _NewAccessRequestScreenState();
}

class _NewAccessRequestScreenState
    extends ConsumerState<NewAccessRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _visitorNameCtrl = TextEditingController();
  final _documentCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  ApartmentLookup? _apartment;
  bool _submitting = false;

  @override
  void dispose() {
    _visitorNameCtrl.dispose();
    _documentCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate() || _apartment == null) {
      if (_apartment == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecciona el apartamento destino.')),
        );
      }
      return;
    }

    setState(() => _submitting = true);
    try {
      final created =
          await ref.read(porteriaRepositoryProvider).createAccessRequest(
                apartmentId: _apartment!.id,
                visitorName: _visitorNameCtrl.text.trim(),
                documentNumber: _documentCtrl.text.trim(),
                reason: _reasonCtrl.text.trim(),
              );
      ref.read(activeAccessRequestProvider.notifier).track(created);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No se pudo enviar la solicitud. Intenta de nuevo.')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _reset() {
    ref.read(activeAccessRequestProvider.notifier).clear();
    _visitorNameCtrl.clear();
    _documentCtrl.clear();
    _reasonCtrl.clear();
    setState(() => _apartment = null);
  }

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(activeAccessRequestProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Autorizar visitante remoto')),
      body: active != null
          ? _StatusView(request: active, onNewRequest: _reset)
          : _FormView(
              formKey: _formKey,
              visitorNameCtrl: _visitorNameCtrl,
              documentCtrl: _documentCtrl,
              reasonCtrl: _reasonCtrl,
              apartment: _apartment,
              onApartmentSelected: (a) => setState(() => _apartment = a),
              submitting: _submitting,
              onSubmit: _submit,
            ),
    );
  }
}

class _FormView extends StatelessWidget {
  const _FormView({
    required this.formKey,
    required this.visitorNameCtrl,
    required this.documentCtrl,
    required this.reasonCtrl,
    required this.apartment,
    required this.onApartmentSelected,
    required this.submitting,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController visitorNameCtrl;
  final TextEditingController documentCtrl;
  final TextEditingController reasonCtrl;
  final ApartmentLookup? apartment;
  final ValueChanged<ApartmentLookup> onApartmentSelected;
  final bool submitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'El residente recibirá una notificación para aprobar o rechazar '
              'el ingreso. Si no responde a tiempo, la solicitud queda como '
              '"sin respuesta" y decides tú si dejarlo entrar.',
              style: TextStyle(
                  fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            ApartmentPicker(
              selected: apartment,
              onSelected: onApartmentSelected,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: visitorNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre del visitante *',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Obligatorio' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: documentCtrl,
              decoration: const InputDecoration(
                labelText: 'Documento (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Motivo (opcional)',
                hintText: 'Ej: trae un pedido, viene de visita...',
                border: OutlineInputBorder(),
              ),
              maxLength: 255,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: submitting ? null : onSubmit,
                icon: submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.notifications_active_outlined),
                label: Text(submitting ? 'Enviando...' : 'Solicitar autorización'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusView extends StatefulWidget {
  const _StatusView({required this.request, required this.onNewRequest});

  final AccessRequest request;
  final VoidCallback onNewRequest;

  @override
  State<_StatusView> createState() => _StatusViewState();
}

class _StatusViewState extends State<_StatusView> {
  Timer? _ticker;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _updateRemaining());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _updateRemaining() {
    final expiresAt = widget.request.expiresAtDateTime;
    if (expiresAt == null) return;
    final diff = expiresAt.difference(DateTime.now());
    if (mounted) {
      setState(() => _remaining = diff.isNegative ? Duration.zero : diff);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final req = widget.request;

    final (icon, color, label) = switch (req.status) {
      'approved' => (Icons.check_circle_outline, Colors.green, 'Acceso aprobado'),
      'rejected' => (Icons.cancel_outlined, cs.error, 'Acceso rechazado'),
      'expired' => (Icons.hourglass_disabled_outlined, Colors.orange, 'Sin respuesta del residente'),
      _ => (Icons.hourglass_top_outlined, cs.primary, 'Esperando respuesta del residente...'),
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: color),
            const SizedBox(height: 20),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(req.visitorName, style: TextStyle(fontSize: 15, color: cs.onSurfaceVariant)),
            if (req.apartmentNumber != null)
              Text('Apto ${req.apartmentNumber}',
                  style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
            if (req.isPending) ...[
              const SizedBox(height: 16),
              Text(
                _remaining > Duration.zero
                    ? 'Vence en ${_remaining.inMinutes}:${(_remaining.inSeconds % 60).toString().padLeft(2, '0')}'
                    : 'Venciendo...',
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
            ],
            if (req.respondedByName != null) ...[
              const SizedBox(height: 8),
              Text('Respondió: ${req.respondedByName}',
                  style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
            ],
            const SizedBox(height: 28),
            if (!req.isPending)
              FilledButton(
                onPressed: widget.onNewRequest,
                child: const Text('Nueva solicitud'),
              ),
          ],
        ),
      ),
    );
  }
}
