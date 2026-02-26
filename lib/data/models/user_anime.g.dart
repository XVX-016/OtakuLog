// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_anime.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetUserAnimeCollection on Isar {
  IsarCollection<UserAnime> get userAnimes => this.collection();
}

const UserAnimeSchema = CollectionSchema(
  name: r'UserAnime',
  id: -443819380410059137,
  properties: {
    r'animeId': PropertySchema(
      id: 0,
      name: r'animeId',
      type: IsarType.long,
    ),
    r'completedAt': PropertySchema(
      id: 1,
      name: r'completedAt',
      type: IsarType.dateTime,
    ),
    r'durationPerEpisode': PropertySchema(
      id: 2,
      name: r'durationPerEpisode',
      type: IsarType.long,
    ),
    r'rating': PropertySchema(
      id: 3,
      name: r'rating',
      type: IsarType.double,
    ),
    r'startedAt': PropertySchema(
      id: 4,
      name: r'startedAt',
      type: IsarType.dateTime,
    ),
    r'title': PropertySchema(
      id: 5,
      name: r'title',
      type: IsarType.string,
    ),
    r'totalEpisodes': PropertySchema(
      id: 6,
      name: r'totalEpisodes',
      type: IsarType.long,
    ),
    r'watchedEpisodes': PropertySchema(
      id: 7,
      name: r'watchedEpisodes',
      type: IsarType.long,
    )
  },
  estimateSize: _userAnimeEstimateSize,
  serialize: _userAnimeSerialize,
  deserialize: _userAnimeDeserialize,
  deserializeProp: _userAnimeDeserializeProp,
  idName: r'id',
  indexes: {
    r'animeId': IndexSchema(
      id: 4402861282981058668,
      name: r'animeId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'animeId',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _userAnimeGetId,
  getLinks: _userAnimeGetLinks,
  attach: _userAnimeAttach,
  version: '3.1.0+1',
);

int _userAnimeEstimateSize(
  UserAnime object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.title.length * 3;
  return bytesCount;
}

void _userAnimeSerialize(
  UserAnime object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.animeId);
  writer.writeDateTime(offsets[1], object.completedAt);
  writer.writeLong(offsets[2], object.durationPerEpisode);
  writer.writeDouble(offsets[3], object.rating);
  writer.writeDateTime(offsets[4], object.startedAt);
  writer.writeString(offsets[5], object.title);
  writer.writeLong(offsets[6], object.totalEpisodes);
  writer.writeLong(offsets[7], object.watchedEpisodes);
}

UserAnime _userAnimeDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = UserAnime();
  object.animeId = reader.readLong(offsets[0]);
  object.completedAt = reader.readDateTimeOrNull(offsets[1]);
  object.durationPerEpisode = reader.readLong(offsets[2]);
  object.id = id;
  object.rating = reader.readDouble(offsets[3]);
  object.startedAt = reader.readDateTime(offsets[4]);
  object.title = reader.readString(offsets[5]);
  object.totalEpisodes = reader.readLong(offsets[6]);
  object.watchedEpisodes = reader.readLong(offsets[7]);
  return object;
}

P _userAnimeDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readDouble(offset)) as P;
    case 4:
      return (reader.readDateTime(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readLong(offset)) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _userAnimeGetId(UserAnime object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _userAnimeGetLinks(UserAnime object) {
  return [];
}

void _userAnimeAttach(IsarCollection<dynamic> col, Id id, UserAnime object) {
  object.id = id;
}

extension UserAnimeByIndex on IsarCollection<UserAnime> {
  Future<UserAnime?> getByAnimeId(int animeId) {
    return getByIndex(r'animeId', [animeId]);
  }

  UserAnime? getByAnimeIdSync(int animeId) {
    return getByIndexSync(r'animeId', [animeId]);
  }

  Future<bool> deleteByAnimeId(int animeId) {
    return deleteByIndex(r'animeId', [animeId]);
  }

  bool deleteByAnimeIdSync(int animeId) {
    return deleteByIndexSync(r'animeId', [animeId]);
  }

  Future<List<UserAnime?>> getAllByAnimeId(List<int> animeIdValues) {
    final values = animeIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'animeId', values);
  }

  List<UserAnime?> getAllByAnimeIdSync(List<int> animeIdValues) {
    final values = animeIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'animeId', values);
  }

  Future<int> deleteAllByAnimeId(List<int> animeIdValues) {
    final values = animeIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'animeId', values);
  }

  int deleteAllByAnimeIdSync(List<int> animeIdValues) {
    final values = animeIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'animeId', values);
  }

  Future<Id> putByAnimeId(UserAnime object) {
    return putByIndex(r'animeId', object);
  }

  Id putByAnimeIdSync(UserAnime object, {bool saveLinks = true}) {
    return putByIndexSync(r'animeId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByAnimeId(List<UserAnime> objects) {
    return putAllByIndex(r'animeId', objects);
  }

  List<Id> putAllByAnimeIdSync(List<UserAnime> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'animeId', objects, saveLinks: saveLinks);
  }
}

