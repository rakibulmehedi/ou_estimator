// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'time_series_data.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetTimeSeriesDataCollection on Isar {
  IsarCollection<TimeSeriesData> get timeSeriesDatas => this.collection();
}

const TimeSeriesDataSchema = CollectionSchema(
  name: r'TimeSeriesData',
  id: -8042136570965589262,
  properties: {
    r'createdAt': PropertySchema(
      id: 0,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'name': PropertySchema(
      id: 1,
      name: r'name',
      type: IsarType.string,
    ),
    r'samplingIntervalSeconds': PropertySchema(
      id: 2,
      name: r'samplingIntervalSeconds',
      type: IsarType.double,
    ),
    r'values': PropertySchema(
      id: 3,
      name: r'values',
      type: IsarType.doubleList,
    )
  },
  estimateSize: _timeSeriesDataEstimateSize,
  serialize: _timeSeriesDataSerialize,
  deserialize: _timeSeriesDataDeserialize,
  deserializeProp: _timeSeriesDataDeserializeProp,
  idName: r'id',
  indexes: {
    r'name': IndexSchema(
      id: 879695947855722453,
      name: r'name',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'name',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {
    r'metrics': LinkSchema(
      id: 6644800533550338940,
      name: r'metrics',
      target: r'OUMetrics',
      single: false,
      linkName: r'dataset',
    )
  },
  embeddedSchemas: {},
  getId: _timeSeriesDataGetId,
  getLinks: _timeSeriesDataGetLinks,
  attach: _timeSeriesDataAttach,
  version: '3.3.2',
);

int _timeSeriesDataEstimateSize(
  TimeSeriesData object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.name.length * 3;
  bytesCount += 3 + object.values.length * 8;
  return bytesCount;
}

void _timeSeriesDataSerialize(
  TimeSeriesData object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.createdAt);
  writer.writeString(offsets[1], object.name);
  writer.writeDouble(offsets[2], object.samplingIntervalSeconds);
  writer.writeDoubleList(offsets[3], object.values);
}

TimeSeriesData _timeSeriesDataDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = TimeSeriesData();
  object.createdAt = reader.readDateTime(offsets[0]);
  object.id = id;
  object.name = reader.readString(offsets[1]);
  object.samplingIntervalSeconds = reader.readDouble(offsets[2]);
  object.values = reader.readDoubleList(offsets[3]) ?? [];
  return object;
}

P _timeSeriesDataDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readDouble(offset)) as P;
    case 3:
      return (reader.readDoubleList(offset) ?? []) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _timeSeriesDataGetId(TimeSeriesData object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _timeSeriesDataGetLinks(TimeSeriesData object) {
  return [object.metrics];
}

void _timeSeriesDataAttach(
    IsarCollection<dynamic> col, Id id, TimeSeriesData object) {
  object.id = id;
  object.metrics.attach(col, col.isar.collection<OUMetrics>(), r'metrics', id);
}

extension TimeSeriesDataByIndex on IsarCollection<TimeSeriesData> {
  Future<TimeSeriesData?> getByName(String name) {
    return getByIndex(r'name', [name]);
  }

  TimeSeriesData? getByNameSync(String name) {
    return getByIndexSync(r'name', [name]);
  }

  Future<bool> deleteByName(String name) {
    return deleteByIndex(r'name', [name]);
  }

  bool deleteByNameSync(String name) {
    return deleteByIndexSync(r'name', [name]);
  }

  Future<List<TimeSeriesData?>> getAllByName(List<String> nameValues) {
    final values = nameValues.map((e) => [e]).toList();
    return getAllByIndex(r'name', values);
  }

  List<TimeSeriesData?> getAllByNameSync(List<String> nameValues) {
    final values = nameValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'name', values);
  }

  Future<int> deleteAllByName(List<String> nameValues) {
    final values = nameValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'name', values);
  }

  int deleteAllByNameSync(List<String> nameValues) {
    final values = nameValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'name', values);
  }

  Future<Id> putByName(TimeSeriesData object) {
    return putByIndex(r'name', object);
  }

  Id putByNameSync(TimeSeriesData object, {bool saveLinks = true}) {
    return putByIndexSync(r'name', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByName(List<TimeSeriesData> objects) {
    return putAllByIndex(r'name', objects);
  }

  List<Id> putAllByNameSync(List<TimeSeriesData> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'name', objects, saveLinks: saveLinks);
  }
}

