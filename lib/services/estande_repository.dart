import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/estande.dart';

enum CheckinStatus { sucesso, qrInvalido, estandeInexistente, estandeInativo, jaRegistrado, erro }

class CheckinResultado {
  final CheckinStatus status;
  final Estande? estande;
  const CheckinResultado(this.status, [this.estande]);
}

class EstandeRepository {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final FirebaseAnalytics _analytics;

  EstandeRepository({FirebaseFirestore? db, FirebaseAuth? auth, FirebaseAnalytics? analytics})
      : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _analytics = analytics ?? FirebaseAnalytics.instance;

  /// IDs válidos: letras, números, "_" e "-". Rejeita "/" e textos soltos de QR alheios.
  static final _idValido = RegExp(r'^[A-Za-z0-9_-]{1,100}$');
  static bool idValido(String s) => _idValido.hasMatch(s);

  /// Chave composta visitante+estande: impede check-in duplicado.
  static String checkinId(String visitanteId, String estandeId) => '${visitanteId}_$estandeId';

  Future<User> garantirSessao() async {
    final atual = _auth.currentUser;
    if (atual != null) return atual;
    return (await _auth.signInAnonymously()).user!;
  }

  Stream<List<Estande>> estandesAtivos() => _db
      .collection('estandes')
      .where('ativo', isEqualTo: true)
      .snapshots()
      .map((s) => s.docs.map(Estande.fromDoc).toList()
        ..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase())));

  /// IDs dos estandes que o visitante já visitou (para marcar a lista).
  Stream<Set<String>> minhasVisitas() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(<String>{});
    return _db
        .collection('checkins')
        .where('visitanteId', isEqualTo: uid)
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()['estandeId'] as String).toSet());
  }

  Future<CheckinResultado> registrarCheckin(String bruto) async {
    final id = bruto.trim();
    if (!idValido(id)) return const CheckinResultado(CheckinStatus.qrInvalido);

    try {
      final user = await garantirSessao();

      final snap = await _db.collection('estandes').doc(id).get();
      if (!snap.exists) return const CheckinResultado(CheckinStatus.estandeInexistente);
      final estande = Estande.fromDoc(snap);
      if (!estande.ativo) return CheckinResultado(CheckinStatus.estandeInativo, estande);

      final ref = _db.collection('checkins').doc(checkinId(user.uid, id));
      if ((await ref.get()).exists) return CheckinResultado(CheckinStatus.jaRegistrado, estande);

      await ref.set({
        'visitanteId': user.uid,
        'estandeId': id,
        'criadoEm': FieldValue.serverTimestamp(),
      });

      await _analytics.logEvent(name: 'checkin_concluido', parameters: {'estande_id': id});
      return CheckinResultado(CheckinStatus.sucesso, estande);
    } on FirebaseException catch (e) {
      // As regras negam update de um check-in existente: corrida entre dois toques.
      if (e.code == 'permission-denied') {
        final uid = _auth.currentUser?.uid;
        if (uid != null && (await _db.collection('checkins').doc(checkinId(uid, id)).get()).exists) {
          return const CheckinResultado(CheckinStatus.jaRegistrado);
        }
      }
      return const CheckinResultado(CheckinStatus.erro);
    } catch (_) {
      return const CheckinResultado(CheckinStatus.erro);
    }
  }

  Future<void> logMissaoAberta(int qtdEstandes) =>
      _analytics.logEvent(name: 'missao_aberta', parameters: {'qtd_estandes': qtdEstandes});
}
