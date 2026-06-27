// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ou_metrics.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetOUMetricsCollection on Isar {
  IsarCollection<OUMetrics> get oUMetrics => this.collection();
}

const OUMetricsSchema = CollectionSchema(
  name: r'OUMetrics',
  id: -4721806705189275522,
  properties: {
    r'datasetName': PropertySchema(
      id: 0,
      name: r'datasetName',
      type: IsarType.string,
    ),
    r'estimatedAt': PropertySchema(
      id: 1,
      name: r'estimatedAt',
      type: IsarType.dateTime,
    ),
    r'halfLife': PropertySchema(
      id: 2,
      name: r'halfLife',
      type: IsarType.double,
    ),
    r'method': PropertySchema(
      id: 3,
      name: r'method',
      type: IsarType.byte,
      enumMap: _OUMetricsmethodEnumValueMap,
    ),
    r'mu': PropertySchema(
      id: 4,
      name: r'mu',
      type: IsarType.double,
    ),
    r'numObservations': PropertySchema(
      id: 5,
      name: r'numObservations',
      type: IsarType.long,
    ),
    r'sigma': PropertySchema(
      id: 6,
      name: r'sigma',
      type: IsarType.double,
    ),
    r'theta': PropertySchema(
      id: 7,
      name: r'theta',
      type: IsarType.double,
    )
  },
  estimateSize: _oUMetricsEstimateSize,
  serialize: _oUMetricsSerialize,
  deserialize: _oUMetricsDeserialize,
  deserializeProp: _oUMetricsDeserializeProp,
  idName: r'id',
  indexes: {
    r'datasetName': IndexSchema(
      id: -5211710991667016736,
      name: r'datasetName',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'datasetName',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {
    r'dataset': LinkSchema(
      id: -6528506907558094048,
      name: r'dataset',
      target: r'TimeSeriesData',
      single: true,
    )
  },
  embeddedSchemas: {},
  getId: _oUMetricsGetId,
  getLinks: _oUMetricsGetLinks,
  attach: _oUMetricsAttach,
  version: '3.3.2',
);

int _oUMetricsEstimateSize(
  OUMetrics object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.datasetName.length * 3;
  return bytesCount;
}

void _oUMetricsSerialize(
  OUMetrics object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.datasetName);
  writer.writeDateTime(offsets[1], object.estimatedAt);
  writer.writeDouble(offsets[2], object.halfLife);
  writer.writeByte(offsets[3], object.method.index);
  writer.writeDouble(offsets[4], object.mu);
  writer.writeLong(offsets[5], object.numObservations);
  writer.writeDouble(offsets[6], object.sigma);
  writer.writeDouble(offsets[7], object.theta);
}

OUMetrics _oUMetricsDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = OUMetrics();
  object.datasetName = reader.readString(offsets[0]);
  object.estimatedAt = reader.readDateTime(offsets[1]);
  object.halfLife = reader.readDouble(offsets[2]);
  object.id = id;
  object.method =
      _OUMetricsmethodValueEnumMap[reader.readByteOrNull(offsets[3])] ??
          EstimationMethod.ols;
  object.mu = reader.readDouble(offsets[4]);
  object.numObservations = reader.readLong(offsets[5]);
  object.sigma = reader.readDouble(offsets[6]);
  object.theta = reader.readDouble(offsets[7]);
  return object;
}

