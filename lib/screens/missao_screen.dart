import 'package:flutter/material.dart';

import '../models/estande.dart';
import '../services/estande_repository.dart';
import '../services/missao_service.dart';

/// Detalhe da missão. Ao abrir, registra o evento `missao_aberta` no Analytics.
class MissaoScreen extends StatefulWidget {
  final EstandeRepository repo;
  final MissaoService missao;
  final List<Estande> estandesAtivos;
  const MissaoScreen({
    super.key,
    required this.repo,
    required this.missao,
    required this.estandesAtivos,
  });

  @override
  State<MissaoScreen> createState() => _MissaoScreenState();
}

class _MissaoScreenState extends State<MissaoScreen> {
  @override
  void initState() {
    super.initState();
    final qtd = widget.estandesAtivos
        .where((e) => widget.missao.estandesDestacados.contains(e.id))
        .length;
    widget.repo.logMissaoAberta(qtd);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Missão surpresa')),
      body: ListenableBuilder(
        listenable: widget.missao,
        builder: (context, _) {
          // Se a missão for desligada com a tela aberta, avisa em vez de mostrar dados velhos.
          if (!widget.missao.ativa) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('A missão foi encerrada. Volte à lista de estandes.',
                    textAlign: TextAlign.center),
              ),
            );
          }
          final ids = widget.missao.estandesDestacados;
          final participantes = widget.estandesAtivos.where((e) => ids.contains(e.id)).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Visite os estandes abaixo e faça o check-in lendo o QR code de cada um.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              if (participantes.isEmpty)
                const Text('Nenhum estande ativo participa da missão agora.'),
              for (final e in participantes)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.star, color: Colors.amber),
                    title: Text(e.nome),
                    subtitle: Text(e.localizacao.isEmpty ? e.descricao : e.localizacao),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
