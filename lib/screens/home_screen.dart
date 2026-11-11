import 'package:flutter/material.dart';

import '../models/estande.dart';
import '../services/estande_repository.dart';
import '../services/missao_service.dart';
import 'missao_screen.dart';
import 'scanner_screen.dart';

class HomeScreen extends StatelessWidget {
  final EstandeRepository repo;
  final MissaoService missao;
  const HomeScreen({super.key, required this.repo, required this.missao});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Circuito de Descobertas')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Check-in'),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ScannerScreen(repo: repo)),
        ),
      ),
      body: StreamBuilder<List<Estande>>(
        stream: repo.estandesAtivos(),
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(child: Text('Erro ao carregar os estandes.'));
          }
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());

          return StreamBuilder<Set<String>>(
            stream: repo.minhasVisitas(),
            builder: (context, visitasSnap) {
              final visitados = visitasSnap.data ?? const <String>{};
              // Recalcula a tela toda vez que o Remote Config muda.
              return ListenableBuilder(
                listenable: missao,
                builder: (context, _) {
                  final estandes = snap.data!;
                  final ligada = missao.ativa;
                  final destaque = ligada ? missao.estandesDestacados : const <String>{};
                  final ordenados = [
                    ...estandes.where((e) => destaque.contains(e.id)),
                    ...estandes.where((e) => !destaque.contains(e.id)),
                  ];

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                    children: [
                      if (ligada) _ChamadaMissao(onTap: () => _abrirMissao(context, estandes)),
                      if (ordenados.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 48),
                          child: Center(child: Text('Nenhum estande ativo no momento.')),
                        ),
                      for (final e in ordenados)
                        _CartaoEstande(
                          estande: e,
                          destacado: destaque.contains(e.id),
                          visitado: visitados.contains(e.id),
                        ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _abrirMissao(BuildContext context, List<Estande> ativos) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => MissaoScreen(repo: repo, missao: missao, estandesAtivos: ativos),
    ));
  }
}

class _ChamadaMissao extends StatelessWidget {
  final VoidCallback onTap;
  const _ChamadaMissao({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.primaryContainer,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Icon(Icons.star, color: cs.primary, size: 32),
        title: const Text('Missão surpresa!', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text('Visite os estandes em destaque. Toque para ver.'),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _CartaoEstande extends StatelessWidget {
  final Estande estande;
  final bool destacado;
  final bool visitado;
  const _CartaoEstande({required this.estande, required this.destacado, required this.visitado});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: destacado ? 3 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: destacado ? Colors.amber.shade700 : cs.outlineVariant,
          width: destacado ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            if (destacado)
              const Padding(
                padding: EdgeInsets.only(right: 6),
                child: Icon(Icons.star, color: Colors.amber, size: 20),
              ),
            Expanded(
              child: Text(
                estande.nome,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            if (visitado)
              const Chip(
                avatar: Icon(Icons.check_circle, color: Colors.green, size: 18),
                label: Text('Visitado'),
                visualDensity: VisualDensity.compact,
              ),
          ]),
          if (estande.descricao.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(estande.descricao),
          ],
          if (estande.localizacao.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.place_outlined, size: 18, color: cs.primary),
              const SizedBox(width: 4),
              Expanded(child: Text(estande.localizacao)),
            ]),
          ],
        ]),
      ),
    );
  }
}
