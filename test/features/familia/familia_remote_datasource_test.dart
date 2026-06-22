import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:prosane_app/features/familia/data/familia_remote_datasource.dart';

void main() {
  test('aceptarConsentimiento hace POST al endpoint del tutor', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://x/api/v1'));
    final adapter = DioAdapter(dio: dio);
    adapter.onPost(
      '/tutores/tut-1/consentimiento/',
      (s) => s.reply(200, {
        'id': 't1',
        'consentimiento_aceptado': true,
        'fecha_consentimiento': 'x',
      }),
      data: Matchers.any,
    );
    await FamiliaRemoteDataSource(dio).aceptarConsentimiento('tut-1'); // no debe tirar
  });
}
