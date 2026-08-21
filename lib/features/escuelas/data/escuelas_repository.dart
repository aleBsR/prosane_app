import 'package:dio/dio.dart';

class Escuela {
  final String id;
  final String nombre;
  final String? cue;
  final String? ambito;
  final String? sectorGestion;
  final String? modalidadEducativa;
  final String? telefono;
  final String? localidad;
  final bool activa;
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
    this.localidad,
    this.activa = true,
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
      localidad: json['localidad'] ??
          (json['domicilio'] is Map ? json['domicilio']['localidad'] : null),
      activa: json['activa'] ?? true,
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
        'localidad': localidad,
        'activa': activa,
        'intercultural_bilingue': interculturalBilingue,
        'plurigrado_rural': plurigradoRural,
      };
}

class Curso {
  final String id;
  final String escuela;
  final String nivel;
  final String salaGradoAnio;
  final String division;
  final int? cicloLectivo;

  Curso({
    required this.id,
    required this.escuela,
    this.nivel = '',
    this.salaGradoAnio = '',
    this.division = '',
    this.cicloLectivo,
  });

  factory Curso.fromJson(Map<String, dynamic> json) {
    return Curso(
      id: json['id'] ?? '',
      escuela: json['escuela'] ?? '',
      nivel: json['nivel'] ?? '',
      salaGradoAnio: json['sala_grado_anio'] ?? '',
      division: json['division'] ?? '',
      cicloLectivo: (json['ciclo_lectivo'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'nivel': nivel,
        'sala_grado_anio': salaGradoAnio,
        'division': division,
        if (cicloLectivo != null) 'ciclo_lectivo': cicloLectivo,
      };

  String get etiqueta {
    final partes = [salaGradoAnio, division].where((p) => p.isNotEmpty);
    return partes.isEmpty ? 'Sin nombre' : partes.join(' ');
  }
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

  Future<Escuela> obtener(String id) async {
    try {
      final res = await _dio.get('/escuelas/$id/');
      if (res.statusCode == 200) {
        return Escuela.fromJson(res.data as Map<String, dynamic>);
      }
      throw Exception('Error ${res.statusCode}');
    } on DioException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<Escuela> editar(String id, Map<String, dynamic> payload) async {
    try {
      final res = await _dio.patch('/escuelas/$id/', data: payload);
      if (res.statusCode == 200) {
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

  Future<void> eliminar(String id) async {
    try {
      final res = await _dio.delete('/escuelas/$id/');
      if (res.statusCode != 204) {
        throw Exception('Error ${res.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<List<Curso>> listarCursos(String escuelaId) async {
    try {
      final res = await _dio.get('/escuelas/$escuelaId/cursos/');
      if (res.statusCode == 200) {
        final data = res.data as List;
        return data.map((e) => Curso.fromJson(e as Map<String, dynamic>)).toList();
      }
      throw Exception('Error ${res.statusCode}');
    } on DioException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<Curso> crearCurso(String escuelaId, Map<String, dynamic> payload) async {
    try {
      final res = await _dio.post('/escuelas/$escuelaId/cursos/', data: payload);
      if (res.statusCode == 201) {
        return Curso.fromJson(res.data as Map<String, dynamic>);
      }
      throw Exception('Error ${res.statusCode}');
    } on DioException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<Curso> editarCurso(
    String escuelaId,
    String cursoId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final res = await _dio.patch('/escuelas/$escuelaId/cursos/$cursoId/', data: payload);
      if (res.statusCode == 200) {
        return Curso.fromJson(res.data as Map<String, dynamic>);
      }
      throw Exception('Error ${res.statusCode}');
    } on DioException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> eliminarCurso(String escuelaId, String cursoId) async {
    try {
      final res = await _dio.delete('/escuelas/$escuelaId/cursos/$cursoId/');
      if (res.statusCode != 204) {
        throw Exception('Error ${res.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<Map<String, dynamic>> miEscuela() async {
    try {
      final res = await _dio.get('/escuelas/mi-escuela/');
      return Map<String, dynamic>.from(res.data as Map);
    } on DioException catch (e) {
      throw Exception(e.message);
    }
  }
}