extension TimeSeriesDataQueryWhereSort
    on QueryBuilder<TimeSeriesData, TimeSeriesData, QWhere> {
  QueryBuilder<TimeSeriesData, TimeSeriesData, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension TimeSeriesDataQueryWhere
    on QueryBuilder<TimeSeriesData, TimeSeriesData, QWhereClause> {
  QueryBuilder<TimeSeriesData, TimeSeriesData, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<TimeSeriesData, TimeSeriesData, QAfterWhereClause> idNotEqualTo(
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

  QueryBuilder<TimeSeriesData, TimeSeriesData, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<TimeSeriesData, TimeSeriesData, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<TimeSeriesData, TimeSeriesData, QAfterWhereClause> idBetween(
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

  QueryBuilder<TimeSeriesData, TimeSeriesData, QAfterWhereClause> nameEqualTo(
      String name) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'name',
        value: [name],
      ));
    });
  }

  QueryBuilder<TimeSeriesData, TimeSeriesData, QAfterWhereClause>
      nameNotEqualTo(String name) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'name',
              lower: [],
              upper: [name],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'name',
              lower: [name],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'name',
              lower: [name],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'name',
              lower: [],
              upper: [name],
              includeUpper: false,
            ));
      }
    });
  }
}

extension TimeSeriesDataQueryFilter
    on QueryBuilder<TimeSeriesData, TimeSeriesData, QFilterCondition> {
  QueryBuilder<TimeSeriesData, TimeSeriesData, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<TimeSeriesData, TimeSeriesData, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<TimeSeriesData, TimeSeriesData, QAfterFilterCondition>
      createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<TimeSeriesData, TimeSeriesData, QAfterFilterCondition>
      createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TimeSeriesData, TimeSeriesData, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<TimeSeriesData, TimeSeriesData, QAfterFilterCondition>
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

  QueryBuilder<TimeSeriesData, TimeSeriesData, QAfterFilterCondition>
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

  QueryBuilder<TimeSeriesData, TimeSeriesData, QAfterFilterCondition> idBetween(
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

  QueryBuilder<TimeSeriesData, TimeSeriesData, QAfterFilterCondition>
      nameEqualTo(
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

  QueryBuilder<TimeSeriesData, TimeSeriesData, QAfterFilterCondition>
      nameGreaterThan(
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

  QueryBuilder<TimeSeriesData, TimeSeriesData, QAfterFilterCondition>
      nameLessThan(
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

  QueryBuilder<TimeSeriesData, TimeSeriesData, QAfterFilterCondition>
      nameBetween(
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

  QueryBuilder<TimeSeriesData, TimeSeriesData, QAfterFilterCondition>
      nameStartsWith(
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

  QueryBuilder<TimeSeriesData, TimeSeriesData, QAfterFilterCondition>
      nameEndsWith(
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

  QueryBuilder<TimeSeriesData, TimeSeriesData, QAfterFilterCondition>
      nameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeSeriesData, TimeSeriesData, QAfterFilterCondition>
      nameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeSeriesData, TimeSeriesData, QAfterFilterCondition>
      nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<TimeSeriesData, TimeSeriesData, QAfterFilterCondition>
      nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<TimeSeriesData, TimeSeriesData, QAfterFilterCondition>
      samplingIntervalSecondsEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'samplingIntervalSeconds',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<TimeSeriesData, TimeSeriesData, QAfterFilterCondition>
      samplingIntervalSecondsGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'samplingIntervalSeconds',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<TimeSeriesData, TimeSeriesData, QAfterFilterCondition>
      samplingIntervalSecondsLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'samplingIntervalSeconds',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<TimeSeriesData, TimeSeriesData, QAfterFilterCondition>
      samplingIntervalSecondsBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'samplingIntervalSeconds',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<TimeSeriesData, TimeSeriesData, QAfterFilterCondition>
      valuesElementEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'values',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<TimeSeriesData, TimeSeriesData, QAfterFilterCondition>
      valuesElementGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'values',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<TimeSeriesData, TimeSeriesData, QAfterFilterCondition>
      valuesElementLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'values',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<TimeSeriesData, TimeSeriesData, QAfterFilterCondition>
      valuesElementBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'values',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<TimeSeriesData, TimeSeriesData, QAfterFilterCondition>
      valuesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'values',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<TimeSeriesData, TimeSeriesData, QAfterFilterCondition>
      valuesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'values',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<TimeSeriesData, TimeSeriesData, QAfterFilterCondition>
      valuesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'values',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<TimeSeriesData, TimeSeriesData, QAfterFilterCondition>
      valuesLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'values',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<TimeSeriesData, TimeSeriesData, QAfterFilterCondition>
      valuesLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'values',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<TimeSeriesData, TimeSeriesData, QAfterFilterCondition>
      valuesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'values',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }
}

extension TimeSeriesDataQueryObject
    on QueryBuilder<TimeSeriesData, TimeSeriesData, QFilterCondition> {}

extension TimeSeriesDataQueryLinks
    on QueryBuilder<TimeSeriesData, TimeSeriesData, QFilterCondition> {
  QueryBuilder<TimeSeriesData, TimeSeriesData, QAfterFilterCondition> metrics(
      FilterQuery<OUMetrics> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'metrics');
    });
  }

  QueryBuilder<TimeSeriesData, TimeSeriesData, QAfterFilterCondition>
      metricsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'metrics', length, true, length, true);
    });
  }

  QueryBuilder<TimeSeriesData, TimeSeriesData, QAfterFilterCondition>
      metricsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'metrics', 0, true, 0, true);
    });
  }

  QueryBuilder<TimeSeriesData, TimeSeriesData, QAfterFilterCondition>
      metricsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'metrics', 0, false, 999999, true);
    });
  }

  QueryBuilder<TimeSeriesData, TimeSeriesData, QAfterFilterCondition>
      metricsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'metrics', 0, true, length, include);
    });
  }

  QueryBuilder<TimeSeriesData, TimeSeriesData, QAfterFilterCondition>
      metricsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'metrics', length, include, 999999, true);
    });
  }

  QueryBuilder<TimeSeriesData, TimeSeriesData, QAfterFilterCondition>
      metricsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(
          r'metrics', lower, includeLower, upper, includeUpper);
    });
  }
}

