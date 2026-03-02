// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_session_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetUserSessionModelCollection on Isar {
  IsarCollection<UserSessionModel> get userSessionModels => this.collection();
}

const UserSessionModelSchema = CollectionSchema(
  name: r'UserSessionModel',
  id: 5302808398292509013,
  properties: {
    r'contentId': PropertySchema(
      id: 0,
      name: r'contentId',
      type: IsarType.string,
    ),
    r'contentType': PropertySchema(
      id: 1,
      name: r'contentType',
      type: IsarType.byte,
      enumMap: _UserSessionModelcontentTypeEnumValueMap,
    ),
    r'endTime': PropertySchema(
      id: 2,
      name: r'endTime',
      type: IsarType.dateTime,
    ),
    r'startTime': PropertySchema(
      id: 3,
      name: r'startTime',
      type: IsarType.dateTime,
    ),
    r'unitsConsumed': PropertySchema(
      id: 4,
      name: r'unitsConsumed',
      type: IsarType.long,
    )
  },
  estimateSize: _userSessionModelEstimateSize,
  serialize: _userSessionModelSerialize,
  deserialize: _userSessionModelDeserialize,
  deserializeProp: _userSessionModelDeserializeProp,
  idName: r'id',
  indexes: {
    r'contentId': IndexSchema(
      id: -332487537278013663,
      name: r'contentId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'contentId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _userSessionModelGetId,
  getLinks: _userSessionModelGetLinks,
  attach: _userSessionModelAttach,
  version: '3.1.0+1',
);

int _userSessionModelEstimateSize(
  UserSessionModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.contentId.length * 3;
  return bytesCount;
}

void _userSessionModelSerialize(
  UserSessionModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.contentId);
  writer.writeByte(offsets[1], object.contentType.index);
  writer.writeDateTime(offsets[2], object.endTime);
  writer.writeDateTime(offsets[3], object.startTime);
  writer.writeLong(offsets[4], object.unitsConsumed);
}

UserSessionModel _userSessionModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = UserSessionModel();
  object.contentId = reader.readString(offsets[0]);
  object.contentType = _UserSessionModelcontentTypeValueEnumMap[
          reader.readByteOrNull(offsets[1])] ??
      SessionContentTypeModel.anime;
  object.endTime = reader.readDateTime(offsets[2]);
  object.id = id;
  object.startTime = reader.readDateTime(offsets[3]);
  object.unitsConsumed = reader.readLong(offsets[4]);
  return object;
}

