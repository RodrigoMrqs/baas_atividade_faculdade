import 'package:baas_atividade_faculdade/models/estande.dart';
import 'package:baas_atividade_faculdade/services/estande_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EstandeRepository', () {
    test('valida ids de QR code', () {
      expect(EstandeRepository.idValido('e01'), isTrue);
      expect(EstandeRepository.idValido('Abc_12-x'), isTrue);
      expect(EstandeRepository.idValido(''), isFalse);
      expect(EstandeRepository.idValido('https://exemplo.com'), isFalse);
      expect(EstandeRepository.idValido('a/b'), isFalse);
    });

    test('chave composta visitante+estande', () {
      expect(EstandeRepository.checkinId('uid1', 'e03'), 'uid1_e03');
    });
  });

  test('Estande.fromMap tolera campos ausentes', () {
    final e = Estande.fromMap('e01', {'nome': 'X', 'ativo': true});
    expect(e.descricao, '');
    expect(e.localizacao, '');
    expect(e.ativo, isTrue);
    expect(Estande.fromMap('e02', {}).ativo, isFalse);
  });
}
