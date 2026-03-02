// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetUserModelCollection on Isar {
  IsarCollection<UserModel> get userModels => this.collection();
}

const UserModelSchema = CollectionSchema(
  name: r'UserModel',
  id: 7195426469378571114,
  properties: {
    r'avatarPath': PropertySchema(
      id: 0,
      name: r'avatarPath',
      type: IsarType.string,
    ),
    r'defaultAnimeWatchTime': PropertySchema(
      id: 1,
      name: r'defaultAnimeWatchTime',
      type: IsarType.long,
    ),
    r'defaultContentRating': PropertySchema(
      id: 2,
      name: r'defaultContentRating',
      type: IsarType.string,
    ),
    r'defaultMangaReadTime': PropertySchema(
      id: 3,
      name: r'defaultMangaReadTime',
      type: IsarType.long,
    ),
    r'defaultSearchType': PropertySchema(
      id: 4,
      name: r'defaultSearchType',
      type: IsarType.string,
    ),
    r'filter18Plus': PropertySchema(
      id: 5,
      name: r'filter18Plus',
      type: IsarType.bool,
    ),
    r'name': PropertySchema(
      id: 6,
      name: r'name',
      type: IsarType.string,
    )
  },
  estimateSize: _userModelEstimateSize,
  serialize: _userModelSerialize,
  deserialize: _userModelDeserialize,
  deserializeProp: _userModelDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _userModelGetId,
  getLinks: _userModelGetLinks,
  attach: _userModelAttach,
  version: '3.1.0+1',
);

int _userModelEstimateSize(
  UserModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.avatarPath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.defaultContentRating.length * 3;
  bytesCount += 3 + object.defaultSearchType.length * 3;
  bytesCount += 3 + object.name.length * 3;
  return bytesCount;
}

void _userModelSerialize(
  UserModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.avatarPath);
  writer.writeLong(offsets[1], object.defaultAnimeWatchTime);
  writer.writeString(offsets[2], object.defaultContentRating);
  writer.writeLong(offsets[3], object.defaultMangaReadTime);
  writer.writeString(offsets[4], object.defaultSearchType);
  writer.writeBool(offsets[5], object.filter18Plus);
  writer.writeString(offsets[6], object.name);
}

UserModel _userModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = UserModel();
  object.avatarPath = reader.readStringOrNull(offsets[0]);
  object.defaultAnimeWatchTime = reader.readLong(offsets[1]);
  object.defaultContentRating = reader.readString(offsets[2]);
  object.defaultMangaReadTime = reader.readLong(offsets[3]);
  object.defaultSearchType = reader.readString(offsets[4]);
  object.filter18Plus = reader.readBool(offsets[5]);
  object.id = id;
  object.name = reader.readString(offsets[6]);
  return object;
}

