import '../../../../core/session/entities.dart';
import '../repositories/auth_repository.dart';

class Register {
  Register(this._repo);
  final AuthRepository _repo;
  Future<Sesion> call(Map<String, dynamic> datos) => _repo.register(datos);
}
