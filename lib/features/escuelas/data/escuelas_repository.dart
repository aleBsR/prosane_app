import 'package:dio/dio.dart';

class Escuela {
  final String id;
  final String nombre;
  final String? cue;
  final String? ambito;
  final String? sectorGestion;
  final String? modalidadEducativa;
  final String? telefono;
  final bool interculturalBilingue;
  final bool plurigradoRural;

  Escuela({
    required this.id,
    required this.nombre,
    this.cue,
    this.ambito,
    this.sectorGestion,
    this.modalidadEducativa,
    this.telefono,
    this.interculturalBilingue = false,
    this.plurigradoRural = false,
  });

  factory Escuela.fromJson(Map<String, dynamic> json) {
    return Escuela(
      id: json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      cue: json['cue'],
      ambito: json['ambito'],
      sectorGestion: json['sector_gestion'],
      modalidadEducativa: json['modalidad_educativa'],
      telefono: json['telefono'],
      interculturalBilingue: json['intercultural_bilingue'] ?? false,
      plurigradoRural: json['plurigrado_rural'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'cue': cue,
        'ambito': ambito,
        'sector_gestion': sectorGestion,
        'modalidad_educativa': modalidadEducativa,
        'telefono': telefono,
        'intercultural_bilingue': interculturalBilingue,
        'plurigrado_rural': plurigradoRural,
      };
}

class EscuelasRepository {
  final Dio _dio;

  EscuelasRepository(this._dio);

  Future<List<Escuela>> listar() async {
    try {
      final res = await _dio.get('/escuelas/?activa=true');
      if (res.statusCode == 200) {
        final data = res.data as List;
        return data.map((e) => Escuela.fromJson(e as Map<String, dynamic>)).toList();
      }
      throw Exception('Error ${res.statusCode}');
    } on DioException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<Escuela> crear(Map<String, dynamic> payload) async {
    try {
      final res = await _dio.post('/escuelas/', data: payload);
      if (res.statusCode == 201) {
        return Escuela.fromJson(res.data as Map<String, dynamic>);
      }
      throw Exception('Error ${res.statusCode}');
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw Exception('CUE duplicado');
      }
      throw Exception(e.message);
    }
  }
}
