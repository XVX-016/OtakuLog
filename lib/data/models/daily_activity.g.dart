// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_activity.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetDailyActivityCollection on Isar {
  IsarCollection<DailyActivity> get dailyActivitys => this.collection();
}

const DailyActivitySchema = CollectionSchema(
  name: r'DailyActivity',
  id: -9126954269818939179,
  properties: {
    r'date': PropertySchema(
      id: 0,
      name: r'date',
      type: IsarType.dateTime,
    ),
    r'minutesRead': PropertySchema(
      id: 1,
      name: r'minutesRead',
      type: IsarType.long,
    ),
    r'minutesWatched': PropertySchema(
      id: 2,
      name: r'minutesWatched',
      type: IsarType.long,
    )
  },
  estimateSize: _dailyActivityEstimateSize,
  serialize: _dailyActivitySerialize,
  deserialize: _dailyActivityDeserialize,
  deserializeProp: _dailyActivityDeserializeProp,
  idName: r'id',
  indexes: {
    r'date': IndexSchema(
      id: -7552997827385218417,
      name: r'date',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'date',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _dailyActivityGetId,
  getLinks: _dailyActivityGetLinks,
  attach: _dailyActivityAttach,
  version: '3.1.0+1',
);

int _dailyActivityEstimateSize(
  DailyActivity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  return bytesCount;
}

void _dailyActivitySerialize(
  DailyActivity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.date);
  writer.writeLong(offsets[1], object.minutesRead);
  writer.writeLong(offsets[2], object.minutesWatched);
}

DailyActivity _dailyActivityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = DailyActivity();
  object.date = reader.readDateTime(offsets[0]);
  object.id = id;
  object.minutesRead = reader.readLong(offsets[1]);
  object.minutesWatched = reader.readLong(offsets[2]);
  return object;
}

P _dailyActivityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _dailyActivityGetId(DailyActivity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _dailyActivityGetLinks(DailyActivity object) {
  return [];
}

void _dailyActivityAttach(
    IsarCollection<dynamic> col, Id id, DailyActivity object) {
  object.id = id;
}

extension DailyActivityByIndex on IsarCollection<DailyActivity> {
  Future<DailyActivity?> getByDate(DateTime date) {
    return getByIndex(r'date', [date]);
  }

  DailyActivity? getByDateSync(DateTime date) {
    return getByIndexSync(r'date', [date]);
  }

  Future<bool> deleteByDate(DateTime date) {
    return deleteByIndex(r'date', [date]);
  }

  bool deleteByDateSync(DateTime date) {
    return deleteByIndexSync(r'date', [date]);
  }

  Future<List<DailyActivity?>> getAllByDate(List<DateTime> dateValues) {
    final values = dateValues.map((e) => [e]).toList();
    return getAllByIndex(r'date', values);
  }

  List<DailyActivity?> getAllByDateSync(List<DateTime> dateValues) {
    final values = dateValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'date', values);
  }

  Future<int> deleteAllByDate(List<DateTime> dateValues) {
    final values = dateValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'date', values);
  }

  int deleteAllByDateSync(List<DateTime> dateValues) {
    final values = dateValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'date', values);
  }

  Future<Id> putByDate(DailyActivity object) {
    return putByIndex(r'date', object);
  }

  Id putByDateSync(DailyActivity object, {bool saveLinks = true}) {
    return putByIndexSync(r'date', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByDate(List<DailyActivity> objects) {
    return putAllByIndex(r'date', objects);
  }

  List<Id> putAllByDateSync(List<DailyActivity> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'date', objects, saveLinks: saveLinks);
  }
}

extension DailyActivityQueryWhereSort
    on QueryBuilder<DailyActivity, DailyActivity, QWhere> {
  QueryBuilder<DailyActivity, DailyActivity, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterWhere> anyDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'date'),
      );
    });
  }
}

