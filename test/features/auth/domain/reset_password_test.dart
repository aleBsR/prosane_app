import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:prosane_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:prosane_app/features/auth/domain/usecases/reset_password.dart';

class _MockAuthRepo extends Mock implements AuthRepository {}

void main() {
  test('SolicitarResetPassword delega en el repositorio', () async {
    final repo = _MockAuthRepo();
    when(() => repo.solicitarResetPassword('a@b.com'))
        .thenAnswer((_) async {});
    await SolicitarResetPassword(repo).call('a@b.com');
    verify(() => repo.solicitarResetPassword('a@b.com')).called(1);
  });

  test('ConfirmarResetPassword delega en el repositorio', () async {
    final repo = _MockAuthRepo();
    when(() => repo.confirmarResetPassword('a@b.com', '123456', 'nueva1'))
        .thenAnswer((_) async {});
    await ConfirmarResetPassword(repo).call('a@b.com', '123456', 'nueva1');
    verify(() => repo.confirmarResetPassword('a@b.com', '123456', 'nueva1'))
        .called(1);
  });
}