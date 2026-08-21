import 'package:dio/dio.dart';

class AlumnoEscuela {
  AlumnoEscuela({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.dni,
    required this.fechaNacimiento,
    required this.sexo,
    required this.edad,
    this.localidad = '',
  });

  final String id;
  final String nombre;
  final String apellido;
  final String dni;
  final String fechaNacimiento;
  final String sexo;
  final int edad;
  final String localidad;

  factory AlumnoEscuela.fromJson(Map<String, dynamic> json) {
    final persona = (json['persona'] as Map?)?.cast<String, dynamic>() ?? {};
    final domicilio = (json['domicilio'] as Map?)?.cast<String, dynamic>() ?? {};
    return AlumnoEscuela(
      id: '${json['id'] ?? ''}',
      nombre: '${persona['nombre'] ?? ''}',
      apellido: '${persona['apellido'] ?? ''}',
      dni: '${persona['dni'] ?? ''}',
      fechaNacimiento: '${persona['fecha_nacimiento'] ?? ''}',
      sexo: '${persona['sexo'] ?? ''}',
      edad: (json['edad'] as num?)?.toInt() ?? 0,
      localidad: '${domicilio['localidad'] ?? ''}',
    );
  }
}

class AlumnosEscuelaRepository {
  AlumnosEscuelaRepository(this._dio);
  final Dio _dio;

  Future<List<AlumnoEscuela>> listar() async {
    final res = await _dio.get('/alumnos/');
    final data = res.data as List;
    return data
        .map((e) => AlumnoEscuela.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AlumnoEscuela> crear(Map<String, dynamic> payload) async {
    final res = await _dio.post('/alumnos/', data: payload);
    return AlumnoEscuela.fromJson(res.data as Map<String, dynamic>);
  }
}
