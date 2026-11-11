import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../services/estande_repository.dart';

class ScannerScreen extends StatefulWidget {
  final EstandeRepository repo;
  const ScannerScreen({super.key, required this.repo});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _processando = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _aoDetectar(BarcodeCapture captura) async {
    if (_processando) return;
    final valor = captura.barcodes.map((b) => b.rawValue).whereType<String>().firstOrNull;
    if (valor == null) return;

    _processando = true;
    final resultado = await widget.repo.registrarCheckin(valor);
    if (!mounted) return;

    final nome = resultado.estande?.nome;
    final (titulo, msg, icone, cor) = switch (resultado.status) {
      CheckinStatus.sucesso => (
          'Check-in confirmado!',
          'Você visitou ${nome ?? 'o estande'}.',
          Icons.check_circle,
          Colors.green
        ),
      CheckinStatus.jaRegistrado => (
          'Visita já registrada',
          'Você já fez check-in em ${nome ?? 'este estande'}.',
          Icons.info,
          Colors.blue
        ),
      CheckinStatus.estandeInativo => (
          'Estande inativo',
          '${nome ?? 'Este estande'} não está recebendo check-ins agora.',
          Icons.block,
          Colors.orange
        ),
      CheckinStatus.estandeInexistente => (
          'Estande não encontrado',
          'Este QR code não corresponde a nenhum estande cadastrado.',
          Icons.help_outline,
          Colors.red
        ),
      CheckinStatus.qrInvalido => (
          'QR code inválido',
          'Este QR code não é de um estande do Circuito de Descobertas.',
          Icons.error_outline,
          Colors.red
        ),
      CheckinStatus.erro => (
          'Não foi possível registrar',
          'Verifique sua conexão e tente novamente.',
          Icons.cloud_off,
          Colors.red
        ),
    };

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(icone, color: cor, size: 48),
        title: Text(titulo),
        content: Text(msg),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
      ),
    );
    if (!mounted) return;

    if (resultado.status == CheckinStatus.sucesso) {
      Navigator.of(context).pop();
    } else {
      // Pequena pausa evita reler o mesmo QR imediatamente após fechar o aviso.
      await Future<void>.delayed(const Duration(milliseconds: 800));
      _processando = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ler QR do estande')),
      body: Stack(children: [
        MobileScanner(
          controller: _controller,
          onDetect: _aoDetectar,
          errorBuilder: (context, error) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                error.errorCode == MobileScannerErrorCode.permissionDenied
                    ? 'Permita o uso da câmera nas configurações do app para ler o QR code.'
                    : 'Não foi possível abrir a câmera.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        const Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Aponte a câmera para o QR code do estande',
              style: TextStyle(color: Colors.white, fontSize: 16, shadows: [Shadow(blurRadius: 6)]),
            ),
          ),
        ),
      ]),
    );
  }
}