extension DailyActivityQueryWhere
    on QueryBuilder<DailyActivity, DailyActivity, QWhereClause> {
  QueryBuilder<DailyActivity, DailyActivity, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterWhereClause> idNotEqualTo(
      Id id) {
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

  QueryBuilder<DailyActivity, DailyActivity, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterWhereClause> idBetween(
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

  QueryBuilder<DailyActivity, DailyActivity, QAfterWhereClause> dateEqualTo(
      DateTime date) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'date',
        value: [date],
      ));
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterWhereClause> dateNotEqualTo(
      DateTime date) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [],
              upper: [date],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [date],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [date],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [],
              upper: [date],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterWhereClause> dateGreaterThan(
    DateTime date, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'date',
        lower: [date],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterWhereClause> dateLessThan(
    DateTime date, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'date',
        lower: [],
        upper: [date],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterWhereClause> dateBetween(
    DateTime lowerDate,
    DateTime upperDate, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'date',
        lower: [lowerDate],
        includeLower: includeLower,
        upper: [upperDate],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension DailyActivityQueryFilter
    on QueryBuilder<DailyActivity, DailyActivity, QFilterCondition> {
  QueryBuilder<DailyActivity, DailyActivity, QAfterFilterCondition> dateEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterFilterCondition>
      dateGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterFilterCondition>
      dateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterFilterCondition> dateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'date',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterFilterCondition>
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

  QueryBuilder<DailyActivity, DailyActivity, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<DailyActivity, DailyActivity, QAfterFilterCondition> idBetween(
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

  QueryBuilder<DailyActivity, DailyActivity, QAfterFilterCondition>
      minutesReadEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'minutesRead',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterFilterCondition>
      minutesReadGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'minutesRead',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterFilterCondition>
      minutesReadLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'minutesRead',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterFilterCondition>
      minutesReadBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'minutesRead',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterFilterCondition>
      minutesWatchedEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'minutesWatched',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterFilterCondition>
      minutesWatchedGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'minutesWatched',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterFilterCondition>
      minutesWatchedLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'minutesWatched',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterFilterCondition>
      minutesWatchedBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'minutesWatched',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension DailyActivityQueryObject
    on QueryBuilder<DailyActivity, DailyActivity, QFilterCondition> {}

extension DailyActivityQueryLinks
    on QueryBuilder<DailyActivity, DailyActivity, QFilterCondition> {}

extension DailyActivityQuerySortBy
    on QueryBuilder<DailyActivity, DailyActivity, QSortBy> {
  QueryBuilder<DailyActivity, DailyActivity, QAfterSortBy> sortByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterSortBy> sortByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterSortBy> sortByMinutesRead() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minutesRead', Sort.asc);
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterSortBy>
      sortByMinutesReadDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minutesRead', Sort.desc);
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterSortBy>
      sortByMinutesWatched() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minutesWatched', Sort.asc);
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterSortBy>
      sortByMinutesWatchedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minutesWatched', Sort.desc);
    });
  }
}

extension DailyActivityQuerySortThenBy
    on QueryBuilder<DailyActivity, DailyActivity, QSortThenBy> {
  QueryBuilder<DailyActivity, DailyActivity, QAfterSortBy> thenByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterSortBy> thenByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterSortBy> thenByMinutesRead() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minutesRead', Sort.asc);
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterSortBy>
      thenByMinutesReadDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minutesRead', Sort.desc);
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterSortBy>
      thenByMinutesWatched() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minutesWatched', Sort.asc);
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QAfterSortBy>
      thenByMinutesWatchedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minutesWatched', Sort.desc);
    });
  }
}

extension DailyActivityQueryWhereDistinct
    on QueryBuilder<DailyActivity, DailyActivity, QDistinct> {
  QueryBuilder<DailyActivity, DailyActivity, QDistinct> distinctByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'date');
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QDistinct>
      distinctByMinutesRead() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'minutesRead');
    });
  }

  QueryBuilder<DailyActivity, DailyActivity, QDistinct>
      distinctByMinutesWatched() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'minutesWatched');
    });
  }
}

extension DailyActivityQueryProperty
    on QueryBuilder<DailyActivity, DailyActivity, QQueryProperty> {
  QueryBuilder<DailyActivity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<DailyActivity, DateTime, QQueryOperations> dateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'date');
    });
  }

  QueryBuilder<DailyActivity, int, QQueryOperations> minutesReadProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'minutesRead');
    });
  }

  QueryBuilder<DailyActivity, int, QQueryOperations> minutesWatchedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'minutesWatched');
    });
  }
}