extension UserAnimeQueryWhereSort
    on QueryBuilder<UserAnime, UserAnime, QWhere> {
  QueryBuilder<UserAnime, UserAnime, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterWhere> anyAnimeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'animeId'),
      );
    });
  }
}

extension UserAnimeQueryWhere
    on QueryBuilder<UserAnime, UserAnime, QWhereClause> {
  QueryBuilder<UserAnime, UserAnime, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterWhereClause> animeIdEqualTo(
      int animeId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'animeId',
        value: [animeId],
      ));
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterWhereClause> animeIdNotEqualTo(
      int animeId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'animeId',
              lower: [],
              upper: [animeId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'animeId',
              lower: [animeId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'animeId',
              lower: [animeId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'animeId',
              lower: [],
              upper: [animeId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterWhereClause> animeIdGreaterThan(
    int animeId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'animeId',
        lower: [animeId],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterWhereClause> animeIdLessThan(
    int animeId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'animeId',
        lower: [],
        upper: [animeId],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterWhereClause> animeIdBetween(
    int lowerAnimeId,
    int upperAnimeId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'animeId',
        lower: [lowerAnimeId],
        includeLower: includeLower,
        upper: [upperAnimeId],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension UserAnimeQueryFilter
    on QueryBuilder<UserAnime, UserAnime, QFilterCondition> {
  QueryBuilder<UserAnime, UserAnime, QAfterFilterCondition> animeIdEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'animeId',
        value: value,
      ));
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterFilterCondition> animeIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'animeId',
        value: value,
      ));
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterFilterCondition> animeIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'animeId',
        value: value,
      ));
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterFilterCondition> animeIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'animeId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterFilterCondition>
      completedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'completedAt',
      ));
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterFilterCondition>
      completedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'completedAt',
      ));
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterFilterCondition> completedAtEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'completedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterFilterCondition>
      completedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'completedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterFilterCondition> completedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'completedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterFilterCondition> completedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'completedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterFilterCondition>
      durationPerEpisodeEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'durationPerEpisode',
        value: value,
      ));
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterFilterCondition>
      durationPerEpisodeGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'durationPerEpisode',
        value: value,
      ));
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterFilterCondition>
      durationPerEpisodeLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'durationPerEpisode',
        value: value,
      ));
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterFilterCondition>
      durationPerEpisodeBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'durationPerEpisode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterFilterCondition> ratingEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rating',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterFilterCondition> ratingGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'rating',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterFilterCondition> ratingLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'rating',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterFilterCondition> ratingBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'rating',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterFilterCondition> startedAtEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'startedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterFilterCondition>
      startedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'startedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterFilterCondition> startedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'startedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterFilterCondition> startedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'startedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterFilterCondition> titleEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterFilterCondition> titleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterFilterCondition> titleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterFilterCondition> titleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'title',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterFilterCondition> titleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterFilterCondition> titleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterFilterCondition> titleContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterFilterCondition> titleMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'title',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterFilterCondition> titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterFilterCondition> titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterFilterCondition>
      totalEpisodesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalEpisodes',
        value: value,
      ));
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterFilterCondition>
      totalEpisodesGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalEpisodes',
        value: value,
      ));
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterFilterCondition>
      totalEpisodesLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalEpisodes',
        value: value,
      ));
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterFilterCondition>
      totalEpisodesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalEpisodes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterFilterCondition>
      watchedEpisodesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'watchedEpisodes',
        value: value,
      ));
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterFilterCondition>
      watchedEpisodesGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'watchedEpisodes',
        value: value,
      ));
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterFilterCondition>
      watchedEpisodesLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'watchedEpisodes',
        value: value,
      ));
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterFilterCondition>
      watchedEpisodesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'watchedEpisodes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension UserAnimeQueryObject
    on QueryBuilder<UserAnime, UserAnime, QFilterCondition> {}

extension UserAnimeQueryLinks
    on QueryBuilder<UserAnime, UserAnime, QFilterCondition> {}