P _userModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readBool(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _userModelGetId(UserModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _userModelGetLinks(UserModel object) {
  return [];
}

void _userModelAttach(IsarCollection<dynamic> col, Id id, UserModel object) {
  object.id = id;
}

extension UserModelQueryWhereSort
    on QueryBuilder<UserModel, UserModel, QWhere> {
  QueryBuilder<UserModel, UserModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension UserModelQueryWhere
    on QueryBuilder<UserModel, UserModel, QWhereClause> {
  QueryBuilder<UserModel, UserModel, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<UserModel, UserModel, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterWhereClause> idBetween(
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
}

extension UserModelQueryFilter
    on QueryBuilder<UserModel, UserModel, QFilterCondition> {
  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> avatarPathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'avatarPath',
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      avatarPathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'avatarPath',
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> avatarPathEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'avatarPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      avatarPathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'avatarPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> avatarPathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'avatarPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> avatarPathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'avatarPath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      avatarPathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'avatarPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> avatarPathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'avatarPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> avatarPathContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'avatarPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> avatarPathMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'avatarPath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      avatarPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'avatarPath',
        value: '',
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      avatarPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'avatarPath',
        value: '',
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      defaultAnimeWatchTimeEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'defaultAnimeWatchTime',
        value: value,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      defaultAnimeWatchTimeGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'defaultAnimeWatchTime',
        value: value,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      defaultAnimeWatchTimeLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'defaultAnimeWatchTime',
        value: value,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      defaultAnimeWatchTimeBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'defaultAnimeWatchTime',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      defaultContentRatingEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'defaultContentRating',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      defaultContentRatingGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'defaultContentRating',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      defaultContentRatingLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'defaultContentRating',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      defaultContentRatingBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'defaultContentRating',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      defaultContentRatingStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'defaultContentRating',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      defaultContentRatingEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'defaultContentRating',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      defaultContentRatingContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'defaultContentRating',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      defaultContentRatingMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'defaultContentRating',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      defaultContentRatingIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'defaultContentRating',
        value: '',
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      defaultContentRatingIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'defaultContentRating',
        value: '',
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      defaultMangaReadTimeEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'defaultMangaReadTime',
        value: value,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      defaultMangaReadTimeGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'defaultMangaReadTime',
        value: value,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      defaultMangaReadTimeLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'defaultMangaReadTime',
        value: value,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      defaultMangaReadTimeBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'defaultMangaReadTime',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      defaultSearchTypeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'defaultSearchType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      defaultSearchTypeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'defaultSearchType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      defaultSearchTypeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'defaultSearchType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      defaultSearchTypeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'defaultSearchType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      defaultSearchTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'defaultSearchType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      defaultSearchTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'defaultSearchType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      defaultSearchTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'defaultSearchType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      defaultSearchTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'defaultSearchType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      defaultSearchTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'defaultSearchType',
        value: '',
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      defaultSearchTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'defaultSearchType',
        value: '',
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> filter18PlusEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'filter18Plus',
        value: value,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> idBetween(
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

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> nameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> nameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }
}

extension UserModelQueryObject
    on QueryBuilder<UserModel, UserModel, QFilterCondition> {}

extension UserModelQueryLinks
    on QueryBuilder<UserModel, UserModel, QFilterCondition> {}

extension UserModelQuerySortBy on QueryBuilder<UserModel, UserModel, QSortBy> {
  QueryBuilder<UserModel, UserModel, QAfterSortBy> sortByAvatarPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avatarPath', Sort.asc);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> sortByAvatarPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avatarPath', Sort.desc);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy>
      sortByDefaultAnimeWatchTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultAnimeWatchTime', Sort.asc);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy>
      sortByDefaultAnimeWatchTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultAnimeWatchTime', Sort.desc);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy>
      sortByDefaultContentRating() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultContentRating', Sort.asc);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy>
      sortByDefaultContentRatingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultContentRating', Sort.desc);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy>
      sortByDefaultMangaReadTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultMangaReadTime', Sort.asc);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy>
      sortByDefaultMangaReadTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultMangaReadTime', Sort.desc);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> sortByDefaultSearchType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultSearchType', Sort.asc);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy>
      sortByDefaultSearchTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultSearchType', Sort.desc);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> sortByFilter18Plus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'filter18Plus', Sort.asc);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> sortByFilter18PlusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'filter18Plus', Sort.desc);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }
}

extension UserModelQuerySortThenBy
    on QueryBuilder<UserModel, UserModel, QSortThenBy> {
  QueryBuilder<UserModel, UserModel, QAfterSortBy> thenByAvatarPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avatarPath', Sort.asc);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> thenByAvatarPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avatarPath', Sort.desc);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy>
      thenByDefaultAnimeWatchTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultAnimeWatchTime', Sort.asc);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy>
      thenByDefaultAnimeWatchTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultAnimeWatchTime', Sort.desc);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy>
      thenByDefaultContentRating() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultContentRating', Sort.asc);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy>
      thenByDefaultContentRatingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultContentRating', Sort.desc);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy>
      thenByDefaultMangaReadTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultMangaReadTime', Sort.asc);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy>
      thenByDefaultMangaReadTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultMangaReadTime', Sort.desc);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> thenByDefaultSearchType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultSearchType', Sort.asc);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy>
      thenByDefaultSearchTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultSearchType', Sort.desc);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> thenByFilter18Plus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'filter18Plus', Sort.asc);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> thenByFilter18PlusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'filter18Plus', Sort.desc);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }
}

extension UserModelQueryWhereDistinct
    on QueryBuilder<UserModel, UserModel, QDistinct> {
  QueryBuilder<UserModel, UserModel, QDistinct> distinctByAvatarPath(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'avatarPath', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UserModel, UserModel, QDistinct>
      distinctByDefaultAnimeWatchTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'defaultAnimeWatchTime');
    });
  }

  QueryBuilder<UserModel, UserModel, QDistinct> distinctByDefaultContentRating(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'defaultContentRating',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UserModel, UserModel, QDistinct>
      distinctByDefaultMangaReadTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'defaultMangaReadTime');
    });
  }

  QueryBuilder<UserModel, UserModel, QDistinct> distinctByDefaultSearchType(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'defaultSearchType',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UserModel, UserModel, QDistinct> distinctByFilter18Plus() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'filter18Plus');
    });
  }

  QueryBuilder<UserModel, UserModel, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }
}

extension UserModelQueryProperty
    on QueryBuilder<UserModel, UserModel, QQueryProperty> {
  QueryBuilder<UserModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<UserModel, String?, QQueryOperations> avatarPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'avatarPath');
    });
  }

  QueryBuilder<UserModel, int, QQueryOperations>
      defaultAnimeWatchTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'defaultAnimeWatchTime');
    });
  }

  QueryBuilder<UserModel, String, QQueryOperations>
      defaultContentRatingProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'defaultContentRating');
    });
  }

  QueryBuilder<UserModel, int, QQueryOperations>
      defaultMangaReadTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'defaultMangaReadTime');
    });
  }

  QueryBuilder<UserModel, String, QQueryOperations>
      defaultSearchTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'defaultSearchType');
    });
  }

  QueryBuilder<UserModel, bool, QQueryOperations> filter18PlusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'filter18Plus');
    });
  }

  QueryBuilder<UserModel, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }
}
