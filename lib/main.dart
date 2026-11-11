import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/estande_repository.dart';
import 'services/missao_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CircuitoApp());
}

class CircuitoApp extends StatelessWidget {
  const CircuitoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Circuito de Descobertas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
        useMaterial3: true,
      ),
      home: const _Inicializacao(),
    );
  }
}

typedef _Servicos = ({EstandeRepository repo, MissaoService missao});

/// Inicia Firebase, sessão anônima e Remote Config antes de mostrar a home.
class _Inicializacao extends StatefulWidget {
  const _Inicializacao();

  @override
  State<_Inicializacao> createState() => _InicializacaoState();
}

class _InicializacaoState extends State<_Inicializacao> {
  late Future<_Servicos> _futuro = _iniciar();

  Future<_Servicos> _iniciar() async {
    await Firebase.initializeApp(); // lê android/app/google-services.json
    final repo = EstandeRepository();
    await repo.garantirSessao();
    final missao = MissaoService();
    await missao.iniciar();
    return (repo: repo, missao: missao);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_Servicos>(
      future: _futuro,
      builder: (context, snap) {
        if (snap.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.cloud_off, size: 56),
                  const SizedBox(height: 12),
                  Text('Não foi possível conectar ao Firebase.\n${snap.error}',
                      textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => setState(() => _futuro = _iniciar()),
                    child: const Text('Tentar novamente'),
                  ),
                ]),
              ),
            ),
          );
        }
        if (!snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final d = snap.data!;
        return HomeScreen(repo: d.repo, missao: d.missao);
      },
    );
  }
}