extension UserAnimeQuerySortBy on QueryBuilder<UserAnime, UserAnime, QSortBy> {
  QueryBuilder<UserAnime, UserAnime, QAfterSortBy> sortByAnimeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'animeId', Sort.asc);
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterSortBy> sortByAnimeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'animeId', Sort.desc);
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterSortBy> sortByCompletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedAt', Sort.asc);
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterSortBy> sortByCompletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedAt', Sort.desc);
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterSortBy> sortByDurationPerEpisode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationPerEpisode', Sort.asc);
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterSortBy>
      sortByDurationPerEpisodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationPerEpisode', Sort.desc);
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterSortBy> sortByRating() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rating', Sort.asc);
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterSortBy> sortByRatingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rating', Sort.desc);
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterSortBy> sortByStartedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startedAt', Sort.asc);
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterSortBy> sortByStartedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startedAt', Sort.desc);
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterSortBy> sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterSortBy> sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterSortBy> sortByTotalEpisodes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalEpisodes', Sort.asc);
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterSortBy> sortByTotalEpisodesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalEpisodes', Sort.desc);
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterSortBy> sortByWatchedEpisodes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'watchedEpisodes', Sort.asc);
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterSortBy> sortByWatchedEpisodesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'watchedEpisodes', Sort.desc);
    });
  }
}

extension UserAnimeQuerySortThenBy
    on QueryBuilder<UserAnime, UserAnime, QSortThenBy> {
  QueryBuilder<UserAnime, UserAnime, QAfterSortBy> thenByAnimeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'animeId', Sort.asc);
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterSortBy> thenByAnimeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'animeId', Sort.desc);
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterSortBy> thenByCompletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedAt', Sort.asc);
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterSortBy> thenByCompletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedAt', Sort.desc);
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterSortBy> thenByDurationPerEpisode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationPerEpisode', Sort.asc);
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterSortBy>
      thenByDurationPerEpisodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationPerEpisode', Sort.desc);
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterSortBy> thenByRating() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rating', Sort.asc);
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterSortBy> thenByRatingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rating', Sort.desc);
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterSortBy> thenByStartedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startedAt', Sort.asc);
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterSortBy> thenByStartedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startedAt', Sort.desc);
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterSortBy> thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterSortBy> thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterSortBy> thenByTotalEpisodes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalEpisodes', Sort.asc);
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterSortBy> thenByTotalEpisodesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalEpisodes', Sort.desc);
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterSortBy> thenByWatchedEpisodes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'watchedEpisodes', Sort.asc);
    });
  }

  QueryBuilder<UserAnime, UserAnime, QAfterSortBy> thenByWatchedEpisodesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'watchedEpisodes', Sort.desc);
    });
  }
}

extension UserAnimeQueryWhereDistinct
    on QueryBuilder<UserAnime, UserAnime, QDistinct> {
  QueryBuilder<UserAnime, UserAnime, QDistinct> distinctByAnimeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'animeId');
    });
  }

  QueryBuilder<UserAnime, UserAnime, QDistinct> distinctByCompletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'completedAt');
    });
  }

  QueryBuilder<UserAnime, UserAnime, QDistinct> distinctByDurationPerEpisode() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'durationPerEpisode');
    });
  }

  QueryBuilder<UserAnime, UserAnime, QDistinct> distinctByRating() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'rating');
    });
  }

  QueryBuilder<UserAnime, UserAnime, QDistinct> distinctByStartedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'startedAt');
    });
  }

  QueryBuilder<UserAnime, UserAnime, QDistinct> distinctByTitle(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UserAnime, UserAnime, QDistinct> distinctByTotalEpisodes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalEpisodes');
    });
  }

  QueryBuilder<UserAnime, UserAnime, QDistinct> distinctByWatchedEpisodes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'watchedEpisodes');
    });
  }
}

extension UserAnimeQueryProperty
    on QueryBuilder<UserAnime, UserAnime, QQueryProperty> {
  QueryBuilder<UserAnime, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<UserAnime, int, QQueryOperations> animeIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'animeId');
    });
  }

  QueryBuilder<UserAnime, DateTime?, QQueryOperations> completedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'completedAt');
    });
  }

  QueryBuilder<UserAnime, int, QQueryOperations> durationPerEpisodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'durationPerEpisode');
    });
  }

  QueryBuilder<UserAnime, double, QQueryOperations> ratingProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rating');
    });
  }

  QueryBuilder<UserAnime, DateTime, QQueryOperations> startedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'startedAt');
    });
  }

  QueryBuilder<UserAnime, String, QQueryOperations> titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }

  QueryBuilder<UserAnime, int, QQueryOperations> totalEpisodesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalEpisodes');
    });
  }

  QueryBuilder<UserAnime, int, QQueryOperations> watchedEpisodesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'watchedEpisodes');
    });
  }
}
