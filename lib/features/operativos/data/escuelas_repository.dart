import 'package:dio/dio.dart';

class Escuela {
  final String id;
  final String nombre;

  Escuela({required this.id, required this.nombre});

  factory Escuela.fromMap(Map<String, dynamic> map) {
    return Escuela(
      id: map['id'] as String,
      nombre: map['nombre'] as String,
    );
  }
}

class EscuelasRepository {
  final Dio _dio;

  EscuelasRepository(this._dio);

  Future<List<Escuela>> listar() async {
    final resp = await _dio.get('/escuelas/');
    return (resp.data as List).map((e) => Escuela.fromMap(e as Map<String, dynamic>)).toList();
  }
}