P _oUMetricsDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readDouble(offset)) as P;
    case 3:
      return (_OUMetricsmethodValueEnumMap[reader.readByteOrNull(offset)] ??
          EstimationMethod.ols) as P;
    case 4:
      return (reader.readDouble(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    case 6:
      return (reader.readDouble(offset)) as P;
    case 7:
      return (reader.readDouble(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _OUMetricsmethodEnumValueMap = {
  'ols': 0,
  'mle': 1,
};
const _OUMetricsmethodValueEnumMap = {
  0: EstimationMethod.ols,
  1: EstimationMethod.mle,
};

Id _oUMetricsGetId(OUMetrics object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _oUMetricsGetLinks(OUMetrics object) {
  return [object.dataset];
}

void _oUMetricsAttach(IsarCollection<dynamic> col, Id id, OUMetrics object) {
  object.id = id;
  object.dataset
      .attach(col, col.isar.collection<TimeSeriesData>(), r'dataset', id);
}

extension OUMetricsQueryWhereSort
    on QueryBuilder<OUMetrics, OUMetrics, QWhere> {
  QueryBuilder<OUMetrics, OUMetrics, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension OUMetricsQueryWhere
    on QueryBuilder<OUMetrics, OUMetrics, QWhereClause> {
  QueryBuilder<OUMetrics, OUMetrics, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<OUMetrics, OUMetrics, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterWhereClause> idBetween(
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

  QueryBuilder<OUMetrics, OUMetrics, QAfterWhereClause> datasetNameEqualTo(
      String datasetName) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'datasetName',
        value: [datasetName],
      ));
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterWhereClause> datasetNameNotEqualTo(
      String datasetName) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'datasetName',
              lower: [],
              upper: [datasetName],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'datasetName',
              lower: [datasetName],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'datasetName',
              lower: [datasetName],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'datasetName',
              lower: [],
              upper: [datasetName],
              includeUpper: false,
            ));
      }
    });
  }
}

extension OUMetricsQueryFilter
    on QueryBuilder<OUMetrics, OUMetrics, QFilterCondition> {
  QueryBuilder<OUMetrics, OUMetrics, QAfterFilterCondition> datasetNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'datasetName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterFilterCondition>
      datasetNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'datasetName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterFilterCondition> datasetNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'datasetName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterFilterCondition> datasetNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'datasetName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterFilterCondition>
      datasetNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'datasetName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterFilterCondition> datasetNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'datasetName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterFilterCondition> datasetNameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'datasetName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterFilterCondition> datasetNameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'datasetName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterFilterCondition>
      datasetNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'datasetName',
        value: '',
      ));
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterFilterCondition>
      datasetNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'datasetName',
        value: '',
      ));
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterFilterCondition> estimatedAtEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'estimatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterFilterCondition>
      estimatedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'estimatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterFilterCondition> estimatedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'estimatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterFilterCondition> estimatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'estimatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterFilterCondition> halfLifeEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'halfLife',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterFilterCondition> halfLifeGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'halfLife',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterFilterCondition> halfLifeLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'halfLife',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterFilterCondition> halfLifeBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'halfLife',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<OUMetrics, OUMetrics, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<OUMetrics, OUMetrics, QAfterFilterCondition> idBetween(
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

  QueryBuilder<OUMetrics, OUMetrics, QAfterFilterCondition> methodEqualTo(
      EstimationMethod value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'method',
        value: value,
      ));
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterFilterCondition> methodGreaterThan(
    EstimationMethod value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'method',
        value: value,
      ));
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterFilterCondition> methodLessThan(
    EstimationMethod value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'method',
        value: value,
      ));
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterFilterCondition> methodBetween(
    EstimationMethod lower,
    EstimationMethod upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'method',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterFilterCondition> muEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mu',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterFilterCondition> muGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'mu',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterFilterCondition> muLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'mu',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterFilterCondition> muBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'mu',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterFilterCondition>
      numObservationsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'numObservations',
        value: value,
      ));
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterFilterCondition>
      numObservationsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'numObservations',
        value: value,
      ));
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterFilterCondition>
      numObservationsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'numObservations',
        value: value,
      ));
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterFilterCondition>
      numObservationsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'numObservations',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterFilterCondition> sigmaEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sigma',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterFilterCondition> sigmaGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sigma',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterFilterCondition> sigmaLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sigma',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterFilterCondition> sigmaBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sigma',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterFilterCondition> thetaEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'theta',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterFilterCondition> thetaGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'theta',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterFilterCondition> thetaLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'theta',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterFilterCondition> thetaBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'theta',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }
}

extension OUMetricsQueryObject
    on QueryBuilder<OUMetrics, OUMetrics, QFilterCondition> {}

extension OUMetricsQueryLinks
    on QueryBuilder<OUMetrics, OUMetrics, QFilterCondition> {
  QueryBuilder<OUMetrics, OUMetrics, QAfterFilterCondition> dataset(
      FilterQuery<TimeSeriesData> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'dataset');
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterFilterCondition> datasetIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'dataset', 0, true, 0, true);
    });
  }
}