P _userSessionModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (_UserSessionModelcontentTypeValueEnumMap[
              reader.readByteOrNull(offset)] ??
          SessionContentTypeModel.anime) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readDateTime(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _UserSessionModelcontentTypeEnumValueMap = {
  'anime': 0,
  'manga': 1,
};
const _UserSessionModelcontentTypeValueEnumMap = {
  0: SessionContentTypeModel.anime,
  1: SessionContentTypeModel.manga,
};

Id _userSessionModelGetId(UserSessionModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _userSessionModelGetLinks(UserSessionModel object) {
  return [];
}

void _userSessionModelAttach(
    IsarCollection<dynamic> col, Id id, UserSessionModel object) {
  object.id = id;
}

extension UserSessionModelQueryWhereSort
    on QueryBuilder<UserSessionModel, UserSessionModel, QWhere> {
  QueryBuilder<UserSessionModel, UserSessionModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension UserSessionModelQueryWhere
    on QueryBuilder<UserSessionModel, UserSessionModel, QWhereClause> {
  QueryBuilder<UserSessionModel, UserSessionModel, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<UserSessionModel, UserSessionModel, QAfterWhereClause>
      idNotEqualTo(Id id) {
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

  QueryBuilder<UserSessionModel, UserSessionModel, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<UserSessionModel, UserSessionModel, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<UserSessionModel, UserSessionModel, QAfterWhereClause> idBetween(
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

  QueryBuilder<UserSessionModel, UserSessionModel, QAfterWhereClause>
      contentIdEqualTo(String contentId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'contentId',
        value: [contentId],
      ));
    });
  }

  QueryBuilder<UserSessionModel, UserSessionModel, QAfterWhereClause>
      contentIdNotEqualTo(String contentId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'contentId',
              lower: [],
              upper: [contentId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'contentId',
              lower: [contentId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'contentId',
              lower: [contentId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'contentId',
              lower: [],
              upper: [contentId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension UserSessionModelQueryFilter
    on QueryBuilder<UserSessionModel, UserSessionModel, QFilterCondition> {
  QueryBuilder<UserSessionModel, UserSessionModel, QAfterFilterCondition>
      contentIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'contentId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserSessionModel, UserSessionModel, QAfterFilterCondition>
      contentIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'contentId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserSessionModel, UserSessionModel, QAfterFilterCondition>
      contentIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'contentId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserSessionModel, UserSessionModel, QAfterFilterCondition>
      contentIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'contentId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserSessionModel, UserSessionModel, QAfterFilterCondition>
      contentIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'contentId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserSessionModel, UserSessionModel, QAfterFilterCondition>
      contentIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'contentId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserSessionModel, UserSessionModel, QAfterFilterCondition>
      contentIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'contentId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserSessionModel, UserSessionModel, QAfterFilterCondition>
      contentIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'contentId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserSessionModel, UserSessionModel, QAfterFilterCondition>
      contentIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'contentId',
        value: '',
      ));
    });
  }

  QueryBuilder<UserSessionModel, UserSessionModel, QAfterFilterCondition>
      contentIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'contentId',
        value: '',
      ));
    });
  }

  QueryBuilder<UserSessionModel, UserSessionModel, QAfterFilterCondition>
      contentTypeEqualTo(SessionContentTypeModel value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'contentType',
        value: value,
      ));
    });
  }

  QueryBuilder<UserSessionModel, UserSessionModel, QAfterFilterCondition>
      contentTypeGreaterThan(
    SessionContentTypeModel value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'contentType',
        value: value,
      ));
    });
  }

  QueryBuilder<UserSessionModel, UserSessionModel, QAfterFilterCondition>
      contentTypeLessThan(
    SessionContentTypeModel value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'contentType',
        value: value,
      ));
    });
  }

  QueryBuilder<UserSessionModel, UserSessionModel, QAfterFilterCondition>
      contentTypeBetween(
    SessionContentTypeModel lower,
    SessionContentTypeModel upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'contentType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<UserSessionModel, UserSessionModel, QAfterFilterCondition>
      endTimeEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'endTime',
        value: value,
      ));
    });
  }

  QueryBuilder<UserSessionModel, UserSessionModel, QAfterFilterCondition>
      endTimeGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'endTime',
        value: value,
      ));
    });
  }

  QueryBuilder<UserSessionModel, UserSessionModel, QAfterFilterCondition>
      endTimeLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'endTime',
        value: value,
      ));
    });
  }

  QueryBuilder<UserSessionModel, UserSessionModel, QAfterFilterCondition>
      endTimeBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'endTime',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<UserSessionModel, UserSessionModel, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<UserSessionModel, UserSessionModel, QAfterFilterCondition>
      idGreaterThan(
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

  QueryBuilder<UserSessionModel, UserSessionModel, QAfterFilterCondition>
      idLessThan(
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

  QueryBuilder<UserSessionModel, UserSessionModel, QAfterFilterCondition>
      idBetween(
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

  QueryBuilder<UserSessionModel, UserSessionModel, QAfterFilterCondition>
      startTimeEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'startTime',
        value: value,
      ));
    });
  }

  QueryBuilder<UserSessionModel, UserSessionModel, QAfterFilterCondition>
      startTimeGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'startTime',
        value: value,
      ));
    });
  }

  QueryBuilder<UserSessionModel, UserSessionModel, QAfterFilterCondition>
      startTimeLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'startTime',
        value: value,
      ));
    });
  }

  QueryBuilder<UserSessionModel, UserSessionModel, QAfterFilterCondition>
      startTimeBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'startTime',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<UserSessionModel, UserSessionModel, QAfterFilterCondition>
      unitsConsumedEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'unitsConsumed',
        value: value,
      ));
    });
  }

  QueryBuilder<UserSessionModel, UserSessionModel, QAfterFilterCondition>
      unitsConsumedGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'unitsConsumed',
        value: value,
      ));
    });
  }

  QueryBuilder<UserSessionModel, UserSessionModel, QAfterFilterCondition>
      unitsConsumedLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'unitsConsumed',
        value: value,
      ));
    });
  }

  QueryBuilder<UserSessionModel, UserSessionModel, QAfterFilterCondition>
      unitsConsumedBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'unitsConsumed',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension UserSessionModelQueryObject
    on QueryBuilder<UserSessionModel, UserSessionModel, QFilterCondition> {}

extension UserSessionModelQueryLinks
    on QueryBuilder<UserSessionModel, UserSessionModel, QFilterCondition> {}