extension TimeSeriesDataQuerySortBy
    on QueryBuilder<TimeSeriesData, TimeSeriesData, QSortBy> {
  QueryBuilder<TimeSeriesData, TimeSeriesData, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<TimeSeriesData, TimeSeriesData, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<TimeSeriesData, TimeSeriesData, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<TimeSeriesData, TimeSeriesData, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<TimeSeriesData, TimeSeriesData, QAfterSortBy>
      sortBySamplingIntervalSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'samplingIntervalSeconds', Sort.asc);
    });
  }

  QueryBuilder<TimeSeriesData, TimeSeriesData, QAfterSortBy>
      sortBySamplingIntervalSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'samplingIntervalSeconds', Sort.desc);
    });
  }
}

extension TimeSeriesDataQuerySortThenBy
    on QueryBuilder<TimeSeriesData, TimeSeriesData, QSortThenBy> {
  QueryBuilder<TimeSeriesData, TimeSeriesData, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<TimeSeriesData, TimeSeriesData, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<TimeSeriesData, TimeSeriesData, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<TimeSeriesData, TimeSeriesData, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<TimeSeriesData, TimeSeriesData, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<TimeSeriesData, TimeSeriesData, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<TimeSeriesData, TimeSeriesData, QAfterSortBy>
      thenBySamplingIntervalSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'samplingIntervalSeconds', Sort.asc);
    });
  }

  QueryBuilder<TimeSeriesData, TimeSeriesData, QAfterSortBy>
      thenBySamplingIntervalSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'samplingIntervalSeconds', Sort.desc);
    });
  }
}

extension TimeSeriesDataQueryWhereDistinct
    on QueryBuilder<TimeSeriesData, TimeSeriesData, QDistinct> {
  QueryBuilder<TimeSeriesData, TimeSeriesData, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<TimeSeriesData, TimeSeriesData, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TimeSeriesData, TimeSeriesData, QDistinct>
      distinctBySamplingIntervalSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'samplingIntervalSeconds');
    });
  }

  QueryBuilder<TimeSeriesData, TimeSeriesData, QDistinct> distinctByValues() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'values');
    });
  }
}

extension TimeSeriesDataQueryProperty
    on QueryBuilder<TimeSeriesData, TimeSeriesData, QQueryProperty> {
  QueryBuilder<TimeSeriesData, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<TimeSeriesData, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<TimeSeriesData, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<TimeSeriesData, double, QQueryOperations>
      samplingIntervalSecondsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'samplingIntervalSeconds');
    });
  }

  QueryBuilder<TimeSeriesData, List<double>, QQueryOperations>
      valuesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'values');
    });
  }
}