extension OUMetricsQuerySortBy on QueryBuilder<OUMetrics, OUMetrics, QSortBy> {
  QueryBuilder<OUMetrics, OUMetrics, QAfterSortBy> sortByDatasetName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'datasetName', Sort.asc);
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterSortBy> sortByDatasetNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'datasetName', Sort.desc);
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterSortBy> sortByEstimatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'estimatedAt', Sort.asc);
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterSortBy> sortByEstimatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'estimatedAt', Sort.desc);
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterSortBy> sortByHalfLife() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'halfLife', Sort.asc);
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterSortBy> sortByHalfLifeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'halfLife', Sort.desc);
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterSortBy> sortByMethod() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'method', Sort.asc);
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterSortBy> sortByMethodDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'method', Sort.desc);
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterSortBy> sortByMu() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mu', Sort.asc);
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterSortBy> sortByMuDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mu', Sort.desc);
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterSortBy> sortByNumObservations() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'numObservations', Sort.asc);
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterSortBy> sortByNumObservationsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'numObservations', Sort.desc);
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterSortBy> sortBySigma() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sigma', Sort.asc);
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterSortBy> sortBySigmaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sigma', Sort.desc);
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterSortBy> sortByTheta() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'theta', Sort.asc);
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterSortBy> sortByThetaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'theta', Sort.desc);
    });
  }
}

extension OUMetricsQuerySortThenBy
    on QueryBuilder<OUMetrics, OUMetrics, QSortThenBy> {
  QueryBuilder<OUMetrics, OUMetrics, QAfterSortBy> thenByDatasetName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'datasetName', Sort.asc);
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterSortBy> thenByDatasetNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'datasetName', Sort.desc);
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterSortBy> thenByEstimatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'estimatedAt', Sort.asc);
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterSortBy> thenByEstimatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'estimatedAt', Sort.desc);
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterSortBy> thenByHalfLife() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'halfLife', Sort.asc);
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterSortBy> thenByHalfLifeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'halfLife', Sort.desc);
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterSortBy> thenByMethod() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'method', Sort.asc);
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterSortBy> thenByMethodDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'method', Sort.desc);
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterSortBy> thenByMu() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mu', Sort.asc);
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterSortBy> thenByMuDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mu', Sort.desc);
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterSortBy> thenByNumObservations() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'numObservations', Sort.asc);
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterSortBy> thenByNumObservationsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'numObservations', Sort.desc);
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterSortBy> thenBySigma() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sigma', Sort.asc);
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterSortBy> thenBySigmaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sigma', Sort.desc);
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterSortBy> thenByTheta() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'theta', Sort.asc);
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QAfterSortBy> thenByThetaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'theta', Sort.desc);
    });
  }
}

extension OUMetricsQueryWhereDistinct
    on QueryBuilder<OUMetrics, OUMetrics, QDistinct> {
  QueryBuilder<OUMetrics, OUMetrics, QDistinct> distinctByDatasetName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'datasetName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QDistinct> distinctByEstimatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'estimatedAt');
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QDistinct> distinctByHalfLife() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'halfLife');
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QDistinct> distinctByMethod() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'method');
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QDistinct> distinctByMu() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mu');
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QDistinct> distinctByNumObservations() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'numObservations');
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QDistinct> distinctBySigma() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sigma');
    });
  }

  QueryBuilder<OUMetrics, OUMetrics, QDistinct> distinctByTheta() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'theta');
    });
  }
}

extension OUMetricsQueryProperty
    on QueryBuilder<OUMetrics, OUMetrics, QQueryProperty> {
  QueryBuilder<OUMetrics, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<OUMetrics, String, QQueryOperations> datasetNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'datasetName');
    });
  }

  QueryBuilder<OUMetrics, DateTime, QQueryOperations> estimatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'estimatedAt');
    });
  }

  QueryBuilder<OUMetrics, double, QQueryOperations> halfLifeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'halfLife');
    });
  }

  QueryBuilder<OUMetrics, EstimationMethod, QQueryOperations> methodProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'method');
    });
  }

  QueryBuilder<OUMetrics, double, QQueryOperations> muProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mu');
    });
  }

  QueryBuilder<OUMetrics, int, QQueryOperations> numObservationsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'numObservations');
    });
  }

  QueryBuilder<OUMetrics, double, QQueryOperations> sigmaProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sigma');
    });
  }

  QueryBuilder<OUMetrics, double, QQueryOperations> thetaProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'theta');
    });
  }
}
