import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../data/access_validation_repository.dart';
import '../../models/qr_preview.dart';

class ValidateAccessScreen extends ConsumerStatefulWidget {
  const ValidateAccessScreen({super.key});

  @override
  ConsumerState<ValidateAccessScreen> createState() =>
      _ValidateAccessScreenState();
}

class _ValidateAccessScreenState extends ConsumerState<ValidateAccessScreen> {
  final MobileScannerController _controller = MobileScannerController();
  final _codeController = TextEditingController();

  bool _scanMode = true;
  bool _loading = false;
  QrPreview? _preview;
  String? _error;

  // Datos pendientes de confirmación — según venga de QR (uuid+token) o de
  // código corto, solo uno de los dos pares queda poblado.
  String? _pendingUuid;
  String? _pendingToken;
  String? _pendingCode;

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
        title: const Text('Validar acceso'),
        actions: [
          if (_scanMode && _preview == null)
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
          child: SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: true,
                icon: Icon(Icons.qr_code_scanner),
                label: Text('Escanear QR'),
              ),
              ButtonSegment(
                value: false,
                icon: Icon(Icons.dialpad),
                label: Text('Código'),
              ),
            ],
            selected: {_scanMode},
            onSelectionChanged: (selection) => setState(() {
              _scanMode = selection.first;
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
        Expanded(child: _scanMode ? _buildScanner() : _buildCodeForm()),
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
                  'Apunta al QR de la invitación',
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
            keyboardType: TextInputType.number,
            maxLength: 4,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 32, letterSpacing: 8, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              counterText: '',
              labelText: 'Código de 4 dígitos',
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

  Widget _buildPreview(QrPreview preview) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          const Icon(Icons.person_pin_circle_outlined,
              size: 72, color: Colors.indigo),
          const SizedBox(height: 16),
          Text(
            preview.nombre,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text('${preview.tipoDocumentoLabel}: ${preview.documento}'),
          if (preview.placa != null && preview.placa!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Vehículo: ${preview.placa}'),
            ),
          if (preview.apartamento != null && preview.apartamento!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Apto: ${preview.apartamento}'),
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
                  onPressed: _loading ? null : _confirmEntry,
                  child: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Confirmar entrada'),
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
    final raw = barcodes.first.rawValue;
    if (raw == null) return;

    Uri uri;
    try {
      uri = Uri.parse(raw);
    } catch (_) {
      setState(() => _error = 'QR inválido.');
      return;
    }

    final segments = uri.pathSegments;
    final qrIndex = segments.indexOf('qr');
    if (qrIndex == -1 || qrIndex + 1 >= segments.length) {
      setState(() => _error = 'Este QR no corresponde a una invitación de visita.');
      return;
    }
    final uuid = segments[qrIndex + 1];
    final token = uri.queryParameters['token'];
    if (token == null || token.isEmpty) {
      setState(() => _error = 'QR incompleto — falta el token.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    await _controller.stop();

    try {
      final preview = await ref
          .read(accessValidationRepositoryProvider)
          .previewByUuid(uuid, token);
      _pendingUuid = uuid;
      _pendingToken = token;
      _pendingCode = null;
      setState(() {
        _preview = preview;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = _friendlyError(e);
      });
      await _controller.start();
    }
  }

  Future<void> _lookupCode() async {
    final code = _codeController.text.trim();
    if (code.length != 4) {
      setState(() => _error = 'Ingresa los 4 dígitos del código.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final preview = await ref
          .read(accessValidationRepositoryProvider)
          .previewByCode(code);
      _pendingCode = code;
      _pendingUuid = null;
      _pendingToken = null;
      setState(() {
        _preview = preview;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = _friendlyError(e);
      });
    }
  }

  Future<void> _confirmEntry() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(accessValidationRepositoryProvider);
      if (_pendingCode != null) {
        await repo.confirmByCode(_pendingCode!);
      } else if (_pendingUuid != null && _pendingToken != null) {
        await repo.confirmByUuid(_pendingUuid!, _pendingToken!);
      }
      if (!mounted) return;
      final name = _preview?.nombre ?? 'Visitante';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$name registrado correctamente.'),
          backgroundColor: Colors.green,
        ),
      );
      _resetToInput();
    } catch (e) {
      setState(() {
        _loading = false;
        _error = _friendlyError(e);
      });
    }
  }

  void _resetToInput() {
    _codeController.clear();
    _pendingUuid = null;
    _pendingToken = null;
    _pendingCode = null;
    setState(() {
      _preview = null;
      _loading = false;
      _error = null;
    });
    if (_scanMode) _controller.start();
  }

  String _friendlyError(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
      if (e.response?.statusCode == 403) {
        return 'No tienes permiso para validar accesos.';
      }
    }
    return 'No se pudo validar. Intenta de nuevo.';
  }
}
