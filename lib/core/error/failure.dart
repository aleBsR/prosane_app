sealed class Failure {
  const Failure(this.mensaje);
  final String mensaje;
}

class NoConnectionFailure extends Failure {
  const NoConnectionFailure() : super('Necesitás conexión para iniciar sesión');
}

class InvalidCredentialsFailure extends Failure {
  const InvalidCredentialsFailure() : super('Credenciales incorrectas');
}

class ServerFailure extends Failure {
  const ServerFailure() : super('Hubo un problema, probá de nuevo');
}

class UnknownFailure extends Failure {
  const UnknownFailure() : super('Hubo un problema, probá de nuevo');
}