extension UserSessionModelQuerySortBy
    on QueryBuilder<UserSessionModel, UserSessionModel, QSortBy> {
  QueryBuilder<UserSessionModel, UserSessionModel, QAfterSortBy>
      sortByContentId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contentId', Sort.asc);
    });
  }

  QueryBuilder<UserSessionModel, UserSessionModel, QAfterSortBy>
      sortByContentIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contentId', Sort.desc);
    });
  }

  QueryBuilder<UserSessionModel, UserSessionModel, QAfterSortBy>
      sortByContentType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contentType', Sort.asc);
    });
  }

  QueryBuilder<UserSessionModel, UserSessionModel, QAfterSortBy>
      sortByContentTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contentType', Sort.desc);
    });
  }

  QueryBuilder<UserSessionModel, UserSessionModel, QAfterSortBy>
      sortByEndTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endTime', Sort.asc);
    });
  }

  QueryBuilder<UserSessionModel, UserSessionModel, QAfterSortBy>
      sortByEndTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endTime', Sort.desc);
    });
  }

  QueryBuilder<UserSessionModel, UserSessionModel, QAfterSortBy>
      sortByStartTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startTime', Sort.asc);
    });
  }

  QueryBuilder<UserSessionModel, UserSessionModel, QAfterSortBy>
      sortByStartTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startTime', Sort.desc);
    });
  }

  QueryBuilder<UserSessionModel, UserSessionModel, QAfterSortBy>
      sortByUnitsConsumed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unitsConsumed', Sort.asc);
    });
  }

  QueryBuilder<UserSessionModel, UserSessionModel, QAfterSortBy>
      sortByUnitsConsumedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unitsConsumed', Sort.desc);
    });
  }
}

extension UserSessionModelQuerySortThenBy
    on QueryBuilder<UserSessionModel, UserSessionModel, QSortThenBy> {
  QueryBuilder<UserSessionModel, UserSessionModel, QAfterSortBy>
      thenByContentId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contentId', Sort.asc);
    });
  }

  QueryBuilder<UserSessionModel, UserSessionModel, QAfterSortBy>
      thenByContentIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contentId', Sort.desc);
    });
  }

  QueryBuilder<UserSessionModel, UserSessionModel, QAfterSortBy>
      thenByContentType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contentType', Sort.asc);
    });
  }

  QueryBuilder<UserSessionModel, UserSessionModel, QAfterSortBy>
      thenByContentTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contentType', Sort.desc);
    });
  }

  QueryBuilder<UserSessionModel, UserSessionModel, QAfterSortBy>
      thenByEndTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endTime', Sort.asc);
    });
  }

  QueryBuilder<UserSessionModel, UserSessionModel, QAfterSortBy>
      thenByEndTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endTime', Sort.desc);
    });
  }

  QueryBuilder<UserSessionModel, UserSessionModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<UserSessionModel, UserSessionModel, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<UserSessionModel, UserSessionModel, QAfterSortBy>
      thenByStartTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startTime', Sort.asc);
    });
  }

  QueryBuilder<UserSessionModel, UserSessionModel, QAfterSortBy>
      thenByStartTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startTime', Sort.desc);
    });
  }

  QueryBuilder<UserSessionModel, UserSessionModel, QAfterSortBy>
      thenByUnitsConsumed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unitsConsumed', Sort.asc);
    });
  }

  QueryBuilder<UserSessionModel, UserSessionModel, QAfterSortBy>
      thenByUnitsConsumedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unitsConsumed', Sort.desc);
    });
  }
}

extension UserSessionModelQueryWhereDistinct
    on QueryBuilder<UserSessionModel, UserSessionModel, QDistinct> {
  QueryBuilder<UserSessionModel, UserSessionModel, QDistinct>
      distinctByContentId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'contentId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UserSessionModel, UserSessionModel, QDistinct>
      distinctByContentType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'contentType');
    });
  }

  QueryBuilder<UserSessionModel, UserSessionModel, QDistinct>
      distinctByEndTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'endTime');
    });
  }

  QueryBuilder<UserSessionModel, UserSessionModel, QDistinct>
      distinctByStartTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'startTime');
    });
  }

  QueryBuilder<UserSessionModel, UserSessionModel, QDistinct>
      distinctByUnitsConsumed() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'unitsConsumed');
    });
  }
}

extension UserSessionModelQueryProperty
    on QueryBuilder<UserSessionModel, UserSessionModel, QQueryProperty> {
  QueryBuilder<UserSessionModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<UserSessionModel, String, QQueryOperations> contentIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'contentId');
    });
  }

  QueryBuilder<UserSessionModel, SessionContentTypeModel, QQueryOperations>
      contentTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'contentType');
    });
  }

  QueryBuilder<UserSessionModel, DateTime, QQueryOperations> endTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'endTime');
    });
  }

  QueryBuilder<UserSessionModel, DateTime, QQueryOperations>
      startTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'startTime');
    });
  }

  QueryBuilder<UserSessionModel, int, QQueryOperations>
      unitsConsumedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'unitsConsumed');
    });
  }
}
