import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/providers.dart';
import '../../../../core/session/entities.dart';
import '../../../../core/session/session_controller.dart';
import '../../domain/usecases/register.dart';

part 'signup_controller.freezed.dart';

@freezed
class SignupFormData with _$SignupFormData {
  const factory SignupFormData({
    @Default('') String tipoDocumento,
    @Default('') String numeroDocumento,
    @Default(false) bool aceptaPolitica,
    @Default('') String nombre,
    @Default('') String apellido,
    @Default('') String sexo,
    DateTime? fechaNacimiento,
    @Default('') String lugarNacimiento,
    @Default('') String paisResidencia,
    @Default('') String email,
    @Default('') String confirmEmail,
    @Default('') String password,
    @Default('') String confirmPassword,
  }) = _SignupFormData;
}

@freezed
class SignupState with _$SignupState {
  const factory SignupState({
    @Default(SignupFormData()) SignupFormData formData,
    @Default(0) int currentStep,
    @Default(false) bool isSubmitting,
    String? error,
    @Default(false) bool registrado,
  }) = _SignupState;
}

class SignupController extends StateNotifier<SignupState> {
  SignupController({
    required Register register,
    required void Function(Sesion) onAutenticado,
  })  : _register = register,
        _onAutenticado = onAutenticado,
        super(const SignupState());

  final Register _register;
  final void Function(Sesion) _onAutenticado;

  // --- Setters etapa 0 ---
  void setTipoDocumento(String v) =>
      state = state.copyWith(formData: state.formData.copyWith(tipoDocumento: v));

  void setNumeroDocumento(String v) =>
      state = state.copyWith(formData: state.formData.copyWith(numeroDocumento: v));

  void setAceptaPolitica(bool v) =>
      state = state.copyWith(formData: state.formData.copyWith(aceptaPolitica: v));

  // --- Setters etapa 1 ---
  void setNombre(String v) =>
      state = state.copyWith(formData: state.formData.copyWith(nombre: v));

  void setApellido(String v) =>
      state = state.copyWith(formData: state.formData.copyWith(apellido: v));

  void setSexo(String v) =>
      state = state.copyWith(formData: state.formData.copyWith(sexo: v));

  void setFechaNacimiento(DateTime? v) =>
      state = state.copyWith(formData: state.formData.copyWith(fechaNacimiento: v));

  void setLugarNacimiento(String v) =>
      state = state.copyWith(formData: state.formData.copyWith(lugarNacimiento: v));

  // --- Setters etapa 2 ---
  void setPaisResidencia(String v) =>
      state = state.copyWith(formData: state.formData.copyWith(paisResidencia: v));

  void setEmail(String v) =>
      state = state.copyWith(formData: state.formData.copyWith(email: v));

  void setConfirmEmail(String v) =>
      state = state.copyWith(formData: state.formData.copyWith(confirmEmail: v));

  // --- Setters etapa 3 ---
  void setPassword(String v) =>
      state = state.copyWith(formData: state.formData.copyWith(password: v));

  void setConfirmPassword(String v) =>
      state = state.copyWith(formData: state.formData.copyWith(confirmPassword: v));

  // --- Validación por etapa ---
  bool etapaValida(int step) {
    final f = state.formData;
    switch (step) {
      case 0:
        return f.tipoDocumento.isNotEmpty &&
            f.numeroDocumento.isNotEmpty &&
            RegExp(r'^\d+$').hasMatch(f.numeroDocumento) &&
            f.aceptaPolitica;
      case 1:
        return f.nombre.isNotEmpty &&
            f.apellido.isNotEmpty &&
            f.sexo.isNotEmpty &&
            f.lugarNacimiento.isNotEmpty &&
            f.fechaNacimiento != null;
      case 2:
        return f.paisResidencia.isNotEmpty &&
            _emailValido(f.email) &&
            f.email == f.confirmEmail;
      case 3:
        return f.password.length >= 8 &&
            !f.password.contains(' ') && // sin espacios (teclados móviles los meten)
            f.password == f.confirmPassword;
      default:
        return false;
    }
  }

  static bool _emailValido(String email) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[a-zA-Z]{2,}$').hasMatch(email);

  // --- Navegación ---
  void siguiente() {
    if (etapaValida(state.currentStep) && state.currentStep < 3) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void anterior() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  // --- Envío ---
  Future<void> enviar() async {
    if (state.registrado || state.isSubmitting) return; // evita doble registro
    // Valida TODO el form (no solo la etapa 3): defensa por si la navegación se
    // bypassea. El payload nunca sale con etapas anteriores incompletas.
    if (![0, 1, 2, 3].every(etapaValida)) return;
    state = state.copyWith(isSubmitting: true, error: null);
    final f = state.formData;
    final payload = <String, dynamic>{
      'email': f.email,
      'password': f.password,
      'persona': {
        'nombre': f.nombre,
        'apellido': f.apellido,
        'dni': f.numeroDocumento,
        'tipo_dni': f.tipoDocumento,
        'sexo': f.sexo,
        // El backend (DateField) espera 'YYYY-MM-DD', no un datetime ISO completo.
        'fecha_nacimiento': _soloFecha(f.fechaNacimiento),
      },
    };
    try {
      final sesion = await _register(payload);
      _onAutenticado(sesion);
      state = state.copyWith(isSubmitting: false, registrado: true);
    } on Failure catch (f) {
      state = state.copyWith(isSubmitting: false, error: f.mensaje);
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        error: 'Hubo un problema, probá de nuevo',
      );
    }
  }
}

/// Formatea una fecha como 'YYYY-MM-DD' (lo que espera el DateField del backend),
/// descartando hora y zona. Devuelve null si la fecha es null.
String? _soloFecha(DateTime? d) => d == null
    ? null
    : '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';

// --- Providers ---
final registerUseCaseProvider =
    Provider((ref) => Register(ref.watch(authRepositoryProvider)));

final signupControllerProvider = StateNotifierProvider.autoDispose<
    SignupController, SignupState>(
  (ref) => SignupController(
    register: ref.watch(registerUseCaseProvider),
    onAutenticado: (s) => ref.read(sessionControllerProvider.notifier).setSesion(s),
  ),
);
