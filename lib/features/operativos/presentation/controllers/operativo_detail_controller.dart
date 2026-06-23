import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import '../../../../core/notificaciones/notificacion_controller.dart';
import '../../data/operativos_repository.dart';

class OperativoDetailState {
  const OperativoDetailState({
    this.operativoActualizado = false,
    this.procesando = false,
    this.error,
  });

  final bool operativoActualizado, procesando;
  final String? error;

  OperativoDetailState copyWith({
    bool? operativoActualizado,
    bool? procesando,
    Object? error = _sentinel,
  }) =>
      OperativoDetailState(
        operativoActualizado: operativoActualizado ?? this.operativoActualizado,
        procesando: procesando ?? this.procesando,
        error: identical(error, _sentinel) ? this.error : error as String?,
      );
}

const _sentinel = Object();

class OperativoDetailController extends StateNotifier<OperativoDetailState> {
  OperativoDetailController({
    required this.repo,
    required this.operativoId,
    required this.notificacionController,
  }) : super(const OperativoDetailState());

  final OperativosRepository repo;
  final String operativoId;
  final NotificacionController notificacionController;

  Future<void> asignarProfesional(String profesionalId, String rol) async {
    state = state.copyWith(procesando: true, error: null);
    try {
      await repo.asignarProfesional(operativoId, profesionalId, rol);
      if (!mounted) return;
      state = state.copyWith(procesando: false, operativoActualizado: true);
      notificacionController.exito('Profesional asignado');
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = _extractErrorMessage(e.response?.data) ??
          'No se pudo asignar el profesional.';
      state = state.copyWith(procesando: false, error: msg);
      notificacionController.error(msg);
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(
          procesando: false, error: 'No se pudo asignar el profesional.');
    }
  }

  Future<void> confirmar() async {
    state = state.copyWith(procesando: true, error: null);
    try {
      await repo.confirmar(operativoId);
      if (!mounted) return;
      state = state.copyWith(procesando: false, operativoActualizado: true);
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(
        procesando: false,
        error: 'No se pudo confirmar el operativo.',
      );
    }
  }

  Future<void> iniciar() async {
    state = state.copyWith(procesando: true, error: null);
    try {
      await repo.iniciar(operativoId);
      if (!mounted) return;
      state = state.copyWith(procesando: false, operativoActualizado: true);
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(
        procesando: false,
        error: 'No se pudo iniciar el operativo.',
      );
    }
  }

  Future<void> finalizar() async {
    state = state.copyWith(procesando: true, error: null);
    try {
      await repo.finalizar(operativoId);
      if (!mounted) return;
      state = state.copyWith(procesando: false, operativoActualizado: true);
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(
        procesando: false,
        error: 'No se pudo finalizar el operativo.',
      );
    }
  }

  Future<void> cancelar() async {
    state = state.copyWith(procesando: true, error: null);
    try {
      await repo.cancelar(operativoId);
      if (!mounted) return;
      state = state.copyWith(procesando: false, operativoActualizado: true);
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(
        procesando: false,
        error: 'No se pudo cancelar el operativo.',
      );
    }
  }

  /// Importa alumnos desde un archivo CSV.
  ///
  /// Realiza un POST a `/api/v1/operativos/<operativoId>/alumnos/importar-csv/`
  /// con el archivo en un campo FormData llamado 'archivo'.
  ///
  /// La respuesta debe tener el formato:
  /// {
  ///   "creados": int,
  ///   "duplicados": int,
  ///   "errores": [string],
  ///   "total_filas": int
  /// }
  Future<void> importarCsv(File archivo) async {
    state = state.copyWith(procesando: true, error: null);
    try {
      // Crea FormData con campo 'archivo'
      final formData = FormData.fromMap({
        'archivo': await MultipartFile.fromFile(
          archivo.path,
          filename: archivo.path.split('/').last,
        ),
      });

      // POST /api/v1/operativos/<operativoId>/alumnos/importar-csv/
      final response = await repo.importarCsv(operativoId, formData);

      if (!mounted) return;

      // Parsea respuesta
      final creados = response['creados'] as int? ?? 0;
      final duplicados = response['duplicados'] as int? ?? 0;
      final errores = List<String>.from(response['errores'] as List? ?? []);

      // Construye mensaje de resultado
      final partes = <String>[];
      if (creados > 0) partes.add('✅ $creados alumnos creados');
      if (duplicados > 0) partes.add('⚠️ $duplicados duplicados');
      final mensaje = partes.isNotEmpty ? partes.join(' | ') : 'Importación completada sin cambios';

      // Notifica resultado
      if (errores.isNotEmpty) {
        notificacionController.error('$mensaje\n\nErrores: ${errores.join(', ')}');
      } else if (partes.isNotEmpty) {
        notificacionController.exito(mensaje);
      }

      state = state.copyWith(procesando: false, operativoActualizado: true);
    } on DioException catch (e) {
      if (!mounted) return;
      final errorMsg = _extractErrorMessage(e.response?.data) ??
          'Error al importar CSV: ${e.message}';
      state = state.copyWith(procesando: false, error: errorMsg);
      notificacionController.error(errorMsg);
    } catch (e) {
      if (!mounted) return;
      final errorMsg = 'Error inesperado al importar CSV: $e';
      state = state.copyWith(procesando: false, error: errorMsg);
      notificacionController.error(errorMsg);
    }
  }

  /// Extrae el mensaje de error de la respuesta del servidor
  String? _extractErrorMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data.containsKey('detail')) {
        return data['detail'];
      } else if (data.containsKey('message')) {
        return data['message'];
      } else if (data.containsKey('error')) {
        return data['error'];
      }
      // Si hay campos específicos con errores
      for (final value in data.values) {
        if (value is List && value.isNotEmpty) {
          return value.first.toString();
        }
      }
    }
    return null;
  }
}

final operativoDetailControllerProvider = StateNotifierProvider.autoDispose
    .family<OperativoDetailController, OperativoDetailState, String>((ref, operativoId) {
  return OperativoDetailController(
    repo: ref.watch(operativosRepositoryProvider),
    operativoId: operativoId,
    notificacionController: ref.watch(notificacionProvider.notifier),
  );
});

final operativoDetailProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, operativoId) async {
  final repo = ref.watch(operativosRepositoryProvider);
  return repo.detalle(operativoId);
});

final profesionalesDisponiblesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(operativosRepositoryProvider);
  return repo.profesionalesDisponibles();
});
