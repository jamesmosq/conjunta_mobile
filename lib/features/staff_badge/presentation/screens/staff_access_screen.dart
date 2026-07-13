import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/utils/error_utils.dart';
import '../../data/staff_badge_repository.dart';
import '../../models/staff_badge.dart';

class StaffAccessScreen extends ConsumerStatefulWidget {
  const StaffAccessScreen({super.key});

  @override
  ConsumerState<StaffAccessScreen> createState() => _StaffAccessScreenState();
}

enum _Mode { scan, code }

class _StaffAccessScreenState extends ConsumerState<StaffAccessScreen> {
  final MobileScannerController _controller = MobileScannerController();
  final _codeController = TextEditingController();

  _Mode _mode = _Mode.scan;
  bool _loading = false;
  StaffBadge? _preview;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acceso personal'),
        actions: [
          if (_mode == _Mode.scan && _preview == null)
            IconButton(
              icon: const Icon(Icons.flash_on),
              onPressed: _controller.toggleTorch,
            ),
        ],
      ),
      body: _preview != null ? _buildPreview(_preview!) : _buildInputMode(),
    );
  }

  Widget _buildInputMode() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: SegmentedButton<_Mode>(
            segments: const [
              ButtonSegment(
                value: _Mode.scan,
                icon: Icon(Icons.qr_code_scanner),
                label: Text('Escanear'),
              ),
              ButtonSegment(
                value: _Mode.code,
                icon: Icon(Icons.dialpad),
                label: Text('Código'),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: (selection) => setState(() {
              _mode = selection.first;
              _error = null;
            }),
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(_error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center),
          ),
        Expanded(
          child: _mode == _Mode.scan ? _buildScanner() : _buildCodeForm(),
        ),
      ],
    );
  }

  Widget _buildScanner() {
    return ClipRRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Apunta al código de acceso',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ),
          if (_loading)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCodeForm() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextField(
            controller: _codeController,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              labelText: 'Código de acceso',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loading ? null : _lookupCode,
            icon: _loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.search),
            label: const Text('Consultar'),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(StaffBadge badge) {
    final actionLabel = badge.isInside ? 'Registrar salida' : 'Registrar entrada';
    final actionColor = badge.isInside ? Colors.orange.shade700 : Colors.green.shade700;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.indigo.shade50,
            child: Icon(Icons.badge_outlined, size: 40, color: Colors.indigo.shade700),
          ),
          const SizedBox(height: 16),
          Text(
            badge.userName,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(badge.roleLabel, style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: (badge.isInside ? Colors.green : Colors.grey).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badge.isInside ? 'Actualmente dentro' : 'Actualmente fuera',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: badge.isInside ? Colors.green.shade700 : Colors.grey.shade700,
              ),
            ),
          ),
          const Spacer(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_error!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center),
            ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _loading ? null : _resetToInput,
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _loading ? null : () => _confirmMark(badge),
                  style: FilledButton.styleFrom(backgroundColor: actionColor),
                  child: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(actionLabel),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_loading) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });
    await _controller.stop();
    await _lookup(code);
  }

  Future<void> _lookupCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Ingresa el código.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    await _lookup(code);
  }

  Future<void> _lookup(String code) async {
    try {
      final badge =
          await ref.read(staffBadgeRepositoryProvider).previewByCode(code);
      setState(() {
        _preview = badge;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = dioErrorMessage(e, 'No se pudo validar el código.');
      });
      if (_mode == _Mode.scan) await _controller.start();
    }
  }

  Future<void> _confirmMark(StaffBadge badge) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final direction =
          await ref.read(staffBadgeRepositoryProvider).markByCode(badge.code);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(direction == 'entrada'
              ? 'Entrada registrada — ${badge.userName}.'
              : 'Salida registrada — ${badge.userName}.'),
          backgroundColor: Colors.green,
        ),
      );
      _resetToInput();
    } catch (e) {
      setState(() {
        _loading = false;
        _error = dioErrorMessage(e, 'No se pudo registrar el acceso.');
      });
    }
  }

  void _resetToInput() {
    _codeController.clear();
    setState(() {
      _preview = null;
      _loading = false;
      _error = null;
    });
    if (_mode == _Mode.scan) _controller.start();
  }
}
