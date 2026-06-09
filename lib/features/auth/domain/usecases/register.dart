import '../repositories/auth_repository.dart';

class Register {
  Register(this._repo);
  final AuthRepository _repo;
  Future<void> call(Map<String, dynamic> datos) => _repo.register(datos);
}
