import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otakulog/data/remote/anilist_service.dart';
import 'package:otakulog/data/remote/mangadex_service.dart';
import 'package:otakulog/features/search/models/search_filters.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  late _MockDio dio;

  setUp(() {
    registerFallbackValue(const SearchFilters());
    dio = _MockDio();
  });

  test('AniList sends safe filters for adult mode off', () async {
    when(() => dio.post(any(), data: any(named: 'data'))).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: ''),
        data: {
          'data': {
            'Page': {'media': []}
          }
        },
      ),
    );

    final service = AnilistService(dio: dio);
    await service.searchAnime(
      'bleach',
      page: 2,
      perPage: 25,
      filters: const SearchFilters(adultMode: AdultMode.off),
    );

    final verification = verify(() => dio.post('', data: captureAny(named: 'data')));
    final payload = verification.captured.single as Map<String, dynamic>;
    final variables = payload['variables'] as Map<String, dynamic>;
    expect(variables['search'], 'bleach');
    expect(variables['isAdult'], isFalse);
    expect(variables['tagNotIn'], isA<List<String>>());
  });

  test('AniList sends adult tags for explicit mode', () async {
    when(() => dio.post(any(), data: any(named: 'data'))).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: ''),
        data: {
          'data': {
            'Page': {'media': []}
          }
        },
      ),
    );

    final service = AnilistService(dio: dio);
    await service.fetchTrendingAnime(
      page: 1,
      perPage: 25,
      filters: const SearchFilters(adultMode: AdultMode.explicitOnly),
    );

    final verification = verify(() => dio.post('', data: captureAny(named: 'data')));
    final payload = verification.captured.single as Map<String, dynamic>;
    final variables = payload['variables'] as Map<String, dynamic>;
    expect(variables['tagIn'], isA<List<String>>());
    expect(variables.containsKey('isAdult'), isFalse);
  });

  test('MangaDex includes safe content ratings when adult mode is off', () async {
    when(() => dio.get(any(), queryParameters: any(named: 'queryParameters'))).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/manga'),
        data: {'data': []},
      ),
    );

    final service = MangadexService(dio: dio);
    await service.searchManga(
      'chainsaw man',
      page: 3,
      perPage: 25,
      filters: const SearchFilters(medium: SearchMedium.manga, adultMode: AdultMode.off),
    );

    final verification = verify(() => dio.get('/manga', queryParameters: captureAny(named: 'queryParameters')));
    final params = verification.captured.single as Map<String, dynamic>;
    expect(params['contentRating[]'], ['safe', 'suggestive']);
    expect(params['excludedTags[]'], isA<List<String>>());
    expect(params['offset'], 50);
  });

  test('MangaDex includes adult tag filters for explicit mode', () async {
    when(() => dio.get(any(), queryParameters: any(named: 'queryParameters'))).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/manga'),
        data: {'data': []},
      ),
    );

    final service = MangadexService(dio: dio);
    await service.fetchTrendingManga(
      page: 1,
      perPage: 25,
      filters: const SearchFilters(medium: SearchMedium.manga, adultMode: AdultMode.explicitOnly),
    );

    final verification = verify(() => dio.get('/manga', queryParameters: captureAny(named: 'queryParameters')));
    final params = verification.captured.single as Map<String, dynamic>;
    expect(params['contentRating[]'], ['erotica', 'pornographic']);
    expect(params['includedTags[]'], isA<List<String>>());
  });
}
