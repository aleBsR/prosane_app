import '../../../../core/session/entities.dart';
import '../repositories/auth_repository.dart';

class Login {
  Login(this._repo);
  final AuthRepository _repo;
  Future<Sesion> call(String email, String password, {bool recordarme = true}) =>
      _repo.login(email, password, recordarme: recordarme);
}
