import 'dart:async';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// Missão surpresa controlada pelo Firebase Remote Config.
/// O padrão local é missão DESLIGADA (também vale se a rede falhar).
class MissaoService extends ChangeNotifier {
  static const chaveAtiva = 'missao_ativa';
  static const chaveEstandes = 'missao_estandes';

  final FirebaseRemoteConfig _rc;
  StreamSubscription<RemoteConfigUpdate>? _sub;

  MissaoService([FirebaseRemoteConfig? rc]) : _rc = rc ?? FirebaseRemoteConfig.instance;

  bool get ativa => _rc.getBool(chaveAtiva);

  /// IDs dos estandes destacados (parâmetro string "e01,e03").
  Set<String> get estandesDestacados => _rc
      .getString(chaveEstandes)
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toSet();

  Future<void> iniciar() async {
    await _rc.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 15),
      // Zero para a demonstração aparecer na hora; o listener em tempo real
      // abaixo é o que faz o app reagir sem reiniciar.
      minimumFetchInterval: Duration.zero,
    ));
    await _rc.setDefaults(const {chaveAtiva: false, chaveEstandes: ''});

    try {
      await _rc.fetchAndActivate();
    } catch (e) {
      debugPrint('Remote Config: usando valores locais ($e)');
    }
    notifyListeners();

    // Atualização em tempo real: dispara quando você publica no console.
    _sub = _rc.onConfigUpdated.listen((_) async {
      await _rc.activate();
      notifyListeners();
    }, onError: (Object e) => debugPrint('Remote Config listener: $e'));
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
