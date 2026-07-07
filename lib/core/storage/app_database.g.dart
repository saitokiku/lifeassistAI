// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $GrowthMetricsTable extends GrowthMetrics
    with TableInfo<$GrowthMetricsTable, GrowthMetric> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GrowthMetricsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
      'unit', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _currentValueMeta =
      const VerificationMeta('currentValue');
  @override
  late final GeneratedColumn<double> currentValue = GeneratedColumn<double>(
      'current_value', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _weeklyTargetMeta =
      const VerificationMeta('weeklyTarget');
  @override
  late final GeneratedColumn<double> weeklyTarget = GeneratedColumn<double>(
      'weekly_target', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        unit,
        currentValue,
        weeklyTarget,
        isActive,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'growth_metrics';
  @override
  VerificationContext validateIntegrity(Insertable<GrowthMetric> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
          _unitMeta, unit.isAcceptableOrUnknown(data['unit']!, _unitMeta));
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('current_value')) {
      context.handle(
          _currentValueMeta,
          currentValue.isAcceptableOrUnknown(
              data['current_value']!, _currentValueMeta));
    }
    if (data.containsKey('weekly_target')) {
      context.handle(
          _weeklyTargetMeta,
          weeklyTarget.isAcceptableOrUnknown(
              data['weekly_target']!, _weeklyTargetMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GrowthMetric map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GrowthMetric(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      unit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit'])!,
      currentValue: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}current_value'])!,
      weeklyTarget: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}weekly_target'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $GrowthMetricsTable createAlias(String alias) {
    return $GrowthMetricsTable(attachedDatabase, alias);
  }
}

class GrowthMetric extends DataClass implements Insertable<GrowthMetric> {
  final String id;
  final String name;
  final String unit;
  final double currentValue;
  final double weeklyTarget;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  const GrowthMetric(
      {required this.id,
      required this.name,
      required this.unit,
      required this.currentValue,
      required this.weeklyTarget,
      required this.isActive,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['unit'] = Variable<String>(unit);
    map['current_value'] = Variable<double>(currentValue);
    map['weekly_target'] = Variable<double>(weeklyTarget);
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  GrowthMetricsCompanion toCompanion(bool nullToAbsent) {
    return GrowthMetricsCompanion(
      id: Value(id),
      name: Value(name),
      unit: Value(unit),
      currentValue: Value(currentValue),
      weeklyTarget: Value(weeklyTarget),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory GrowthMetric.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GrowthMetric(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      unit: serializer.fromJson<String>(json['unit']),
      currentValue: serializer.fromJson<double>(json['currentValue']),
      weeklyTarget: serializer.fromJson<double>(json['weeklyTarget']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'unit': serializer.toJson<String>(unit),
      'currentValue': serializer.toJson<double>(currentValue),
      'weeklyTarget': serializer.toJson<double>(weeklyTarget),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  GrowthMetric copyWith(
          {String? id,
          String? name,
          String? unit,
          double? currentValue,
          double? weeklyTarget,
          bool? isActive,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      GrowthMetric(
        id: id ?? this.id,
        name: name ?? this.name,
        unit: unit ?? this.unit,
        currentValue: currentValue ?? this.currentValue,
        weeklyTarget: weeklyTarget ?? this.weeklyTarget,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  GrowthMetric copyWithCompanion(GrowthMetricsCompanion data) {
    return GrowthMetric(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      unit: data.unit.present ? data.unit.value : this.unit,
      currentValue: data.currentValue.present
          ? data.currentValue.value
          : this.currentValue,
      weeklyTarget: data.weeklyTarget.present
          ? data.weeklyTarget.value
          : this.weeklyTarget,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GrowthMetric(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('unit: $unit, ')
          ..write('currentValue: $currentValue, ')
          ..write('weeklyTarget: $weeklyTarget, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, unit, currentValue, weeklyTarget,
      isActive, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GrowthMetric &&
          other.id == this.id &&
          other.name == this.name &&
          other.unit == this.unit &&
          other.currentValue == this.currentValue &&
          other.weeklyTarget == this.weeklyTarget &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class GrowthMetricsCompanion extends UpdateCompanion<GrowthMetric> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> unit;
  final Value<double> currentValue;
  final Value<double> weeklyTarget;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const GrowthMetricsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.unit = const Value.absent(),
    this.currentValue = const Value.absent(),
    this.weeklyTarget = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GrowthMetricsCompanion.insert({
    required String id,
    required String name,
    required String unit,
    this.currentValue = const Value.absent(),
    this.weeklyTarget = const Value.absent(),
    this.isActive = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        unit = Value(unit),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<GrowthMetric> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? unit,
    Expression<double>? currentValue,
    Expression<double>? weeklyTarget,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (unit != null) 'unit': unit,
      if (currentValue != null) 'current_value': currentValue,
      if (weeklyTarget != null) 'weekly_target': weeklyTarget,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GrowthMetricsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? unit,
      Value<double>? currentValue,
      Value<double>? weeklyTarget,
      Value<bool>? isActive,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return GrowthMetricsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      currentValue: currentValue ?? this.currentValue,
      weeklyTarget: weeklyTarget ?? this.weeklyTarget,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (currentValue.present) {
      map['current_value'] = Variable<double>(currentValue.value);
    }
    if (weeklyTarget.present) {
      map['weekly_target'] = Variable<double>(weeklyTarget.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GrowthMetricsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('unit: $unit, ')
          ..write('currentValue: $currentValue, ')
          ..write('weeklyTarget: $weeklyTarget, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GrowthMetricEntriesTable extends GrowthMetricEntries
    with TableInfo<$GrowthMetricEntriesTable, GrowthMetricEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GrowthMetricEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _metricIdMeta =
      const VerificationMeta('metricId');
  @override
  late final GeneratedColumn<String> metricId = GeneratedColumn<String>(
      'metric_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
      'date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<double> value = GeneratedColumn<double>(
      'value', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [id, metricId, date, value, note];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'growth_metric_entries';
  @override
  VerificationContext validateIntegrity(Insertable<GrowthMetricEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('metric_id')) {
      context.handle(_metricIdMeta,
          metricId.isAcceptableOrUnknown(data['metric_id']!, _metricIdMeta));
    } else if (isInserting) {
      context.missing(_metricIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GrowthMetricEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GrowthMetricEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      metricId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}metric_id'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}date'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}value'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
    );
  }

  @override
  $GrowthMetricEntriesTable createAlias(String alias) {
    return $GrowthMetricEntriesTable(attachedDatabase, alias);
  }
}

class GrowthMetricEntry extends DataClass
    implements Insertable<GrowthMetricEntry> {
  final String id;
  final String metricId;
  final String date;
  final double value;
  final String? note;
  const GrowthMetricEntry(
      {required this.id,
      required this.metricId,
      required this.date,
      required this.value,
      this.note});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['metric_id'] = Variable<String>(metricId);
    map['date'] = Variable<String>(date);
    map['value'] = Variable<double>(value);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  GrowthMetricEntriesCompanion toCompanion(bool nullToAbsent) {
    return GrowthMetricEntriesCompanion(
      id: Value(id),
      metricId: Value(metricId),
      date: Value(date),
      value: Value(value),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory GrowthMetricEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GrowthMetricEntry(
      id: serializer.fromJson<String>(json['id']),
      metricId: serializer.fromJson<String>(json['metricId']),
      date: serializer.fromJson<String>(json['date']),
      value: serializer.fromJson<double>(json['value']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'metricId': serializer.toJson<String>(metricId),
      'date': serializer.toJson<String>(date),
      'value': serializer.toJson<double>(value),
      'note': serializer.toJson<String?>(note),
    };
  }

  GrowthMetricEntry copyWith(
          {String? id,
          String? metricId,
          String? date,
          double? value,
          Value<String?> note = const Value.absent()}) =>
      GrowthMetricEntry(
        id: id ?? this.id,
        metricId: metricId ?? this.metricId,
        date: date ?? this.date,
        value: value ?? this.value,
        note: note.present ? note.value : this.note,
      );
  GrowthMetricEntry copyWithCompanion(GrowthMetricEntriesCompanion data) {
    return GrowthMetricEntry(
      id: data.id.present ? data.id.value : this.id,
      metricId: data.metricId.present ? data.metricId.value : this.metricId,
      date: data.date.present ? data.date.value : this.date,
      value: data.value.present ? data.value.value : this.value,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GrowthMetricEntry(')
          ..write('id: $id, ')
          ..write('metricId: $metricId, ')
          ..write('date: $date, ')
          ..write('value: $value, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, metricId, date, value, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GrowthMetricEntry &&
          other.id == this.id &&
          other.metricId == this.metricId &&
          other.date == this.date &&
          other.value == this.value &&
          other.note == this.note);
}

class GrowthMetricEntriesCompanion extends UpdateCompanion<GrowthMetricEntry> {
  final Value<String> id;
  final Value<String> metricId;
  final Value<String> date;
  final Value<double> value;
  final Value<String?> note;
  final Value<int> rowid;
  const GrowthMetricEntriesCompanion({
    this.id = const Value.absent(),
    this.metricId = const Value.absent(),
    this.date = const Value.absent(),
    this.value = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GrowthMetricEntriesCompanion.insert({
    required String id,
    required String metricId,
    required String date,
    required double value,
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        metricId = Value(metricId),
        date = Value(date),
        value = Value(value);
  static Insertable<GrowthMetricEntry> custom({
    Expression<String>? id,
    Expression<String>? metricId,
    Expression<String>? date,
    Expression<double>? value,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (metricId != null) 'metric_id': metricId,
      if (date != null) 'date': date,
      if (value != null) 'value': value,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GrowthMetricEntriesCompanion copyWith(
      {Value<String>? id,
      Value<String>? metricId,
      Value<String>? date,
      Value<double>? value,
      Value<String?>? note,
      Value<int>? rowid}) {
    return GrowthMetricEntriesCompanion(
      id: id ?? this.id,
      metricId: metricId ?? this.metricId,
      date: date ?? this.date,
      value: value ?? this.value,
      note: note ?? this.note,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (metricId.present) {
      map['metric_id'] = Variable<String>(metricId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (value.present) {
      map['value'] = Variable<double>(value.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GrowthMetricEntriesCompanion(')
          ..write('id: $id, ')
          ..write('metricId: $metricId, ')
          ..write('date: $date, ')
          ..write('value: $value, ')
          ..write('note: $note, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DailyExperimentsTable extends DailyExperiments
    with TableInfo<$DailyExperimentsTable, DailyExperiment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyExperimentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
      'date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _hypothesisMeta =
      const VerificationMeta('hypothesis');
  @override
  late final GeneratedColumn<String> hypothesis = GeneratedColumn<String>(
      'hypothesis', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _actionTakenMeta =
      const VerificationMeta('actionTaken');
  @override
  late final GeneratedColumn<String> actionTaken = GeneratedColumn<String>(
      'action_taken', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _resultMeta = const VerificationMeta('result');
  @override
  late final GeneratedColumn<String> result = GeneratedColumn<String>(
      'result', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _verdictMeta =
      const VerificationMeta('verdict');
  @override
  late final GeneratedColumn<String> verdict = GeneratedColumn<String>(
      'verdict', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        date,
        hypothesis,
        actionTaken,
        result,
        verdict,
        notes,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_experiments';
  @override
  VerificationContext validateIntegrity(Insertable<DailyExperiment> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('hypothesis')) {
      context.handle(
          _hypothesisMeta,
          hypothesis.isAcceptableOrUnknown(
              data['hypothesis']!, _hypothesisMeta));
    } else if (isInserting) {
      context.missing(_hypothesisMeta);
    }
    if (data.containsKey('action_taken')) {
      context.handle(
          _actionTakenMeta,
          actionTaken.isAcceptableOrUnknown(
              data['action_taken']!, _actionTakenMeta));
    } else if (isInserting) {
      context.missing(_actionTakenMeta);
    }
    if (data.containsKey('result')) {
      context.handle(_resultMeta,
          result.isAcceptableOrUnknown(data['result']!, _resultMeta));
    } else if (isInserting) {
      context.missing(_resultMeta);
    }
    if (data.containsKey('verdict')) {
      context.handle(_verdictMeta,
          verdict.isAcceptableOrUnknown(data['verdict']!, _verdictMeta));
    } else if (isInserting) {
      context.missing(_verdictMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DailyExperiment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyExperiment(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}date'])!,
      hypothesis: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}hypothesis'])!,
      actionTaken: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}action_taken'])!,
      result: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}result'])!,
      verdict: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}verdict'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $DailyExperimentsTable createAlias(String alias) {
    return $DailyExperimentsTable(attachedDatabase, alias);
  }
}

class DailyExperiment extends DataClass implements Insertable<DailyExperiment> {
  final String id;
  final String date;
  final String hypothesis;
  final String actionTaken;
  final String result;
  final String verdict;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  const DailyExperiment(
      {required this.id,
      required this.date,
      required this.hypothesis,
      required this.actionTaken,
      required this.result,
      required this.verdict,
      this.notes,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['date'] = Variable<String>(date);
    map['hypothesis'] = Variable<String>(hypothesis);
    map['action_taken'] = Variable<String>(actionTaken);
    map['result'] = Variable<String>(result);
    map['verdict'] = Variable<String>(verdict);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DailyExperimentsCompanion toCompanion(bool nullToAbsent) {
    return DailyExperimentsCompanion(
      id: Value(id),
      date: Value(date),
      hypothesis: Value(hypothesis),
      actionTaken: Value(actionTaken),
      result: Value(result),
      verdict: Value(verdict),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory DailyExperiment.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyExperiment(
      id: serializer.fromJson<String>(json['id']),
      date: serializer.fromJson<String>(json['date']),
      hypothesis: serializer.fromJson<String>(json['hypothesis']),
      actionTaken: serializer.fromJson<String>(json['actionTaken']),
      result: serializer.fromJson<String>(json['result']),
      verdict: serializer.fromJson<String>(json['verdict']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'date': serializer.toJson<String>(date),
      'hypothesis': serializer.toJson<String>(hypothesis),
      'actionTaken': serializer.toJson<String>(actionTaken),
      'result': serializer.toJson<String>(result),
      'verdict': serializer.toJson<String>(verdict),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DailyExperiment copyWith(
          {String? id,
          String? date,
          String? hypothesis,
          String? actionTaken,
          String? result,
          String? verdict,
          Value<String?> notes = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      DailyExperiment(
        id: id ?? this.id,
        date: date ?? this.date,
        hypothesis: hypothesis ?? this.hypothesis,
        actionTaken: actionTaken ?? this.actionTaken,
        result: result ?? this.result,
        verdict: verdict ?? this.verdict,
        notes: notes.present ? notes.value : this.notes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  DailyExperiment copyWithCompanion(DailyExperimentsCompanion data) {
    return DailyExperiment(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      hypothesis:
          data.hypothesis.present ? data.hypothesis.value : this.hypothesis,
      actionTaken:
          data.actionTaken.present ? data.actionTaken.value : this.actionTaken,
      result: data.result.present ? data.result.value : this.result,
      verdict: data.verdict.present ? data.verdict.value : this.verdict,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyExperiment(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('hypothesis: $hypothesis, ')
          ..write('actionTaken: $actionTaken, ')
          ..write('result: $result, ')
          ..write('verdict: $verdict, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, date, hypothesis, actionTaken, result,
      verdict, notes, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyExperiment &&
          other.id == this.id &&
          other.date == this.date &&
          other.hypothesis == this.hypothesis &&
          other.actionTaken == this.actionTaken &&
          other.result == this.result &&
          other.verdict == this.verdict &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DailyExperimentsCompanion extends UpdateCompanion<DailyExperiment> {
  final Value<String> id;
  final Value<String> date;
  final Value<String> hypothesis;
  final Value<String> actionTaken;
  final Value<String> result;
  final Value<String> verdict;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const DailyExperimentsCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.hypothesis = const Value.absent(),
    this.actionTaken = const Value.absent(),
    this.result = const Value.absent(),
    this.verdict = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailyExperimentsCompanion.insert({
    required String id,
    required String date,
    required String hypothesis,
    required String actionTaken,
    required String result,
    required String verdict,
    this.notes = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        date = Value(date),
        hypothesis = Value(hypothesis),
        actionTaken = Value(actionTaken),
        result = Value(result),
        verdict = Value(verdict),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<DailyExperiment> custom({
    Expression<String>? id,
    Expression<String>? date,
    Expression<String>? hypothesis,
    Expression<String>? actionTaken,
    Expression<String>? result,
    Expression<String>? verdict,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (hypothesis != null) 'hypothesis': hypothesis,
      if (actionTaken != null) 'action_taken': actionTaken,
      if (result != null) 'result': result,
      if (verdict != null) 'verdict': verdict,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailyExperimentsCompanion copyWith(
      {Value<String>? id,
      Value<String>? date,
      Value<String>? hypothesis,
      Value<String>? actionTaken,
      Value<String>? result,
      Value<String>? verdict,
      Value<String?>? notes,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return DailyExperimentsCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      hypothesis: hypothesis ?? this.hypothesis,
      actionTaken: actionTaken ?? this.actionTaken,
      result: result ?? this.result,
      verdict: verdict ?? this.verdict,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (hypothesis.present) {
      map['hypothesis'] = Variable<String>(hypothesis.value);
    }
    if (actionTaken.present) {
      map['action_taken'] = Variable<String>(actionTaken.value);
    }
    if (result.present) {
      map['result'] = Variable<String>(result.value);
    }
    if (verdict.present) {
      map['verdict'] = Variable<String>(verdict.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyExperimentsCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('hypothesis: $hypothesis, ')
          ..write('actionTaken: $actionTaken, ')
          ..write('result: $result, ')
          ..write('verdict: $verdict, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BudgetCategoriesTable extends BudgetCategories
    with TableInfo<$BudgetCategoriesTable, BudgetCategory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BudgetCategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _monthlyTargetMeta =
      const VerificationMeta('monthlyTarget');
  @override
  late final GeneratedColumn<double> monthlyTarget = GeneratedColumn<double>(
      'monthly_target', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _flagTypeMeta =
      const VerificationMeta('flagType');
  @override
  late final GeneratedColumn<String> flagType = GeneratedColumn<String>(
      'flag_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('warnOverTarget'));
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, monthlyTarget, flagType, sortOrder, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'budget_categories';
  @override
  VerificationContext validateIntegrity(Insertable<BudgetCategory> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('monthly_target')) {
      context.handle(
          _monthlyTargetMeta,
          monthlyTarget.isAcceptableOrUnknown(
              data['monthly_target']!, _monthlyTargetMeta));
    }
    if (data.containsKey('flag_type')) {
      context.handle(_flagTypeMeta,
          flagType.isAcceptableOrUnknown(data['flag_type']!, _flagTypeMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BudgetCategory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BudgetCategory(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      monthlyTarget: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}monthly_target'])!,
      flagType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}flag_type'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $BudgetCategoriesTable createAlias(String alias) {
    return $BudgetCategoriesTable(attachedDatabase, alias);
  }
}

class BudgetCategory extends DataClass implements Insertable<BudgetCategory> {
  final String id;
  final String name;
  final double monthlyTarget;
  final String flagType;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  const BudgetCategory(
      {required this.id,
      required this.name,
      required this.monthlyTarget,
      required this.flagType,
      required this.sortOrder,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['monthly_target'] = Variable<double>(monthlyTarget);
    map['flag_type'] = Variable<String>(flagType);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BudgetCategoriesCompanion toCompanion(bool nullToAbsent) {
    return BudgetCategoriesCompanion(
      id: Value(id),
      name: Value(name),
      monthlyTarget: Value(monthlyTarget),
      flagType: Value(flagType),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory BudgetCategory.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BudgetCategory(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      monthlyTarget: serializer.fromJson<double>(json['monthlyTarget']),
      flagType: serializer.fromJson<String>(json['flagType']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'monthlyTarget': serializer.toJson<double>(monthlyTarget),
      'flagType': serializer.toJson<String>(flagType),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  BudgetCategory copyWith(
          {String? id,
          String? name,
          double? monthlyTarget,
          String? flagType,
          int? sortOrder,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      BudgetCategory(
        id: id ?? this.id,
        name: name ?? this.name,
        monthlyTarget: monthlyTarget ?? this.monthlyTarget,
        flagType: flagType ?? this.flagType,
        sortOrder: sortOrder ?? this.sortOrder,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  BudgetCategory copyWithCompanion(BudgetCategoriesCompanion data) {
    return BudgetCategory(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      monthlyTarget: data.monthlyTarget.present
          ? data.monthlyTarget.value
          : this.monthlyTarget,
      flagType: data.flagType.present ? data.flagType.value : this.flagType,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BudgetCategory(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('monthlyTarget: $monthlyTarget, ')
          ..write('flagType: $flagType, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, name, monthlyTarget, flagType, sortOrder, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BudgetCategory &&
          other.id == this.id &&
          other.name == this.name &&
          other.monthlyTarget == this.monthlyTarget &&
          other.flagType == this.flagType &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class BudgetCategoriesCompanion extends UpdateCompanion<BudgetCategory> {
  final Value<String> id;
  final Value<String> name;
  final Value<double> monthlyTarget;
  final Value<String> flagType;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const BudgetCategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.monthlyTarget = const Value.absent(),
    this.flagType = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BudgetCategoriesCompanion.insert({
    required String id,
    required String name,
    this.monthlyTarget = const Value.absent(),
    this.flagType = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<BudgetCategory> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<double>? monthlyTarget,
    Expression<String>? flagType,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (monthlyTarget != null) 'monthly_target': monthlyTarget,
      if (flagType != null) 'flag_type': flagType,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BudgetCategoriesCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<double>? monthlyTarget,
      Value<String>? flagType,
      Value<int>? sortOrder,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return BudgetCategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      monthlyTarget: monthlyTarget ?? this.monthlyTarget,
      flagType: flagType ?? this.flagType,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (monthlyTarget.present) {
      map['monthly_target'] = Variable<double>(monthlyTarget.value);
    }
    if (flagType.present) {
      map['flag_type'] = Variable<String>(flagType.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BudgetCategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('monthlyTarget: $monthlyTarget, ')
          ..write('flagType: $flagType, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransactionEntriesTable extends TransactionEntries
    with TableInfo<$TransactionEntriesTable, TransactionEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
      'category_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
      'date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _isIntentionalMeta =
      const VerificationMeta('isIntentional');
  @override
  late final GeneratedColumn<bool> isIntentional = GeneratedColumn<bool>(
      'is_intentional', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_intentional" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, categoryId, date, amount, description, isIntentional, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transaction_entries';
  @override
  VerificationContext validateIntegrity(Insertable<TransactionEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('is_intentional')) {
      context.handle(
          _isIntentionalMeta,
          isIntentional.isAcceptableOrUnknown(
              data['is_intentional']!, _isIntentionalMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransactionEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_id']),
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}date'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      isIntentional: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_intentional'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $TransactionEntriesTable createAlias(String alias) {
    return $TransactionEntriesTable(attachedDatabase, alias);
  }
}

class TransactionEntry extends DataClass
    implements Insertable<TransactionEntry> {
  final String id;
  final String? categoryId;
  final String date;
  final double amount;
  final String description;
  final bool isIntentional;
  final DateTime createdAt;
  const TransactionEntry(
      {required this.id,
      this.categoryId,
      required this.date,
      required this.amount,
      required this.description,
      required this.isIntentional,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    map['date'] = Variable<String>(date);
    map['amount'] = Variable<double>(amount);
    map['description'] = Variable<String>(description);
    map['is_intentional'] = Variable<bool>(isIntentional);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TransactionEntriesCompanion toCompanion(bool nullToAbsent) {
    return TransactionEntriesCompanion(
      id: Value(id),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      date: Value(date),
      amount: Value(amount),
      description: Value(description),
      isIntentional: Value(isIntentional),
      createdAt: Value(createdAt),
    );
  }

  factory TransactionEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionEntry(
      id: serializer.fromJson<String>(json['id']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      date: serializer.fromJson<String>(json['date']),
      amount: serializer.fromJson<double>(json['amount']),
      description: serializer.fromJson<String>(json['description']),
      isIntentional: serializer.fromJson<bool>(json['isIntentional']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'categoryId': serializer.toJson<String?>(categoryId),
      'date': serializer.toJson<String>(date),
      'amount': serializer.toJson<double>(amount),
      'description': serializer.toJson<String>(description),
      'isIntentional': serializer.toJson<bool>(isIntentional),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  TransactionEntry copyWith(
          {String? id,
          Value<String?> categoryId = const Value.absent(),
          String? date,
          double? amount,
          String? description,
          bool? isIntentional,
          DateTime? createdAt}) =>
      TransactionEntry(
        id: id ?? this.id,
        categoryId: categoryId.present ? categoryId.value : this.categoryId,
        date: date ?? this.date,
        amount: amount ?? this.amount,
        description: description ?? this.description,
        isIntentional: isIntentional ?? this.isIntentional,
        createdAt: createdAt ?? this.createdAt,
      );
  TransactionEntry copyWithCompanion(TransactionEntriesCompanion data) {
    return TransactionEntry(
      id: data.id.present ? data.id.value : this.id,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      date: data.date.present ? data.date.value : this.date,
      amount: data.amount.present ? data.amount.value : this.amount,
      description:
          data.description.present ? data.description.value : this.description,
      isIntentional: data.isIntentional.present
          ? data.isIntentional.value
          : this.isIntentional,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionEntry(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('date: $date, ')
          ..write('amount: $amount, ')
          ..write('description: $description, ')
          ..write('isIntentional: $isIntentional, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, categoryId, date, amount, description, isIntentional, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionEntry &&
          other.id == this.id &&
          other.categoryId == this.categoryId &&
          other.date == this.date &&
          other.amount == this.amount &&
          other.description == this.description &&
          other.isIntentional == this.isIntentional &&
          other.createdAt == this.createdAt);
}

class TransactionEntriesCompanion extends UpdateCompanion<TransactionEntry> {
  final Value<String> id;
  final Value<String?> categoryId;
  final Value<String> date;
  final Value<double> amount;
  final Value<String> description;
  final Value<bool> isIntentional;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const TransactionEntriesCompanion({
    this.id = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.date = const Value.absent(),
    this.amount = const Value.absent(),
    this.description = const Value.absent(),
    this.isIntentional = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionEntriesCompanion.insert({
    required String id,
    this.categoryId = const Value.absent(),
    required String date,
    required double amount,
    this.description = const Value.absent(),
    this.isIntentional = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        date = Value(date),
        amount = Value(amount),
        createdAt = Value(createdAt);
  static Insertable<TransactionEntry> custom({
    Expression<String>? id,
    Expression<String>? categoryId,
    Expression<String>? date,
    Expression<double>? amount,
    Expression<String>? description,
    Expression<bool>? isIntentional,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (categoryId != null) 'category_id': categoryId,
      if (date != null) 'date': date,
      if (amount != null) 'amount': amount,
      if (description != null) 'description': description,
      if (isIntentional != null) 'is_intentional': isIntentional,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionEntriesCompanion copyWith(
      {Value<String>? id,
      Value<String?>? categoryId,
      Value<String>? date,
      Value<double>? amount,
      Value<String>? description,
      Value<bool>? isIntentional,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return TransactionEntriesCompanion(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      isIntentional: isIntentional ?? this.isIntentional,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (isIntentional.present) {
      map['is_intentional'] = Variable<bool>(isIntentional.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionEntriesCompanion(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('date: $date, ')
          ..write('amount: $amount, ')
          ..write('description: $description, ')
          ..write('isIntentional: $isIntentional, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TimeBudgetsTable extends TimeBudgets
    with TableInfo<$TimeBudgetsTable, TimeBudget> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TimeBudgetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
      'kind', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('other'));
  static const VerificationMeta _weeklyTargetHoursMeta =
      const VerificationMeta('weeklyTargetHours');
  @override
  late final GeneratedColumn<double> weeklyTargetHours =
      GeneratedColumn<double>('weekly_target_hours', aliasedName, false,
          type: DriftSqlType.double,
          requiredDuringInsert: false,
          defaultValue: const Constant(0));
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, kind, weeklyTargetHours, sortOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'time_budgets';
  @override
  VerificationContext validateIntegrity(Insertable<TimeBudget> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
          _kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    }
    if (data.containsKey('weekly_target_hours')) {
      context.handle(
          _weeklyTargetHoursMeta,
          weeklyTargetHours.isAcceptableOrUnknown(
              data['weekly_target_hours']!, _weeklyTargetHoursMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TimeBudget map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TimeBudget(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      weeklyTargetHours: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}weekly_target_hours'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
    );
  }

  @override
  $TimeBudgetsTable createAlias(String alias) {
    return $TimeBudgetsTable(attachedDatabase, alias);
  }
}

class TimeBudget extends DataClass implements Insertable<TimeBudget> {
  final String id;
  final String name;
  final String kind;
  final double weeklyTargetHours;
  final int sortOrder;
  const TimeBudget(
      {required this.id,
      required this.name,
      required this.kind,
      required this.weeklyTargetHours,
      required this.sortOrder});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['kind'] = Variable<String>(kind);
    map['weekly_target_hours'] = Variable<double>(weeklyTargetHours);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  TimeBudgetsCompanion toCompanion(bool nullToAbsent) {
    return TimeBudgetsCompanion(
      id: Value(id),
      name: Value(name),
      kind: Value(kind),
      weeklyTargetHours: Value(weeklyTargetHours),
      sortOrder: Value(sortOrder),
    );
  }

  factory TimeBudget.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TimeBudget(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      kind: serializer.fromJson<String>(json['kind']),
      weeklyTargetHours: serializer.fromJson<double>(json['weeklyTargetHours']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'kind': serializer.toJson<String>(kind),
      'weeklyTargetHours': serializer.toJson<double>(weeklyTargetHours),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  TimeBudget copyWith(
          {String? id,
          String? name,
          String? kind,
          double? weeklyTargetHours,
          int? sortOrder}) =>
      TimeBudget(
        id: id ?? this.id,
        name: name ?? this.name,
        kind: kind ?? this.kind,
        weeklyTargetHours: weeklyTargetHours ?? this.weeklyTargetHours,
        sortOrder: sortOrder ?? this.sortOrder,
      );
  TimeBudget copyWithCompanion(TimeBudgetsCompanion data) {
    return TimeBudget(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      kind: data.kind.present ? data.kind.value : this.kind,
      weeklyTargetHours: data.weeklyTargetHours.present
          ? data.weeklyTargetHours.value
          : this.weeklyTargetHours,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TimeBudget(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('weeklyTargetHours: $weeklyTargetHours, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, kind, weeklyTargetHours, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TimeBudget &&
          other.id == this.id &&
          other.name == this.name &&
          other.kind == this.kind &&
          other.weeklyTargetHours == this.weeklyTargetHours &&
          other.sortOrder == this.sortOrder);
}

class TimeBudgetsCompanion extends UpdateCompanion<TimeBudget> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> kind;
  final Value<double> weeklyTargetHours;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const TimeBudgetsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.kind = const Value.absent(),
    this.weeklyTargetHours = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TimeBudgetsCompanion.insert({
    required String id,
    required String name,
    this.kind = const Value.absent(),
    this.weeklyTargetHours = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name);
  static Insertable<TimeBudget> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? kind,
    Expression<double>? weeklyTargetHours,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (kind != null) 'kind': kind,
      if (weeklyTargetHours != null) 'weekly_target_hours': weeklyTargetHours,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TimeBudgetsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? kind,
      Value<double>? weeklyTargetHours,
      Value<int>? sortOrder,
      Value<int>? rowid}) {
    return TimeBudgetsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      weeklyTargetHours: weeklyTargetHours ?? this.weeklyTargetHours,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (weeklyTargetHours.present) {
      map['weekly_target_hours'] = Variable<double>(weeklyTargetHours.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TimeBudgetsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('weeklyTargetHours: $weeklyTargetHours, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TimeBlocksTable extends TimeBlocks
    with TableInfo<$TimeBlocksTable, TimeBlock> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TimeBlocksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _budgetIdMeta =
      const VerificationMeta('budgetId');
  @override
  late final GeneratedColumn<String> budgetId = GeneratedColumn<String>(
      'budget_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
      'date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _hoursMeta = const VerificationMeta('hours');
  @override
  late final GeneratedColumn<double> hours = GeneratedColumn<double>(
      'hours', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, budgetId, date, hours, note, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'time_blocks';
  @override
  VerificationContext validateIntegrity(Insertable<TimeBlock> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('budget_id')) {
      context.handle(_budgetIdMeta,
          budgetId.isAcceptableOrUnknown(data['budget_id']!, _budgetIdMeta));
    } else if (isInserting) {
      context.missing(_budgetIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('hours')) {
      context.handle(
          _hoursMeta, hours.isAcceptableOrUnknown(data['hours']!, _hoursMeta));
    } else if (isInserting) {
      context.missing(_hoursMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TimeBlock map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TimeBlock(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      budgetId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}budget_id'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}date'])!,
      hours: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}hours'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $TimeBlocksTable createAlias(String alias) {
    return $TimeBlocksTable(attachedDatabase, alias);
  }
}

class TimeBlock extends DataClass implements Insertable<TimeBlock> {
  final String id;
  final String budgetId;
  final String date;
  final double hours;
  final String? note;
  final DateTime createdAt;
  const TimeBlock(
      {required this.id,
      required this.budgetId,
      required this.date,
      required this.hours,
      this.note,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['budget_id'] = Variable<String>(budgetId);
    map['date'] = Variable<String>(date);
    map['hours'] = Variable<double>(hours);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TimeBlocksCompanion toCompanion(bool nullToAbsent) {
    return TimeBlocksCompanion(
      id: Value(id),
      budgetId: Value(budgetId),
      date: Value(date),
      hours: Value(hours),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory TimeBlock.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TimeBlock(
      id: serializer.fromJson<String>(json['id']),
      budgetId: serializer.fromJson<String>(json['budgetId']),
      date: serializer.fromJson<String>(json['date']),
      hours: serializer.fromJson<double>(json['hours']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'budgetId': serializer.toJson<String>(budgetId),
      'date': serializer.toJson<String>(date),
      'hours': serializer.toJson<double>(hours),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  TimeBlock copyWith(
          {String? id,
          String? budgetId,
          String? date,
          double? hours,
          Value<String?> note = const Value.absent(),
          DateTime? createdAt}) =>
      TimeBlock(
        id: id ?? this.id,
        budgetId: budgetId ?? this.budgetId,
        date: date ?? this.date,
        hours: hours ?? this.hours,
        note: note.present ? note.value : this.note,
        createdAt: createdAt ?? this.createdAt,
      );
  TimeBlock copyWithCompanion(TimeBlocksCompanion data) {
    return TimeBlock(
      id: data.id.present ? data.id.value : this.id,
      budgetId: data.budgetId.present ? data.budgetId.value : this.budgetId,
      date: data.date.present ? data.date.value : this.date,
      hours: data.hours.present ? data.hours.value : this.hours,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TimeBlock(')
          ..write('id: $id, ')
          ..write('budgetId: $budgetId, ')
          ..write('date: $date, ')
          ..write('hours: $hours, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, budgetId, date, hours, note, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TimeBlock &&
          other.id == this.id &&
          other.budgetId == this.budgetId &&
          other.date == this.date &&
          other.hours == this.hours &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class TimeBlocksCompanion extends UpdateCompanion<TimeBlock> {
  final Value<String> id;
  final Value<String> budgetId;
  final Value<String> date;
  final Value<double> hours;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const TimeBlocksCompanion({
    this.id = const Value.absent(),
    this.budgetId = const Value.absent(),
    this.date = const Value.absent(),
    this.hours = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TimeBlocksCompanion.insert({
    required String id,
    required String budgetId,
    required String date,
    required double hours,
    this.note = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        budgetId = Value(budgetId),
        date = Value(date),
        hours = Value(hours),
        createdAt = Value(createdAt);
  static Insertable<TimeBlock> custom({
    Expression<String>? id,
    Expression<String>? budgetId,
    Expression<String>? date,
    Expression<double>? hours,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (budgetId != null) 'budget_id': budgetId,
      if (date != null) 'date': date,
      if (hours != null) 'hours': hours,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TimeBlocksCompanion copyWith(
      {Value<String>? id,
      Value<String>? budgetId,
      Value<String>? date,
      Value<double>? hours,
      Value<String?>? note,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return TimeBlocksCompanion(
      id: id ?? this.id,
      budgetId: budgetId ?? this.budgetId,
      date: date ?? this.date,
      hours: hours ?? this.hours,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (budgetId.present) {
      map['budget_id'] = Variable<String>(budgetId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (hours.present) {
      map['hours'] = Variable<double>(hours.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TimeBlocksCompanion(')
          ..write('id: $id, ')
          ..write('budgetId: $budgetId, ')
          ..write('date: $date, ')
          ..write('hours: $hours, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CountdownsTable extends Countdowns
    with TableInfo<$CountdownsTable, Countdown> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CountdownsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _targetDateMeta =
      const VerificationMeta('targetDate');
  @override
  late final GeneratedColumn<String> targetDate = GeneratedColumn<String>(
      'target_date', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _dynamicKeyMeta =
      const VerificationMeta('dynamicKey');
  @override
  late final GeneratedColumn<String> dynamicKey = GeneratedColumn<String>(
      'dynamic_key', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns =>
      [id, title, targetDate, dynamicKey, sortOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'countdowns';
  @override
  VerificationContext validateIntegrity(Insertable<Countdown> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('target_date')) {
      context.handle(
          _targetDateMeta,
          targetDate.isAcceptableOrUnknown(
              data['target_date']!, _targetDateMeta));
    }
    if (data.containsKey('dynamic_key')) {
      context.handle(
          _dynamicKeyMeta,
          dynamicKey.isAcceptableOrUnknown(
              data['dynamic_key']!, _dynamicKeyMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Countdown map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Countdown(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      targetDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}target_date']),
      dynamicKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}dynamic_key']),
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
    );
  }

  @override
  $CountdownsTable createAlias(String alias) {
    return $CountdownsTable(attachedDatabase, alias);
  }
}

class Countdown extends DataClass implements Insertable<Countdown> {
  final String id;
  final String title;
  final String? targetDate;
  final String? dynamicKey;
  final int sortOrder;
  const Countdown(
      {required this.id,
      required this.title,
      this.targetDate,
      this.dynamicKey,
      required this.sortOrder});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || targetDate != null) {
      map['target_date'] = Variable<String>(targetDate);
    }
    if (!nullToAbsent || dynamicKey != null) {
      map['dynamic_key'] = Variable<String>(dynamicKey);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  CountdownsCompanion toCompanion(bool nullToAbsent) {
    return CountdownsCompanion(
      id: Value(id),
      title: Value(title),
      targetDate: targetDate == null && nullToAbsent
          ? const Value.absent()
          : Value(targetDate),
      dynamicKey: dynamicKey == null && nullToAbsent
          ? const Value.absent()
          : Value(dynamicKey),
      sortOrder: Value(sortOrder),
    );
  }

  factory Countdown.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Countdown(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      targetDate: serializer.fromJson<String?>(json['targetDate']),
      dynamicKey: serializer.fromJson<String?>(json['dynamicKey']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'targetDate': serializer.toJson<String?>(targetDate),
      'dynamicKey': serializer.toJson<String?>(dynamicKey),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  Countdown copyWith(
          {String? id,
          String? title,
          Value<String?> targetDate = const Value.absent(),
          Value<String?> dynamicKey = const Value.absent(),
          int? sortOrder}) =>
      Countdown(
        id: id ?? this.id,
        title: title ?? this.title,
        targetDate: targetDate.present ? targetDate.value : this.targetDate,
        dynamicKey: dynamicKey.present ? dynamicKey.value : this.dynamicKey,
        sortOrder: sortOrder ?? this.sortOrder,
      );
  Countdown copyWithCompanion(CountdownsCompanion data) {
    return Countdown(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      targetDate:
          data.targetDate.present ? data.targetDate.value : this.targetDate,
      dynamicKey:
          data.dynamicKey.present ? data.dynamicKey.value : this.dynamicKey,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Countdown(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('targetDate: $targetDate, ')
          ..write('dynamicKey: $dynamicKey, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, targetDate, dynamicKey, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Countdown &&
          other.id == this.id &&
          other.title == this.title &&
          other.targetDate == this.targetDate &&
          other.dynamicKey == this.dynamicKey &&
          other.sortOrder == this.sortOrder);
}

class CountdownsCompanion extends UpdateCompanion<Countdown> {
  final Value<String> id;
  final Value<String> title;
  final Value<String?> targetDate;
  final Value<String?> dynamicKey;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const CountdownsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.targetDate = const Value.absent(),
    this.dynamicKey = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CountdownsCompanion.insert({
    required String id,
    required String title,
    this.targetDate = const Value.absent(),
    this.dynamicKey = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        title = Value(title);
  static Insertable<Countdown> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? targetDate,
    Expression<String>? dynamicKey,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (targetDate != null) 'target_date': targetDate,
      if (dynamicKey != null) 'dynamic_key': dynamicKey,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CountdownsCompanion copyWith(
      {Value<String>? id,
      Value<String>? title,
      Value<String?>? targetDate,
      Value<String?>? dynamicKey,
      Value<int>? sortOrder,
      Value<int>? rowid}) {
    return CountdownsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      targetDate: targetDate ?? this.targetDate,
      dynamicKey: dynamicKey ?? this.dynamicKey,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (targetDate.present) {
      map['target_date'] = Variable<String>(targetDate.value);
    }
    if (dynamicKey.present) {
      map['dynamic_key'] = Variable<String>(dynamicKey.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CountdownsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('targetDate: $targetDate, ')
          ..write('dynamicKey: $dynamicKey, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HabitsTable extends Habits with TableInfo<$HabitsTable, Habit> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HabitsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('boolean'));
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
      'unit', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _isArchivedMeta =
      const VerificationMeta('isArchived');
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
      'is_archived', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_archived" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, type, unit, sortOrder, isArchived, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'habits';
  @override
  VerificationContext validateIntegrity(Insertable<Habit> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    }
    if (data.containsKey('unit')) {
      context.handle(
          _unitMeta, unit.isAcceptableOrUnknown(data['unit']!, _unitMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('is_archived')) {
      context.handle(
          _isArchivedMeta,
          isArchived.isAcceptableOrUnknown(
              data['is_archived']!, _isArchivedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Habit map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Habit(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      unit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit']),
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      isArchived: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_archived'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $HabitsTable createAlias(String alias) {
    return $HabitsTable(attachedDatabase, alias);
  }
}

class Habit extends DataClass implements Insertable<Habit> {
  final String id;
  final String name;
  final String type;
  final String? unit;
  final int sortOrder;
  final bool isArchived;
  final DateTime createdAt;
  const Habit(
      {required this.id,
      required this.name,
      required this.type,
      this.unit,
      required this.sortOrder,
      required this.isArchived,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['is_archived'] = Variable<bool>(isArchived);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  HabitsCompanion toCompanion(bool nullToAbsent) {
    return HabitsCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      sortOrder: Value(sortOrder),
      isArchived: Value(isArchived),
      createdAt: Value(createdAt),
    );
  }

  factory Habit.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Habit(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      unit: serializer.fromJson<String?>(json['unit']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'unit': serializer.toJson<String?>(unit),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'isArchived': serializer.toJson<bool>(isArchived),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Habit copyWith(
          {String? id,
          String? name,
          String? type,
          Value<String?> unit = const Value.absent(),
          int? sortOrder,
          bool? isArchived,
          DateTime? createdAt}) =>
      Habit(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        unit: unit.present ? unit.value : this.unit,
        sortOrder: sortOrder ?? this.sortOrder,
        isArchived: isArchived ?? this.isArchived,
        createdAt: createdAt ?? this.createdAt,
      );
  Habit copyWithCompanion(HabitsCompanion data) {
    return Habit(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      unit: data.unit.present ? data.unit.value : this.unit,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      isArchived:
          data.isArchived.present ? data.isArchived.value : this.isArchived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Habit(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('unit: $unit, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, type, unit, sortOrder, isArchived, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Habit &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.unit == this.unit &&
          other.sortOrder == this.sortOrder &&
          other.isArchived == this.isArchived &&
          other.createdAt == this.createdAt);
}

class HabitsCompanion extends UpdateCompanion<Habit> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> type;
  final Value<String?> unit;
  final Value<int> sortOrder;
  final Value<bool> isArchived;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const HabitsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.unit = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HabitsCompanion.insert({
    required String id,
    required String name,
    this.type = const Value.absent(),
    this.unit = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isArchived = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        createdAt = Value(createdAt);
  static Insertable<Habit> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? type,
    Expression<String>? unit,
    Expression<int>? sortOrder,
    Expression<bool>? isArchived,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (unit != null) 'unit': unit,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (isArchived != null) 'is_archived': isArchived,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HabitsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? type,
      Value<String?>? unit,
      Value<int>? sortOrder,
      Value<bool>? isArchived,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return HabitsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      unit: unit ?? this.unit,
      sortOrder: sortOrder ?? this.sortOrder,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HabitsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('unit: $unit, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HabitLogsTable extends HabitLogs
    with TableInfo<$HabitLogsTable, HabitLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HabitLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _habitIdMeta =
      const VerificationMeta('habitId');
  @override
  late final GeneratedColumn<String> habitId = GeneratedColumn<String>(
      'habit_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
      'date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<double> value = GeneratedColumn<double>(
      'value', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [id, habitId, date, value, note];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'habit_logs';
  @override
  VerificationContext validateIntegrity(Insertable<HabitLog> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('habit_id')) {
      context.handle(_habitIdMeta,
          habitId.isAcceptableOrUnknown(data['habit_id']!, _habitIdMeta));
    } else if (isInserting) {
      context.missing(_habitIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HabitLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HabitLog(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      habitId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}habit_id'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}date'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}value'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
    );
  }

  @override
  $HabitLogsTable createAlias(String alias) {
    return $HabitLogsTable(attachedDatabase, alias);
  }
}

class HabitLog extends DataClass implements Insertable<HabitLog> {
  final String id;
  final String habitId;
  final String date;
  final double value;
  final String? note;
  const HabitLog(
      {required this.id,
      required this.habitId,
      required this.date,
      required this.value,
      this.note});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['habit_id'] = Variable<String>(habitId);
    map['date'] = Variable<String>(date);
    map['value'] = Variable<double>(value);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  HabitLogsCompanion toCompanion(bool nullToAbsent) {
    return HabitLogsCompanion(
      id: Value(id),
      habitId: Value(habitId),
      date: Value(date),
      value: Value(value),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory HabitLog.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HabitLog(
      id: serializer.fromJson<String>(json['id']),
      habitId: serializer.fromJson<String>(json['habitId']),
      date: serializer.fromJson<String>(json['date']),
      value: serializer.fromJson<double>(json['value']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'habitId': serializer.toJson<String>(habitId),
      'date': serializer.toJson<String>(date),
      'value': serializer.toJson<double>(value),
      'note': serializer.toJson<String?>(note),
    };
  }

  HabitLog copyWith(
          {String? id,
          String? habitId,
          String? date,
          double? value,
          Value<String?> note = const Value.absent()}) =>
      HabitLog(
        id: id ?? this.id,
        habitId: habitId ?? this.habitId,
        date: date ?? this.date,
        value: value ?? this.value,
        note: note.present ? note.value : this.note,
      );
  HabitLog copyWithCompanion(HabitLogsCompanion data) {
    return HabitLog(
      id: data.id.present ? data.id.value : this.id,
      habitId: data.habitId.present ? data.habitId.value : this.habitId,
      date: data.date.present ? data.date.value : this.date,
      value: data.value.present ? data.value.value : this.value,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HabitLog(')
          ..write('id: $id, ')
          ..write('habitId: $habitId, ')
          ..write('date: $date, ')
          ..write('value: $value, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, habitId, date, value, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HabitLog &&
          other.id == this.id &&
          other.habitId == this.habitId &&
          other.date == this.date &&
          other.value == this.value &&
          other.note == this.note);
}

class HabitLogsCompanion extends UpdateCompanion<HabitLog> {
  final Value<String> id;
  final Value<String> habitId;
  final Value<String> date;
  final Value<double> value;
  final Value<String?> note;
  final Value<int> rowid;
  const HabitLogsCompanion({
    this.id = const Value.absent(),
    this.habitId = const Value.absent(),
    this.date = const Value.absent(),
    this.value = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HabitLogsCompanion.insert({
    required String id,
    required String habitId,
    required String date,
    this.value = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        habitId = Value(habitId),
        date = Value(date);
  static Insertable<HabitLog> custom({
    Expression<String>? id,
    Expression<String>? habitId,
    Expression<String>? date,
    Expression<double>? value,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (habitId != null) 'habit_id': habitId,
      if (date != null) 'date': date,
      if (value != null) 'value': value,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HabitLogsCompanion copyWith(
      {Value<String>? id,
      Value<String>? habitId,
      Value<String>? date,
      Value<double>? value,
      Value<String?>? note,
      Value<int>? rowid}) {
    return HabitLogsCompanion(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      date: date ?? this.date,
      value: value ?? this.value,
      note: note ?? this.note,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (habitId.present) {
      map['habit_id'] = Variable<String>(habitId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (value.present) {
      map['value'] = Variable<double>(value.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HabitLogsCompanion(')
          ..write('id: $id, ')
          ..write('habitId: $habitId, ')
          ..write('date: $date, ')
          ..write('value: $value, ')
          ..write('note: $note, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ParkedIdeasTable extends ParkedIdeas
    with TableInfo<$ParkedIdeasTable, ParkedIdea> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ParkedIdeasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _whyTemptingMeta =
      const VerificationMeta('whyTempting');
  @override
  late final GeneratedColumn<String> whyTempting = GeneratedColumn<String>(
      'why_tempting', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _potentialValueMeta =
      const VerificationMeta('potentialValue');
  @override
  late final GeneratedColumn<String> potentialValue = GeneratedColumn<String>(
      'potential_value', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _dateCapturedMeta =
      const VerificationMeta('dateCaptured');
  @override
  late final GeneratedColumn<String> dateCaptured = GeneratedColumn<String>(
      'date_captured', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _reviewDateMeta =
      const VerificationMeta('reviewDate');
  @override
  late final GeneratedColumn<String> reviewDate = GeneratedColumn<String>(
      'review_date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _decisionMeta =
      const VerificationMeta('decision');
  @override
  late final GeneratedColumn<String> decision = GeneratedColumn<String>(
      'decision', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('undecided'));
  static const VerificationMeta _directlyHelpsKaizenThisWeekMeta =
      const VerificationMeta('directlyHelpsKaizenThisWeek');
  @override
  late final GeneratedColumn<bool> directlyHelpsKaizenThisWeek =
      GeneratedColumn<bool>(
          'directly_helps_kaizen_this_week', aliasedName, false,
          type: DriftSqlType.bool,
          requiredDuringInsert: false,
          defaultConstraints: GeneratedColumn.constraintIsAlways(
              'CHECK ("directly_helps_kaizen_this_week" IN (0, 1))'),
          defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        title,
        description,
        category,
        whyTempting,
        potentialValue,
        dateCaptured,
        reviewDate,
        decision,
        directlyHelpsKaizenThisWeek,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'parked_ideas';
  @override
  VerificationContext validateIntegrity(Insertable<ParkedIdea> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    }
    if (data.containsKey('why_tempting')) {
      context.handle(
          _whyTemptingMeta,
          whyTempting.isAcceptableOrUnknown(
              data['why_tempting']!, _whyTemptingMeta));
    }
    if (data.containsKey('potential_value')) {
      context.handle(
          _potentialValueMeta,
          potentialValue.isAcceptableOrUnknown(
              data['potential_value']!, _potentialValueMeta));
    }
    if (data.containsKey('date_captured')) {
      context.handle(
          _dateCapturedMeta,
          dateCaptured.isAcceptableOrUnknown(
              data['date_captured']!, _dateCapturedMeta));
    } else if (isInserting) {
      context.missing(_dateCapturedMeta);
    }
    if (data.containsKey('review_date')) {
      context.handle(
          _reviewDateMeta,
          reviewDate.isAcceptableOrUnknown(
              data['review_date']!, _reviewDateMeta));
    } else if (isInserting) {
      context.missing(_reviewDateMeta);
    }
    if (data.containsKey('decision')) {
      context.handle(_decisionMeta,
          decision.isAcceptableOrUnknown(data['decision']!, _decisionMeta));
    }
    if (data.containsKey('directly_helps_kaizen_this_week')) {
      context.handle(
          _directlyHelpsKaizenThisWeekMeta,
          directlyHelpsKaizenThisWeek.isAcceptableOrUnknown(
              data['directly_helps_kaizen_this_week']!,
              _directlyHelpsKaizenThisWeekMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ParkedIdea map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ParkedIdea(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category']),
      whyTempting: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}why_tempting']),
      potentialValue: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}potential_value']),
      dateCaptured: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}date_captured'])!,
      reviewDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}review_date'])!,
      decision: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}decision'])!,
      directlyHelpsKaizenThisWeek: attachedDatabase.typeMapping.read(
          DriftSqlType.bool,
          data['${effectivePrefix}directly_helps_kaizen_this_week'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $ParkedIdeasTable createAlias(String alias) {
    return $ParkedIdeasTable(attachedDatabase, alias);
  }
}

class ParkedIdea extends DataClass implements Insertable<ParkedIdea> {
  final String id;
  final String title;
  final String? description;
  final String? category;
  final String? whyTempting;
  final String? potentialValue;
  final String dateCaptured;
  final String reviewDate;
  final String decision;
  final bool directlyHelpsKaizenThisWeek;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ParkedIdea(
      {required this.id,
      required this.title,
      this.description,
      this.category,
      this.whyTempting,
      this.potentialValue,
      required this.dateCaptured,
      required this.reviewDate,
      required this.decision,
      required this.directlyHelpsKaizenThisWeek,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    if (!nullToAbsent || whyTempting != null) {
      map['why_tempting'] = Variable<String>(whyTempting);
    }
    if (!nullToAbsent || potentialValue != null) {
      map['potential_value'] = Variable<String>(potentialValue);
    }
    map['date_captured'] = Variable<String>(dateCaptured);
    map['review_date'] = Variable<String>(reviewDate);
    map['decision'] = Variable<String>(decision);
    map['directly_helps_kaizen_this_week'] =
        Variable<bool>(directlyHelpsKaizenThisWeek);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ParkedIdeasCompanion toCompanion(bool nullToAbsent) {
    return ParkedIdeasCompanion(
      id: Value(id),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      whyTempting: whyTempting == null && nullToAbsent
          ? const Value.absent()
          : Value(whyTempting),
      potentialValue: potentialValue == null && nullToAbsent
          ? const Value.absent()
          : Value(potentialValue),
      dateCaptured: Value(dateCaptured),
      reviewDate: Value(reviewDate),
      decision: Value(decision),
      directlyHelpsKaizenThisWeek: Value(directlyHelpsKaizenThisWeek),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ParkedIdea.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ParkedIdea(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      category: serializer.fromJson<String?>(json['category']),
      whyTempting: serializer.fromJson<String?>(json['whyTempting']),
      potentialValue: serializer.fromJson<String?>(json['potentialValue']),
      dateCaptured: serializer.fromJson<String>(json['dateCaptured']),
      reviewDate: serializer.fromJson<String>(json['reviewDate']),
      decision: serializer.fromJson<String>(json['decision']),
      directlyHelpsKaizenThisWeek:
          serializer.fromJson<bool>(json['directlyHelpsKaizenThisWeek']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'category': serializer.toJson<String?>(category),
      'whyTempting': serializer.toJson<String?>(whyTempting),
      'potentialValue': serializer.toJson<String?>(potentialValue),
      'dateCaptured': serializer.toJson<String>(dateCaptured),
      'reviewDate': serializer.toJson<String>(reviewDate),
      'decision': serializer.toJson<String>(decision),
      'directlyHelpsKaizenThisWeek':
          serializer.toJson<bool>(directlyHelpsKaizenThisWeek),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ParkedIdea copyWith(
          {String? id,
          String? title,
          Value<String?> description = const Value.absent(),
          Value<String?> category = const Value.absent(),
          Value<String?> whyTempting = const Value.absent(),
          Value<String?> potentialValue = const Value.absent(),
          String? dateCaptured,
          String? reviewDate,
          String? decision,
          bool? directlyHelpsKaizenThisWeek,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      ParkedIdea(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description.present ? description.value : this.description,
        category: category.present ? category.value : this.category,
        whyTempting: whyTempting.present ? whyTempting.value : this.whyTempting,
        potentialValue:
            potentialValue.present ? potentialValue.value : this.potentialValue,
        dateCaptured: dateCaptured ?? this.dateCaptured,
        reviewDate: reviewDate ?? this.reviewDate,
        decision: decision ?? this.decision,
        directlyHelpsKaizenThisWeek:
            directlyHelpsKaizenThisWeek ?? this.directlyHelpsKaizenThisWeek,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  ParkedIdea copyWithCompanion(ParkedIdeasCompanion data) {
    return ParkedIdea(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      description:
          data.description.present ? data.description.value : this.description,
      category: data.category.present ? data.category.value : this.category,
      whyTempting:
          data.whyTempting.present ? data.whyTempting.value : this.whyTempting,
      potentialValue: data.potentialValue.present
          ? data.potentialValue.value
          : this.potentialValue,
      dateCaptured: data.dateCaptured.present
          ? data.dateCaptured.value
          : this.dateCaptured,
      reviewDate:
          data.reviewDate.present ? data.reviewDate.value : this.reviewDate,
      decision: data.decision.present ? data.decision.value : this.decision,
      directlyHelpsKaizenThisWeek: data.directlyHelpsKaizenThisWeek.present
          ? data.directlyHelpsKaizenThisWeek.value
          : this.directlyHelpsKaizenThisWeek,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ParkedIdea(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('category: $category, ')
          ..write('whyTempting: $whyTempting, ')
          ..write('potentialValue: $potentialValue, ')
          ..write('dateCaptured: $dateCaptured, ')
          ..write('reviewDate: $reviewDate, ')
          ..write('decision: $decision, ')
          ..write('directlyHelpsKaizenThisWeek: $directlyHelpsKaizenThisWeek, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      title,
      description,
      category,
      whyTempting,
      potentialValue,
      dateCaptured,
      reviewDate,
      decision,
      directlyHelpsKaizenThisWeek,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ParkedIdea &&
          other.id == this.id &&
          other.title == this.title &&
          other.description == this.description &&
          other.category == this.category &&
          other.whyTempting == this.whyTempting &&
          other.potentialValue == this.potentialValue &&
          other.dateCaptured == this.dateCaptured &&
          other.reviewDate == this.reviewDate &&
          other.decision == this.decision &&
          other.directlyHelpsKaizenThisWeek ==
              this.directlyHelpsKaizenThisWeek &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ParkedIdeasCompanion extends UpdateCompanion<ParkedIdea> {
  final Value<String> id;
  final Value<String> title;
  final Value<String?> description;
  final Value<String?> category;
  final Value<String?> whyTempting;
  final Value<String?> potentialValue;
  final Value<String> dateCaptured;
  final Value<String> reviewDate;
  final Value<String> decision;
  final Value<bool> directlyHelpsKaizenThisWeek;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ParkedIdeasCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.category = const Value.absent(),
    this.whyTempting = const Value.absent(),
    this.potentialValue = const Value.absent(),
    this.dateCaptured = const Value.absent(),
    this.reviewDate = const Value.absent(),
    this.decision = const Value.absent(),
    this.directlyHelpsKaizenThisWeek = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ParkedIdeasCompanion.insert({
    required String id,
    required String title,
    this.description = const Value.absent(),
    this.category = const Value.absent(),
    this.whyTempting = const Value.absent(),
    this.potentialValue = const Value.absent(),
    required String dateCaptured,
    required String reviewDate,
    this.decision = const Value.absent(),
    this.directlyHelpsKaizenThisWeek = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        title = Value(title),
        dateCaptured = Value(dateCaptured),
        reviewDate = Value(reviewDate),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<ParkedIdea> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? category,
    Expression<String>? whyTempting,
    Expression<String>? potentialValue,
    Expression<String>? dateCaptured,
    Expression<String>? reviewDate,
    Expression<String>? decision,
    Expression<bool>? directlyHelpsKaizenThisWeek,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      if (whyTempting != null) 'why_tempting': whyTempting,
      if (potentialValue != null) 'potential_value': potentialValue,
      if (dateCaptured != null) 'date_captured': dateCaptured,
      if (reviewDate != null) 'review_date': reviewDate,
      if (decision != null) 'decision': decision,
      if (directlyHelpsKaizenThisWeek != null)
        'directly_helps_kaizen_this_week': directlyHelpsKaizenThisWeek,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ParkedIdeasCompanion copyWith(
      {Value<String>? id,
      Value<String>? title,
      Value<String?>? description,
      Value<String?>? category,
      Value<String?>? whyTempting,
      Value<String?>? potentialValue,
      Value<String>? dateCaptured,
      Value<String>? reviewDate,
      Value<String>? decision,
      Value<bool>? directlyHelpsKaizenThisWeek,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return ParkedIdeasCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      whyTempting: whyTempting ?? this.whyTempting,
      potentialValue: potentialValue ?? this.potentialValue,
      dateCaptured: dateCaptured ?? this.dateCaptured,
      reviewDate: reviewDate ?? this.reviewDate,
      decision: decision ?? this.decision,
      directlyHelpsKaizenThisWeek:
          directlyHelpsKaizenThisWeek ?? this.directlyHelpsKaizenThisWeek,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (whyTempting.present) {
      map['why_tempting'] = Variable<String>(whyTempting.value);
    }
    if (potentialValue.present) {
      map['potential_value'] = Variable<String>(potentialValue.value);
    }
    if (dateCaptured.present) {
      map['date_captured'] = Variable<String>(dateCaptured.value);
    }
    if (reviewDate.present) {
      map['review_date'] = Variable<String>(reviewDate.value);
    }
    if (decision.present) {
      map['decision'] = Variable<String>(decision.value);
    }
    if (directlyHelpsKaizenThisWeek.present) {
      map['directly_helps_kaizen_this_week'] =
          Variable<bool>(directlyHelpsKaizenThisWeek.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ParkedIdeasCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('category: $category, ')
          ..write('whyTempting: $whyTempting, ')
          ..write('potentialValue: $potentialValue, ')
          ..write('dateCaptured: $dateCaptured, ')
          ..write('reviewDate: $reviewDate, ')
          ..write('decision: $decision, ')
          ..write('directlyHelpsKaizenThisWeek: $directlyHelpsKaizenThisWeek, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GoalsTable extends Goals with TableInfo<$GoalsTable, Goal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GoalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _metricNameMeta =
      const VerificationMeta('metricName');
  @override
  late final GeneratedColumn<String> metricName = GeneratedColumn<String>(
      'metric_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _currentValueMeta =
      const VerificationMeta('currentValue');
  @override
  late final GeneratedColumn<double> currentValue = GeneratedColumn<double>(
      'current_value', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _targetValueMeta =
      const VerificationMeta('targetValue');
  @override
  late final GeneratedColumn<double> targetValue = GeneratedColumn<double>(
      'target_value', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _targetDateMeta =
      const VerificationMeta('targetDate');
  @override
  late final GeneratedColumn<String> targetDate = GeneratedColumn<String>(
      'target_date', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        title,
        description,
        metricName,
        currentValue,
        targetValue,
        targetDate,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'goals';
  @override
  VerificationContext validateIntegrity(Insertable<Goal> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('metric_name')) {
      context.handle(
          _metricNameMeta,
          metricName.isAcceptableOrUnknown(
              data['metric_name']!, _metricNameMeta));
    }
    if (data.containsKey('current_value')) {
      context.handle(
          _currentValueMeta,
          currentValue.isAcceptableOrUnknown(
              data['current_value']!, _currentValueMeta));
    }
    if (data.containsKey('target_value')) {
      context.handle(
          _targetValueMeta,
          targetValue.isAcceptableOrUnknown(
              data['target_value']!, _targetValueMeta));
    }
    if (data.containsKey('target_date')) {
      context.handle(
          _targetDateMeta,
          targetDate.isAcceptableOrUnknown(
              data['target_date']!, _targetDateMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Goal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Goal(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      metricName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}metric_name']),
      currentValue: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}current_value'])!,
      targetValue: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}target_value'])!,
      targetDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}target_date']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $GoalsTable createAlias(String alias) {
    return $GoalsTable(attachedDatabase, alias);
  }
}

class Goal extends DataClass implements Insertable<Goal> {
  final String id;
  final String title;
  final String? description;
  final String? metricName;
  final double currentValue;
  final double targetValue;
  final String? targetDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Goal(
      {required this.id,
      required this.title,
      this.description,
      this.metricName,
      required this.currentValue,
      required this.targetValue,
      this.targetDate,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || metricName != null) {
      map['metric_name'] = Variable<String>(metricName);
    }
    map['current_value'] = Variable<double>(currentValue);
    map['target_value'] = Variable<double>(targetValue);
    if (!nullToAbsent || targetDate != null) {
      map['target_date'] = Variable<String>(targetDate);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  GoalsCompanion toCompanion(bool nullToAbsent) {
    return GoalsCompanion(
      id: Value(id),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      metricName: metricName == null && nullToAbsent
          ? const Value.absent()
          : Value(metricName),
      currentValue: Value(currentValue),
      targetValue: Value(targetValue),
      targetDate: targetDate == null && nullToAbsent
          ? const Value.absent()
          : Value(targetDate),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Goal.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Goal(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      metricName: serializer.fromJson<String?>(json['metricName']),
      currentValue: serializer.fromJson<double>(json['currentValue']),
      targetValue: serializer.fromJson<double>(json['targetValue']),
      targetDate: serializer.fromJson<String?>(json['targetDate']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'metricName': serializer.toJson<String?>(metricName),
      'currentValue': serializer.toJson<double>(currentValue),
      'targetValue': serializer.toJson<double>(targetValue),
      'targetDate': serializer.toJson<String?>(targetDate),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Goal copyWith(
          {String? id,
          String? title,
          Value<String?> description = const Value.absent(),
          Value<String?> metricName = const Value.absent(),
          double? currentValue,
          double? targetValue,
          Value<String?> targetDate = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Goal(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description.present ? description.value : this.description,
        metricName: metricName.present ? metricName.value : this.metricName,
        currentValue: currentValue ?? this.currentValue,
        targetValue: targetValue ?? this.targetValue,
        targetDate: targetDate.present ? targetDate.value : this.targetDate,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Goal copyWithCompanion(GoalsCompanion data) {
    return Goal(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      description:
          data.description.present ? data.description.value : this.description,
      metricName:
          data.metricName.present ? data.metricName.value : this.metricName,
      currentValue: data.currentValue.present
          ? data.currentValue.value
          : this.currentValue,
      targetValue:
          data.targetValue.present ? data.targetValue.value : this.targetValue,
      targetDate:
          data.targetDate.present ? data.targetDate.value : this.targetDate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Goal(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('metricName: $metricName, ')
          ..write('currentValue: $currentValue, ')
          ..write('targetValue: $targetValue, ')
          ..write('targetDate: $targetDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, description, metricName,
      currentValue, targetValue, targetDate, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Goal &&
          other.id == this.id &&
          other.title == this.title &&
          other.description == this.description &&
          other.metricName == this.metricName &&
          other.currentValue == this.currentValue &&
          other.targetValue == this.targetValue &&
          other.targetDate == this.targetDate &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class GoalsCompanion extends UpdateCompanion<Goal> {
  final Value<String> id;
  final Value<String> title;
  final Value<String?> description;
  final Value<String?> metricName;
  final Value<double> currentValue;
  final Value<double> targetValue;
  final Value<String?> targetDate;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const GoalsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.metricName = const Value.absent(),
    this.currentValue = const Value.absent(),
    this.targetValue = const Value.absent(),
    this.targetDate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GoalsCompanion.insert({
    required String id,
    required String title,
    this.description = const Value.absent(),
    this.metricName = const Value.absent(),
    this.currentValue = const Value.absent(),
    this.targetValue = const Value.absent(),
    this.targetDate = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        title = Value(title),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Goal> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? metricName,
    Expression<double>? currentValue,
    Expression<double>? targetValue,
    Expression<String>? targetDate,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (metricName != null) 'metric_name': metricName,
      if (currentValue != null) 'current_value': currentValue,
      if (targetValue != null) 'target_value': targetValue,
      if (targetDate != null) 'target_date': targetDate,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GoalsCompanion copyWith(
      {Value<String>? id,
      Value<String>? title,
      Value<String?>? description,
      Value<String?>? metricName,
      Value<double>? currentValue,
      Value<double>? targetValue,
      Value<String?>? targetDate,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return GoalsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      metricName: metricName ?? this.metricName,
      currentValue: currentValue ?? this.currentValue,
      targetValue: targetValue ?? this.targetValue,
      targetDate: targetDate ?? this.targetDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (metricName.present) {
      map['metric_name'] = Variable<String>(metricName.value);
    }
    if (currentValue.present) {
      map['current_value'] = Variable<double>(currentValue.value);
    }
    if (targetValue.present) {
      map['target_value'] = Variable<double>(targetValue.value);
    }
    if (targetDate.present) {
      map['target_date'] = Variable<String>(targetDate.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GoalsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('metricName: $metricName, ')
          ..write('currentValue: $currentValue, ')
          ..write('targetValue: $targetValue, ')
          ..write('targetDate: $targetDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FreedomTargetsTable extends FreedomTargets
    with TableInfo<$FreedomTargetsTable, FreedomTarget> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FreedomTargetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _targetMonthlyPassiveIncomeMeta =
      const VerificationMeta('targetMonthlyPassiveIncome');
  @override
  late final GeneratedColumn<double> targetMonthlyPassiveIncome =
      GeneratedColumn<double>(
          'target_monthly_passive_income', aliasedName, false,
          type: DriftSqlType.double,
          requiredDuringInsert: false,
          defaultValue: const Constant(0));
  static const VerificationMeta _targetLiquidNetWorthMeta =
      const VerificationMeta('targetLiquidNetWorth');
  @override
  late final GeneratedColumn<double> targetLiquidNetWorth =
      GeneratedColumn<double>('target_liquid_net_worth', aliasedName, false,
          type: DriftSqlType.double,
          requiredDuringInsert: false,
          defaultValue: const Constant(0));
  static const VerificationMeta _currentMonthlyPassiveIncomeMeta =
      const VerificationMeta('currentMonthlyPassiveIncome');
  @override
  late final GeneratedColumn<double> currentMonthlyPassiveIncome =
      GeneratedColumn<double>(
          'current_monthly_passive_income', aliasedName, false,
          type: DriftSqlType.double,
          requiredDuringInsert: false,
          defaultValue: const Constant(0));
  static const VerificationMeta _currentLiquidNetWorthMeta =
      const VerificationMeta('currentLiquidNetWorth');
  @override
  late final GeneratedColumn<double> currentLiquidNetWorth =
      GeneratedColumn<double>('current_liquid_net_worth', aliasedName, false,
          type: DriftSqlType.double,
          requiredDuringInsert: false,
          defaultValue: const Constant(0));
  static const VerificationMeta _targetDateMeta =
      const VerificationMeta('targetDate');
  @override
  late final GeneratedColumn<String> targetDate = GeneratedColumn<String>(
      'target_date', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        title,
        description,
        targetMonthlyPassiveIncome,
        targetLiquidNetWorth,
        currentMonthlyPassiveIncome,
        currentLiquidNetWorth,
        targetDate,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'freedom_targets';
  @override
  VerificationContext validateIntegrity(Insertable<FreedomTarget> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('target_monthly_passive_income')) {
      context.handle(
          _targetMonthlyPassiveIncomeMeta,
          targetMonthlyPassiveIncome.isAcceptableOrUnknown(
              data['target_monthly_passive_income']!,
              _targetMonthlyPassiveIncomeMeta));
    }
    if (data.containsKey('target_liquid_net_worth')) {
      context.handle(
          _targetLiquidNetWorthMeta,
          targetLiquidNetWorth.isAcceptableOrUnknown(
              data['target_liquid_net_worth']!, _targetLiquidNetWorthMeta));
    }
    if (data.containsKey('current_monthly_passive_income')) {
      context.handle(
          _currentMonthlyPassiveIncomeMeta,
          currentMonthlyPassiveIncome.isAcceptableOrUnknown(
              data['current_monthly_passive_income']!,
              _currentMonthlyPassiveIncomeMeta));
    }
    if (data.containsKey('current_liquid_net_worth')) {
      context.handle(
          _currentLiquidNetWorthMeta,
          currentLiquidNetWorth.isAcceptableOrUnknown(
              data['current_liquid_net_worth']!, _currentLiquidNetWorthMeta));
    }
    if (data.containsKey('target_date')) {
      context.handle(
          _targetDateMeta,
          targetDate.isAcceptableOrUnknown(
              data['target_date']!, _targetDateMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FreedomTarget map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FreedomTarget(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      targetMonthlyPassiveIncome: attachedDatabase.typeMapping.read(
          DriftSqlType.double,
          data['${effectivePrefix}target_monthly_passive_income'])!,
      targetLiquidNetWorth: attachedDatabase.typeMapping.read(
          DriftSqlType.double,
          data['${effectivePrefix}target_liquid_net_worth'])!,
      currentMonthlyPassiveIncome: attachedDatabase.typeMapping.read(
          DriftSqlType.double,
          data['${effectivePrefix}current_monthly_passive_income'])!,
      currentLiquidNetWorth: attachedDatabase.typeMapping.read(
          DriftSqlType.double,
          data['${effectivePrefix}current_liquid_net_worth'])!,
      targetDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}target_date']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $FreedomTargetsTable createAlias(String alias) {
    return $FreedomTargetsTable(attachedDatabase, alias);
  }
}

class FreedomTarget extends DataClass implements Insertable<FreedomTarget> {
  final String id;
  final String title;
  final String? description;
  final double targetMonthlyPassiveIncome;
  final double targetLiquidNetWorth;
  final double currentMonthlyPassiveIncome;
  final double currentLiquidNetWorth;
  final String? targetDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  const FreedomTarget(
      {required this.id,
      required this.title,
      this.description,
      required this.targetMonthlyPassiveIncome,
      required this.targetLiquidNetWorth,
      required this.currentMonthlyPassiveIncome,
      required this.currentLiquidNetWorth,
      this.targetDate,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['target_monthly_passive_income'] =
        Variable<double>(targetMonthlyPassiveIncome);
    map['target_liquid_net_worth'] = Variable<double>(targetLiquidNetWorth);
    map['current_monthly_passive_income'] =
        Variable<double>(currentMonthlyPassiveIncome);
    map['current_liquid_net_worth'] = Variable<double>(currentLiquidNetWorth);
    if (!nullToAbsent || targetDate != null) {
      map['target_date'] = Variable<String>(targetDate);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  FreedomTargetsCompanion toCompanion(bool nullToAbsent) {
    return FreedomTargetsCompanion(
      id: Value(id),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      targetMonthlyPassiveIncome: Value(targetMonthlyPassiveIncome),
      targetLiquidNetWorth: Value(targetLiquidNetWorth),
      currentMonthlyPassiveIncome: Value(currentMonthlyPassiveIncome),
      currentLiquidNetWorth: Value(currentLiquidNetWorth),
      targetDate: targetDate == null && nullToAbsent
          ? const Value.absent()
          : Value(targetDate),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory FreedomTarget.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FreedomTarget(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      targetMonthlyPassiveIncome:
          serializer.fromJson<double>(json['targetMonthlyPassiveIncome']),
      targetLiquidNetWorth:
          serializer.fromJson<double>(json['targetLiquidNetWorth']),
      currentMonthlyPassiveIncome:
          serializer.fromJson<double>(json['currentMonthlyPassiveIncome']),
      currentLiquidNetWorth:
          serializer.fromJson<double>(json['currentLiquidNetWorth']),
      targetDate: serializer.fromJson<String?>(json['targetDate']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'targetMonthlyPassiveIncome':
          serializer.toJson<double>(targetMonthlyPassiveIncome),
      'targetLiquidNetWorth': serializer.toJson<double>(targetLiquidNetWorth),
      'currentMonthlyPassiveIncome':
          serializer.toJson<double>(currentMonthlyPassiveIncome),
      'currentLiquidNetWorth': serializer.toJson<double>(currentLiquidNetWorth),
      'targetDate': serializer.toJson<String?>(targetDate),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  FreedomTarget copyWith(
          {String? id,
          String? title,
          Value<String?> description = const Value.absent(),
          double? targetMonthlyPassiveIncome,
          double? targetLiquidNetWorth,
          double? currentMonthlyPassiveIncome,
          double? currentLiquidNetWorth,
          Value<String?> targetDate = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      FreedomTarget(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description.present ? description.value : this.description,
        targetMonthlyPassiveIncome:
            targetMonthlyPassiveIncome ?? this.targetMonthlyPassiveIncome,
        targetLiquidNetWorth: targetLiquidNetWorth ?? this.targetLiquidNetWorth,
        currentMonthlyPassiveIncome:
            currentMonthlyPassiveIncome ?? this.currentMonthlyPassiveIncome,
        currentLiquidNetWorth:
            currentLiquidNetWorth ?? this.currentLiquidNetWorth,
        targetDate: targetDate.present ? targetDate.value : this.targetDate,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  FreedomTarget copyWithCompanion(FreedomTargetsCompanion data) {
    return FreedomTarget(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      description:
          data.description.present ? data.description.value : this.description,
      targetMonthlyPassiveIncome: data.targetMonthlyPassiveIncome.present
          ? data.targetMonthlyPassiveIncome.value
          : this.targetMonthlyPassiveIncome,
      targetLiquidNetWorth: data.targetLiquidNetWorth.present
          ? data.targetLiquidNetWorth.value
          : this.targetLiquidNetWorth,
      currentMonthlyPassiveIncome: data.currentMonthlyPassiveIncome.present
          ? data.currentMonthlyPassiveIncome.value
          : this.currentMonthlyPassiveIncome,
      currentLiquidNetWorth: data.currentLiquidNetWorth.present
          ? data.currentLiquidNetWorth.value
          : this.currentLiquidNetWorth,
      targetDate:
          data.targetDate.present ? data.targetDate.value : this.targetDate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FreedomTarget(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('targetMonthlyPassiveIncome: $targetMonthlyPassiveIncome, ')
          ..write('targetLiquidNetWorth: $targetLiquidNetWorth, ')
          ..write('currentMonthlyPassiveIncome: $currentMonthlyPassiveIncome, ')
          ..write('currentLiquidNetWorth: $currentLiquidNetWorth, ')
          ..write('targetDate: $targetDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      title,
      description,
      targetMonthlyPassiveIncome,
      targetLiquidNetWorth,
      currentMonthlyPassiveIncome,
      currentLiquidNetWorth,
      targetDate,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FreedomTarget &&
          other.id == this.id &&
          other.title == this.title &&
          other.description == this.description &&
          other.targetMonthlyPassiveIncome == this.targetMonthlyPassiveIncome &&
          other.targetLiquidNetWorth == this.targetLiquidNetWorth &&
          other.currentMonthlyPassiveIncome ==
              this.currentMonthlyPassiveIncome &&
          other.currentLiquidNetWorth == this.currentLiquidNetWorth &&
          other.targetDate == this.targetDate &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class FreedomTargetsCompanion extends UpdateCompanion<FreedomTarget> {
  final Value<String> id;
  final Value<String> title;
  final Value<String?> description;
  final Value<double> targetMonthlyPassiveIncome;
  final Value<double> targetLiquidNetWorth;
  final Value<double> currentMonthlyPassiveIncome;
  final Value<double> currentLiquidNetWorth;
  final Value<String?> targetDate;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const FreedomTargetsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.targetMonthlyPassiveIncome = const Value.absent(),
    this.targetLiquidNetWorth = const Value.absent(),
    this.currentMonthlyPassiveIncome = const Value.absent(),
    this.currentLiquidNetWorth = const Value.absent(),
    this.targetDate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FreedomTargetsCompanion.insert({
    required String id,
    required String title,
    this.description = const Value.absent(),
    this.targetMonthlyPassiveIncome = const Value.absent(),
    this.targetLiquidNetWorth = const Value.absent(),
    this.currentMonthlyPassiveIncome = const Value.absent(),
    this.currentLiquidNetWorth = const Value.absent(),
    this.targetDate = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        title = Value(title),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<FreedomTarget> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? description,
    Expression<double>? targetMonthlyPassiveIncome,
    Expression<double>? targetLiquidNetWorth,
    Expression<double>? currentMonthlyPassiveIncome,
    Expression<double>? currentLiquidNetWorth,
    Expression<String>? targetDate,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (targetMonthlyPassiveIncome != null)
        'target_monthly_passive_income': targetMonthlyPassiveIncome,
      if (targetLiquidNetWorth != null)
        'target_liquid_net_worth': targetLiquidNetWorth,
      if (currentMonthlyPassiveIncome != null)
        'current_monthly_passive_income': currentMonthlyPassiveIncome,
      if (currentLiquidNetWorth != null)
        'current_liquid_net_worth': currentLiquidNetWorth,
      if (targetDate != null) 'target_date': targetDate,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FreedomTargetsCompanion copyWith(
      {Value<String>? id,
      Value<String>? title,
      Value<String?>? description,
      Value<double>? targetMonthlyPassiveIncome,
      Value<double>? targetLiquidNetWorth,
      Value<double>? currentMonthlyPassiveIncome,
      Value<double>? currentLiquidNetWorth,
      Value<String?>? targetDate,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return FreedomTargetsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      targetMonthlyPassiveIncome:
          targetMonthlyPassiveIncome ?? this.targetMonthlyPassiveIncome,
      targetLiquidNetWorth: targetLiquidNetWorth ?? this.targetLiquidNetWorth,
      currentMonthlyPassiveIncome:
          currentMonthlyPassiveIncome ?? this.currentMonthlyPassiveIncome,
      currentLiquidNetWorth:
          currentLiquidNetWorth ?? this.currentLiquidNetWorth,
      targetDate: targetDate ?? this.targetDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (targetMonthlyPassiveIncome.present) {
      map['target_monthly_passive_income'] =
          Variable<double>(targetMonthlyPassiveIncome.value);
    }
    if (targetLiquidNetWorth.present) {
      map['target_liquid_net_worth'] =
          Variable<double>(targetLiquidNetWorth.value);
    }
    if (currentMonthlyPassiveIncome.present) {
      map['current_monthly_passive_income'] =
          Variable<double>(currentMonthlyPassiveIncome.value);
    }
    if (currentLiquidNetWorth.present) {
      map['current_liquid_net_worth'] =
          Variable<double>(currentLiquidNetWorth.value);
    }
    if (targetDate.present) {
      map['target_date'] = Variable<String>(targetDate.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FreedomTargetsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('targetMonthlyPassiveIncome: $targetMonthlyPassiveIncome, ')
          ..write('targetLiquidNetWorth: $targetLiquidNetWorth, ')
          ..write('currentMonthlyPassiveIncome: $currentMonthlyPassiveIncome, ')
          ..write('currentLiquidNetWorth: $currentLiquidNetWorth, ')
          ..write('targetDate: $targetDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RemindersTable extends Reminders
    with TableInfo<$RemindersTable, Reminder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RemindersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _messageMeta =
      const VerificationMeta('message');
  @override
  late final GeneratedColumn<String> message = GeneratedColumn<String>(
      'message', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('custom'));
  static const VerificationMeta _hourMeta = const VerificationMeta('hour');
  @override
  late final GeneratedColumn<int> hour = GeneratedColumn<int>(
      'hour', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _minuteMeta = const VerificationMeta('minute');
  @override
  late final GeneratedColumn<int> minute = GeneratedColumn<int>(
      'minute', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _enabledMeta =
      const VerificationMeta('enabled');
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
      'enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("enabled" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _notificationIdMeta =
      const VerificationMeta('notificationId');
  @override
  late final GeneratedColumn<int> notificationId = GeneratedColumn<int>(
      'notification_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        title,
        message,
        type,
        hour,
        minute,
        enabled,
        notificationId,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reminders';
  @override
  VerificationContext validateIntegrity(Insertable<Reminder> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('message')) {
      context.handle(_messageMeta,
          message.isAcceptableOrUnknown(data['message']!, _messageMeta));
    } else if (isInserting) {
      context.missing(_messageMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    }
    if (data.containsKey('hour')) {
      context.handle(
          _hourMeta, hour.isAcceptableOrUnknown(data['hour']!, _hourMeta));
    } else if (isInserting) {
      context.missing(_hourMeta);
    }
    if (data.containsKey('minute')) {
      context.handle(_minuteMeta,
          minute.isAcceptableOrUnknown(data['minute']!, _minuteMeta));
    } else if (isInserting) {
      context.missing(_minuteMeta);
    }
    if (data.containsKey('enabled')) {
      context.handle(_enabledMeta,
          enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta));
    }
    if (data.containsKey('notification_id')) {
      context.handle(
          _notificationIdMeta,
          notificationId.isAcceptableOrUnknown(
              data['notification_id']!, _notificationIdMeta));
    } else if (isInserting) {
      context.missing(_notificationIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Reminder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Reminder(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      message: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}message'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      hour: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}hour'])!,
      minute: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}minute'])!,
      enabled: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}enabled'])!,
      notificationId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}notification_id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $RemindersTable createAlias(String alias) {
    return $RemindersTable(attachedDatabase, alias);
  }
}

class Reminder extends DataClass implements Insertable<Reminder> {
  final String id;
  final String title;
  final String message;
  final String type;
  final int hour;
  final int minute;
  final bool enabled;
  final int notificationId;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Reminder(
      {required this.id,
      required this.title,
      required this.message,
      required this.type,
      required this.hour,
      required this.minute,
      required this.enabled,
      required this.notificationId,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['message'] = Variable<String>(message);
    map['type'] = Variable<String>(type);
    map['hour'] = Variable<int>(hour);
    map['minute'] = Variable<int>(minute);
    map['enabled'] = Variable<bool>(enabled);
    map['notification_id'] = Variable<int>(notificationId);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  RemindersCompanion toCompanion(bool nullToAbsent) {
    return RemindersCompanion(
      id: Value(id),
      title: Value(title),
      message: Value(message),
      type: Value(type),
      hour: Value(hour),
      minute: Value(minute),
      enabled: Value(enabled),
      notificationId: Value(notificationId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Reminder.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Reminder(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      message: serializer.fromJson<String>(json['message']),
      type: serializer.fromJson<String>(json['type']),
      hour: serializer.fromJson<int>(json['hour']),
      minute: serializer.fromJson<int>(json['minute']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      notificationId: serializer.fromJson<int>(json['notificationId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'message': serializer.toJson<String>(message),
      'type': serializer.toJson<String>(type),
      'hour': serializer.toJson<int>(hour),
      'minute': serializer.toJson<int>(minute),
      'enabled': serializer.toJson<bool>(enabled),
      'notificationId': serializer.toJson<int>(notificationId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Reminder copyWith(
          {String? id,
          String? title,
          String? message,
          String? type,
          int? hour,
          int? minute,
          bool? enabled,
          int? notificationId,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Reminder(
        id: id ?? this.id,
        title: title ?? this.title,
        message: message ?? this.message,
        type: type ?? this.type,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
        enabled: enabled ?? this.enabled,
        notificationId: notificationId ?? this.notificationId,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Reminder copyWithCompanion(RemindersCompanion data) {
    return Reminder(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      message: data.message.present ? data.message.value : this.message,
      type: data.type.present ? data.type.value : this.type,
      hour: data.hour.present ? data.hour.value : this.hour,
      minute: data.minute.present ? data.minute.value : this.minute,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      notificationId: data.notificationId.present
          ? data.notificationId.value
          : this.notificationId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Reminder(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('message: $message, ')
          ..write('type: $type, ')
          ..write('hour: $hour, ')
          ..write('minute: $minute, ')
          ..write('enabled: $enabled, ')
          ..write('notificationId: $notificationId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, message, type, hour, minute,
      enabled, notificationId, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Reminder &&
          other.id == this.id &&
          other.title == this.title &&
          other.message == this.message &&
          other.type == this.type &&
          other.hour == this.hour &&
          other.minute == this.minute &&
          other.enabled == this.enabled &&
          other.notificationId == this.notificationId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class RemindersCompanion extends UpdateCompanion<Reminder> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> message;
  final Value<String> type;
  final Value<int> hour;
  final Value<int> minute;
  final Value<bool> enabled;
  final Value<int> notificationId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const RemindersCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.message = const Value.absent(),
    this.type = const Value.absent(),
    this.hour = const Value.absent(),
    this.minute = const Value.absent(),
    this.enabled = const Value.absent(),
    this.notificationId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RemindersCompanion.insert({
    required String id,
    required String title,
    required String message,
    this.type = const Value.absent(),
    required int hour,
    required int minute,
    this.enabled = const Value.absent(),
    required int notificationId,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        title = Value(title),
        message = Value(message),
        hour = Value(hour),
        minute = Value(minute),
        notificationId = Value(notificationId),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Reminder> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? message,
    Expression<String>? type,
    Expression<int>? hour,
    Expression<int>? minute,
    Expression<bool>? enabled,
    Expression<int>? notificationId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (message != null) 'message': message,
      if (type != null) 'type': type,
      if (hour != null) 'hour': hour,
      if (minute != null) 'minute': minute,
      if (enabled != null) 'enabled': enabled,
      if (notificationId != null) 'notification_id': notificationId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RemindersCompanion copyWith(
      {Value<String>? id,
      Value<String>? title,
      Value<String>? message,
      Value<String>? type,
      Value<int>? hour,
      Value<int>? minute,
      Value<bool>? enabled,
      Value<int>? notificationId,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return RemindersCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      enabled: enabled ?? this.enabled,
      notificationId: notificationId ?? this.notificationId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (hour.present) {
      map['hour'] = Variable<int>(hour.value);
    }
    if (minute.present) {
      map['minute'] = Variable<int>(minute.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (notificationId.present) {
      map['notification_id'] = Variable<int>(notificationId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RemindersCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('message: $message, ')
          ..write('type: $type, ')
          ..write('hour: $hour, ')
          ..write('minute: $minute, ')
          ..write('enabled: $enabled, ')
          ..write('notificationId: $notificationId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $IdentityStatementsTable extends IdentityStatements
    with TableInfo<$IdentityStatementsTable, IdentityStatement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IdentityStatementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [id, content, sortOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'identity_statements';
  @override
  VerificationContext validateIntegrity(Insertable<IdentityStatement> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  IdentityStatement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IdentityStatement(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
    );
  }

  @override
  $IdentityStatementsTable createAlias(String alias) {
    return $IdentityStatementsTable(attachedDatabase, alias);
  }
}

class IdentityStatement extends DataClass
    implements Insertable<IdentityStatement> {
  final String id;
  final String content;
  final int sortOrder;
  const IdentityStatement(
      {required this.id, required this.content, required this.sortOrder});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['content'] = Variable<String>(content);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  IdentityStatementsCompanion toCompanion(bool nullToAbsent) {
    return IdentityStatementsCompanion(
      id: Value(id),
      content: Value(content),
      sortOrder: Value(sortOrder),
    );
  }

  factory IdentityStatement.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IdentityStatement(
      id: serializer.fromJson<String>(json['id']),
      content: serializer.fromJson<String>(json['content']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'content': serializer.toJson<String>(content),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  IdentityStatement copyWith({String? id, String? content, int? sortOrder}) =>
      IdentityStatement(
        id: id ?? this.id,
        content: content ?? this.content,
        sortOrder: sortOrder ?? this.sortOrder,
      );
  IdentityStatement copyWithCompanion(IdentityStatementsCompanion data) {
    return IdentityStatement(
      id: data.id.present ? data.id.value : this.id,
      content: data.content.present ? data.content.value : this.content,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IdentityStatement(')
          ..write('id: $id, ')
          ..write('content: $content, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, content, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IdentityStatement &&
          other.id == this.id &&
          other.content == this.content &&
          other.sortOrder == this.sortOrder);
}

class IdentityStatementsCompanion extends UpdateCompanion<IdentityStatement> {
  final Value<String> id;
  final Value<String> content;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const IdentityStatementsCompanion({
    this.id = const Value.absent(),
    this.content = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IdentityStatementsCompanion.insert({
    required String id,
    required String content,
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        content = Value(content);
  static Insertable<IdentityStatement> custom({
    Expression<String>? id,
    Expression<String>? content,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (content != null) 'content': content,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IdentityStatementsCompanion copyWith(
      {Value<String>? id,
      Value<String>? content,
      Value<int>? sortOrder,
      Value<int>? rowid}) {
    return IdentityStatementsCompanion(
      id: id ?? this.id,
      content: content ?? this.content,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IdentityStatementsCompanion(')
          ..write('id: $id, ')
          ..write('content: $content, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsEntriesTable extends SettingsEntries
    with TableInfo<$SettingsEntriesTable, SettingsEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings_entries';
  @override
  VerificationContext validateIntegrity(Insertable<SettingsEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingsEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingsEntry(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $SettingsEntriesTable createAlias(String alias) {
    return $SettingsEntriesTable(attachedDatabase, alias);
  }
}

class SettingsEntry extends DataClass implements Insertable<SettingsEntry> {
  final String key;
  final String value;
  const SettingsEntry({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsEntriesCompanion toCompanion(bool nullToAbsent) {
    return SettingsEntriesCompanion(
      key: Value(key),
      value: Value(value),
    );
  }

  factory SettingsEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingsEntry(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SettingsEntry copyWith({String? key, String? value}) => SettingsEntry(
        key: key ?? this.key,
        value: value ?? this.value,
      );
  SettingsEntry copyWithCompanion(SettingsEntriesCompanion data) {
    return SettingsEntry(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingsEntry(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingsEntry &&
          other.key == this.key &&
          other.value == this.value);
}

class SettingsEntriesCompanion extends UpdateCompanion<SettingsEntry> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsEntriesCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsEntriesCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        value = Value(value);
  static Insertable<SettingsEntry> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsEntriesCompanion copyWith(
      {Value<String>? key, Value<String>? value, Value<int>? rowid}) {
    return SettingsEntriesCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsEntriesCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $GrowthMetricsTable growthMetrics = $GrowthMetricsTable(this);
  late final $GrowthMetricEntriesTable growthMetricEntries =
      $GrowthMetricEntriesTable(this);
  late final $DailyExperimentsTable dailyExperiments =
      $DailyExperimentsTable(this);
  late final $BudgetCategoriesTable budgetCategories =
      $BudgetCategoriesTable(this);
  late final $TransactionEntriesTable transactionEntries =
      $TransactionEntriesTable(this);
  late final $TimeBudgetsTable timeBudgets = $TimeBudgetsTable(this);
  late final $TimeBlocksTable timeBlocks = $TimeBlocksTable(this);
  late final $CountdownsTable countdowns = $CountdownsTable(this);
  late final $HabitsTable habits = $HabitsTable(this);
  late final $HabitLogsTable habitLogs = $HabitLogsTable(this);
  late final $ParkedIdeasTable parkedIdeas = $ParkedIdeasTable(this);
  late final $GoalsTable goals = $GoalsTable(this);
  late final $FreedomTargetsTable freedomTargets = $FreedomTargetsTable(this);
  late final $RemindersTable reminders = $RemindersTable(this);
  late final $IdentityStatementsTable identityStatements =
      $IdentityStatementsTable(this);
  late final $SettingsEntriesTable settingsEntries =
      $SettingsEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        growthMetrics,
        growthMetricEntries,
        dailyExperiments,
        budgetCategories,
        transactionEntries,
        timeBudgets,
        timeBlocks,
        countdowns,
        habits,
        habitLogs,
        parkedIdeas,
        goals,
        freedomTargets,
        reminders,
        identityStatements,
        settingsEntries
      ];
}

typedef $$GrowthMetricsTableCreateCompanionBuilder = GrowthMetricsCompanion
    Function({
  required String id,
  required String name,
  required String unit,
  Value<double> currentValue,
  Value<double> weeklyTarget,
  Value<bool> isActive,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$GrowthMetricsTableUpdateCompanionBuilder = GrowthMetricsCompanion
    Function({
  Value<String> id,
  Value<String> name,
  Value<String> unit,
  Value<double> currentValue,
  Value<double> weeklyTarget,
  Value<bool> isActive,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$GrowthMetricsTableFilterComposer
    extends Composer<_$AppDatabase, $GrowthMetricsTable> {
  $$GrowthMetricsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get currentValue => $composableBuilder(
      column: $table.currentValue, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get weeklyTarget => $composableBuilder(
      column: $table.weeklyTarget, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$GrowthMetricsTableOrderingComposer
    extends Composer<_$AppDatabase, $GrowthMetricsTable> {
  $$GrowthMetricsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get currentValue => $composableBuilder(
      column: $table.currentValue,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get weeklyTarget => $composableBuilder(
      column: $table.weeklyTarget,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$GrowthMetricsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GrowthMetricsTable> {
  $$GrowthMetricsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<double> get currentValue => $composableBuilder(
      column: $table.currentValue, builder: (column) => column);

  GeneratedColumn<double> get weeklyTarget => $composableBuilder(
      column: $table.weeklyTarget, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$GrowthMetricsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $GrowthMetricsTable,
    GrowthMetric,
    $$GrowthMetricsTableFilterComposer,
    $$GrowthMetricsTableOrderingComposer,
    $$GrowthMetricsTableAnnotationComposer,
    $$GrowthMetricsTableCreateCompanionBuilder,
    $$GrowthMetricsTableUpdateCompanionBuilder,
    (
      GrowthMetric,
      BaseReferences<_$AppDatabase, $GrowthMetricsTable, GrowthMetric>
    ),
    GrowthMetric,
    PrefetchHooks Function()> {
  $$GrowthMetricsTableTableManager(_$AppDatabase db, $GrowthMetricsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GrowthMetricsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GrowthMetricsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GrowthMetricsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> unit = const Value.absent(),
            Value<double> currentValue = const Value.absent(),
            Value<double> weeklyTarget = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GrowthMetricsCompanion(
            id: id,
            name: name,
            unit: unit,
            currentValue: currentValue,
            weeklyTarget: weeklyTarget,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String unit,
            Value<double> currentValue = const Value.absent(),
            Value<double> weeklyTarget = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              GrowthMetricsCompanion.insert(
            id: id,
            name: name,
            unit: unit,
            currentValue: currentValue,
            weeklyTarget: weeklyTarget,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$GrowthMetricsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $GrowthMetricsTable,
    GrowthMetric,
    $$GrowthMetricsTableFilterComposer,
    $$GrowthMetricsTableOrderingComposer,
    $$GrowthMetricsTableAnnotationComposer,
    $$GrowthMetricsTableCreateCompanionBuilder,
    $$GrowthMetricsTableUpdateCompanionBuilder,
    (
      GrowthMetric,
      BaseReferences<_$AppDatabase, $GrowthMetricsTable, GrowthMetric>
    ),
    GrowthMetric,
    PrefetchHooks Function()>;
typedef $$GrowthMetricEntriesTableCreateCompanionBuilder
    = GrowthMetricEntriesCompanion Function({
  required String id,
  required String metricId,
  required String date,
  required double value,
  Value<String?> note,
  Value<int> rowid,
});
typedef $$GrowthMetricEntriesTableUpdateCompanionBuilder
    = GrowthMetricEntriesCompanion Function({
  Value<String> id,
  Value<String> metricId,
  Value<String> date,
  Value<double> value,
  Value<String?> note,
  Value<int> rowid,
});

class $$GrowthMetricEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $GrowthMetricEntriesTable> {
  $$GrowthMetricEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get metricId => $composableBuilder(
      column: $table.metricId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));
}

class $$GrowthMetricEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $GrowthMetricEntriesTable> {
  $$GrowthMetricEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get metricId => $composableBuilder(
      column: $table.metricId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));
}

class $$GrowthMetricEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $GrowthMetricEntriesTable> {
  $$GrowthMetricEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get metricId =>
      $composableBuilder(column: $table.metricId, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<double> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);
}

class $$GrowthMetricEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $GrowthMetricEntriesTable,
    GrowthMetricEntry,
    $$GrowthMetricEntriesTableFilterComposer,
    $$GrowthMetricEntriesTableOrderingComposer,
    $$GrowthMetricEntriesTableAnnotationComposer,
    $$GrowthMetricEntriesTableCreateCompanionBuilder,
    $$GrowthMetricEntriesTableUpdateCompanionBuilder,
    (
      GrowthMetricEntry,
      BaseReferences<_$AppDatabase, $GrowthMetricEntriesTable,
          GrowthMetricEntry>
    ),
    GrowthMetricEntry,
    PrefetchHooks Function()> {
  $$GrowthMetricEntriesTableTableManager(
      _$AppDatabase db, $GrowthMetricEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GrowthMetricEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GrowthMetricEntriesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GrowthMetricEntriesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> metricId = const Value.absent(),
            Value<String> date = const Value.absent(),
            Value<double> value = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GrowthMetricEntriesCompanion(
            id: id,
            metricId: metricId,
            date: date,
            value: value,
            note: note,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String metricId,
            required String date,
            required double value,
            Value<String?> note = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GrowthMetricEntriesCompanion.insert(
            id: id,
            metricId: metricId,
            date: date,
            value: value,
            note: note,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$GrowthMetricEntriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $GrowthMetricEntriesTable,
    GrowthMetricEntry,
    $$GrowthMetricEntriesTableFilterComposer,
    $$GrowthMetricEntriesTableOrderingComposer,
    $$GrowthMetricEntriesTableAnnotationComposer,
    $$GrowthMetricEntriesTableCreateCompanionBuilder,
    $$GrowthMetricEntriesTableUpdateCompanionBuilder,
    (
      GrowthMetricEntry,
      BaseReferences<_$AppDatabase, $GrowthMetricEntriesTable,
          GrowthMetricEntry>
    ),
    GrowthMetricEntry,
    PrefetchHooks Function()>;
typedef $$DailyExperimentsTableCreateCompanionBuilder
    = DailyExperimentsCompanion Function({
  required String id,
  required String date,
  required String hypothesis,
  required String actionTaken,
  required String result,
  required String verdict,
  Value<String?> notes,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$DailyExperimentsTableUpdateCompanionBuilder
    = DailyExperimentsCompanion Function({
  Value<String> id,
  Value<String> date,
  Value<String> hypothesis,
  Value<String> actionTaken,
  Value<String> result,
  Value<String> verdict,
  Value<String?> notes,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$DailyExperimentsTableFilterComposer
    extends Composer<_$AppDatabase, $DailyExperimentsTable> {
  $$DailyExperimentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get hypothesis => $composableBuilder(
      column: $table.hypothesis, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get actionTaken => $composableBuilder(
      column: $table.actionTaken, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get result => $composableBuilder(
      column: $table.result, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get verdict => $composableBuilder(
      column: $table.verdict, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$DailyExperimentsTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyExperimentsTable> {
  $$DailyExperimentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get hypothesis => $composableBuilder(
      column: $table.hypothesis, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get actionTaken => $composableBuilder(
      column: $table.actionTaken, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get result => $composableBuilder(
      column: $table.result, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get verdict => $composableBuilder(
      column: $table.verdict, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$DailyExperimentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyExperimentsTable> {
  $$DailyExperimentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get hypothesis => $composableBuilder(
      column: $table.hypothesis, builder: (column) => column);

  GeneratedColumn<String> get actionTaken => $composableBuilder(
      column: $table.actionTaken, builder: (column) => column);

  GeneratedColumn<String> get result =>
      $composableBuilder(column: $table.result, builder: (column) => column);

  GeneratedColumn<String> get verdict =>
      $composableBuilder(column: $table.verdict, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DailyExperimentsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DailyExperimentsTable,
    DailyExperiment,
    $$DailyExperimentsTableFilterComposer,
    $$DailyExperimentsTableOrderingComposer,
    $$DailyExperimentsTableAnnotationComposer,
    $$DailyExperimentsTableCreateCompanionBuilder,
    $$DailyExperimentsTableUpdateCompanionBuilder,
    (
      DailyExperiment,
      BaseReferences<_$AppDatabase, $DailyExperimentsTable, DailyExperiment>
    ),
    DailyExperiment,
    PrefetchHooks Function()> {
  $$DailyExperimentsTableTableManager(
      _$AppDatabase db, $DailyExperimentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyExperimentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyExperimentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyExperimentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> date = const Value.absent(),
            Value<String> hypothesis = const Value.absent(),
            Value<String> actionTaken = const Value.absent(),
            Value<String> result = const Value.absent(),
            Value<String> verdict = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DailyExperimentsCompanion(
            id: id,
            date: date,
            hypothesis: hypothesis,
            actionTaken: actionTaken,
            result: result,
            verdict: verdict,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String date,
            required String hypothesis,
            required String actionTaken,
            required String result,
            required String verdict,
            Value<String?> notes = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              DailyExperimentsCompanion.insert(
            id: id,
            date: date,
            hypothesis: hypothesis,
            actionTaken: actionTaken,
            result: result,
            verdict: verdict,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DailyExperimentsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DailyExperimentsTable,
    DailyExperiment,
    $$DailyExperimentsTableFilterComposer,
    $$DailyExperimentsTableOrderingComposer,
    $$DailyExperimentsTableAnnotationComposer,
    $$DailyExperimentsTableCreateCompanionBuilder,
    $$DailyExperimentsTableUpdateCompanionBuilder,
    (
      DailyExperiment,
      BaseReferences<_$AppDatabase, $DailyExperimentsTable, DailyExperiment>
    ),
    DailyExperiment,
    PrefetchHooks Function()>;
typedef $$BudgetCategoriesTableCreateCompanionBuilder
    = BudgetCategoriesCompanion Function({
  required String id,
  required String name,
  Value<double> monthlyTarget,
  Value<String> flagType,
  Value<int> sortOrder,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$BudgetCategoriesTableUpdateCompanionBuilder
    = BudgetCategoriesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<double> monthlyTarget,
  Value<String> flagType,
  Value<int> sortOrder,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$BudgetCategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $BudgetCategoriesTable> {
  $$BudgetCategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get monthlyTarget => $composableBuilder(
      column: $table.monthlyTarget, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get flagType => $composableBuilder(
      column: $table.flagType, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$BudgetCategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $BudgetCategoriesTable> {
  $$BudgetCategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get monthlyTarget => $composableBuilder(
      column: $table.monthlyTarget,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get flagType => $composableBuilder(
      column: $table.flagType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$BudgetCategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BudgetCategoriesTable> {
  $$BudgetCategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get monthlyTarget => $composableBuilder(
      column: $table.monthlyTarget, builder: (column) => column);

  GeneratedColumn<String> get flagType =>
      $composableBuilder(column: $table.flagType, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$BudgetCategoriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BudgetCategoriesTable,
    BudgetCategory,
    $$BudgetCategoriesTableFilterComposer,
    $$BudgetCategoriesTableOrderingComposer,
    $$BudgetCategoriesTableAnnotationComposer,
    $$BudgetCategoriesTableCreateCompanionBuilder,
    $$BudgetCategoriesTableUpdateCompanionBuilder,
    (
      BudgetCategory,
      BaseReferences<_$AppDatabase, $BudgetCategoriesTable, BudgetCategory>
    ),
    BudgetCategory,
    PrefetchHooks Function()> {
  $$BudgetCategoriesTableTableManager(
      _$AppDatabase db, $BudgetCategoriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BudgetCategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BudgetCategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BudgetCategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<double> monthlyTarget = const Value.absent(),
            Value<String> flagType = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BudgetCategoriesCompanion(
            id: id,
            name: name,
            monthlyTarget: monthlyTarget,
            flagType: flagType,
            sortOrder: sortOrder,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<double> monthlyTarget = const Value.absent(),
            Value<String> flagType = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              BudgetCategoriesCompanion.insert(
            id: id,
            name: name,
            monthlyTarget: monthlyTarget,
            flagType: flagType,
            sortOrder: sortOrder,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$BudgetCategoriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $BudgetCategoriesTable,
    BudgetCategory,
    $$BudgetCategoriesTableFilterComposer,
    $$BudgetCategoriesTableOrderingComposer,
    $$BudgetCategoriesTableAnnotationComposer,
    $$BudgetCategoriesTableCreateCompanionBuilder,
    $$BudgetCategoriesTableUpdateCompanionBuilder,
    (
      BudgetCategory,
      BaseReferences<_$AppDatabase, $BudgetCategoriesTable, BudgetCategory>
    ),
    BudgetCategory,
    PrefetchHooks Function()>;
typedef $$TransactionEntriesTableCreateCompanionBuilder
    = TransactionEntriesCompanion Function({
  required String id,
  Value<String?> categoryId,
  required String date,
  required double amount,
  Value<String> description,
  Value<bool> isIntentional,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$TransactionEntriesTableUpdateCompanionBuilder
    = TransactionEntriesCompanion Function({
  Value<String> id,
  Value<String?> categoryId,
  Value<String> date,
  Value<double> amount,
  Value<String> description,
  Value<bool> isIntentional,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$TransactionEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionEntriesTable> {
  $$TransactionEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isIntentional => $composableBuilder(
      column: $table.isIntentional, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$TransactionEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionEntriesTable> {
  $$TransactionEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isIntentional => $composableBuilder(
      column: $table.isIntentional,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$TransactionEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionEntriesTable> {
  $$TransactionEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<bool> get isIntentional => $composableBuilder(
      column: $table.isIntentional, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$TransactionEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TransactionEntriesTable,
    TransactionEntry,
    $$TransactionEntriesTableFilterComposer,
    $$TransactionEntriesTableOrderingComposer,
    $$TransactionEntriesTableAnnotationComposer,
    $$TransactionEntriesTableCreateCompanionBuilder,
    $$TransactionEntriesTableUpdateCompanionBuilder,
    (
      TransactionEntry,
      BaseReferences<_$AppDatabase, $TransactionEntriesTable, TransactionEntry>
    ),
    TransactionEntry,
    PrefetchHooks Function()> {
  $$TransactionEntriesTableTableManager(
      _$AppDatabase db, $TransactionEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionEntriesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String?> categoryId = const Value.absent(),
            Value<String> date = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<bool> isIntentional = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TransactionEntriesCompanion(
            id: id,
            categoryId: categoryId,
            date: date,
            amount: amount,
            description: description,
            isIntentional: isIntentional,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String?> categoryId = const Value.absent(),
            required String date,
            required double amount,
            Value<String> description = const Value.absent(),
            Value<bool> isIntentional = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              TransactionEntriesCompanion.insert(
            id: id,
            categoryId: categoryId,
            date: date,
            amount: amount,
            description: description,
            isIntentional: isIntentional,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TransactionEntriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TransactionEntriesTable,
    TransactionEntry,
    $$TransactionEntriesTableFilterComposer,
    $$TransactionEntriesTableOrderingComposer,
    $$TransactionEntriesTableAnnotationComposer,
    $$TransactionEntriesTableCreateCompanionBuilder,
    $$TransactionEntriesTableUpdateCompanionBuilder,
    (
      TransactionEntry,
      BaseReferences<_$AppDatabase, $TransactionEntriesTable, TransactionEntry>
    ),
    TransactionEntry,
    PrefetchHooks Function()>;
typedef $$TimeBudgetsTableCreateCompanionBuilder = TimeBudgetsCompanion
    Function({
  required String id,
  required String name,
  Value<String> kind,
  Value<double> weeklyTargetHours,
  Value<int> sortOrder,
  Value<int> rowid,
});
typedef $$TimeBudgetsTableUpdateCompanionBuilder = TimeBudgetsCompanion
    Function({
  Value<String> id,
  Value<String> name,
  Value<String> kind,
  Value<double> weeklyTargetHours,
  Value<int> sortOrder,
  Value<int> rowid,
});

class $$TimeBudgetsTableFilterComposer
    extends Composer<_$AppDatabase, $TimeBudgetsTable> {
  $$TimeBudgetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get weeklyTargetHours => $composableBuilder(
      column: $table.weeklyTargetHours,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));
}

class $$TimeBudgetsTableOrderingComposer
    extends Composer<_$AppDatabase, $TimeBudgetsTable> {
  $$TimeBudgetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get weeklyTargetHours => $composableBuilder(
      column: $table.weeklyTargetHours,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));
}

class $$TimeBudgetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TimeBudgetsTable> {
  $$TimeBudgetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<double> get weeklyTargetHours => $composableBuilder(
      column: $table.weeklyTargetHours, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$TimeBudgetsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TimeBudgetsTable,
    TimeBudget,
    $$TimeBudgetsTableFilterComposer,
    $$TimeBudgetsTableOrderingComposer,
    $$TimeBudgetsTableAnnotationComposer,
    $$TimeBudgetsTableCreateCompanionBuilder,
    $$TimeBudgetsTableUpdateCompanionBuilder,
    (TimeBudget, BaseReferences<_$AppDatabase, $TimeBudgetsTable, TimeBudget>),
    TimeBudget,
    PrefetchHooks Function()> {
  $$TimeBudgetsTableTableManager(_$AppDatabase db, $TimeBudgetsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TimeBudgetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TimeBudgetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TimeBudgetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> kind = const Value.absent(),
            Value<double> weeklyTargetHours = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TimeBudgetsCompanion(
            id: id,
            name: name,
            kind: kind,
            weeklyTargetHours: weeklyTargetHours,
            sortOrder: sortOrder,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<String> kind = const Value.absent(),
            Value<double> weeklyTargetHours = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TimeBudgetsCompanion.insert(
            id: id,
            name: name,
            kind: kind,
            weeklyTargetHours: weeklyTargetHours,
            sortOrder: sortOrder,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TimeBudgetsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TimeBudgetsTable,
    TimeBudget,
    $$TimeBudgetsTableFilterComposer,
    $$TimeBudgetsTableOrderingComposer,
    $$TimeBudgetsTableAnnotationComposer,
    $$TimeBudgetsTableCreateCompanionBuilder,
    $$TimeBudgetsTableUpdateCompanionBuilder,
    (TimeBudget, BaseReferences<_$AppDatabase, $TimeBudgetsTable, TimeBudget>),
    TimeBudget,
    PrefetchHooks Function()>;
typedef $$TimeBlocksTableCreateCompanionBuilder = TimeBlocksCompanion Function({
  required String id,
  required String budgetId,
  required String date,
  required double hours,
  Value<String?> note,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$TimeBlocksTableUpdateCompanionBuilder = TimeBlocksCompanion Function({
  Value<String> id,
  Value<String> budgetId,
  Value<String> date,
  Value<double> hours,
  Value<String?> note,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$TimeBlocksTableFilterComposer
    extends Composer<_$AppDatabase, $TimeBlocksTable> {
  $$TimeBlocksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get budgetId => $composableBuilder(
      column: $table.budgetId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get hours => $composableBuilder(
      column: $table.hours, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$TimeBlocksTableOrderingComposer
    extends Composer<_$AppDatabase, $TimeBlocksTable> {
  $$TimeBlocksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get budgetId => $composableBuilder(
      column: $table.budgetId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get hours => $composableBuilder(
      column: $table.hours, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$TimeBlocksTableAnnotationComposer
    extends Composer<_$AppDatabase, $TimeBlocksTable> {
  $$TimeBlocksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get budgetId =>
      $composableBuilder(column: $table.budgetId, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<double> get hours =>
      $composableBuilder(column: $table.hours, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$TimeBlocksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TimeBlocksTable,
    TimeBlock,
    $$TimeBlocksTableFilterComposer,
    $$TimeBlocksTableOrderingComposer,
    $$TimeBlocksTableAnnotationComposer,
    $$TimeBlocksTableCreateCompanionBuilder,
    $$TimeBlocksTableUpdateCompanionBuilder,
    (TimeBlock, BaseReferences<_$AppDatabase, $TimeBlocksTable, TimeBlock>),
    TimeBlock,
    PrefetchHooks Function()> {
  $$TimeBlocksTableTableManager(_$AppDatabase db, $TimeBlocksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TimeBlocksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TimeBlocksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TimeBlocksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> budgetId = const Value.absent(),
            Value<String> date = const Value.absent(),
            Value<double> hours = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TimeBlocksCompanion(
            id: id,
            budgetId: budgetId,
            date: date,
            hours: hours,
            note: note,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String budgetId,
            required String date,
            required double hours,
            Value<String?> note = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              TimeBlocksCompanion.insert(
            id: id,
            budgetId: budgetId,
            date: date,
            hours: hours,
            note: note,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TimeBlocksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TimeBlocksTable,
    TimeBlock,
    $$TimeBlocksTableFilterComposer,
    $$TimeBlocksTableOrderingComposer,
    $$TimeBlocksTableAnnotationComposer,
    $$TimeBlocksTableCreateCompanionBuilder,
    $$TimeBlocksTableUpdateCompanionBuilder,
    (TimeBlock, BaseReferences<_$AppDatabase, $TimeBlocksTable, TimeBlock>),
    TimeBlock,
    PrefetchHooks Function()>;
typedef $$CountdownsTableCreateCompanionBuilder = CountdownsCompanion Function({
  required String id,
  required String title,
  Value<String?> targetDate,
  Value<String?> dynamicKey,
  Value<int> sortOrder,
  Value<int> rowid,
});
typedef $$CountdownsTableUpdateCompanionBuilder = CountdownsCompanion Function({
  Value<String> id,
  Value<String> title,
  Value<String?> targetDate,
  Value<String?> dynamicKey,
  Value<int> sortOrder,
  Value<int> rowid,
});

class $$CountdownsTableFilterComposer
    extends Composer<_$AppDatabase, $CountdownsTable> {
  $$CountdownsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get targetDate => $composableBuilder(
      column: $table.targetDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dynamicKey => $composableBuilder(
      column: $table.dynamicKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));
}

class $$CountdownsTableOrderingComposer
    extends Composer<_$AppDatabase, $CountdownsTable> {
  $$CountdownsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get targetDate => $composableBuilder(
      column: $table.targetDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dynamicKey => $composableBuilder(
      column: $table.dynamicKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));
}

class $$CountdownsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CountdownsTable> {
  $$CountdownsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get targetDate => $composableBuilder(
      column: $table.targetDate, builder: (column) => column);

  GeneratedColumn<String> get dynamicKey => $composableBuilder(
      column: $table.dynamicKey, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$CountdownsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CountdownsTable,
    Countdown,
    $$CountdownsTableFilterComposer,
    $$CountdownsTableOrderingComposer,
    $$CountdownsTableAnnotationComposer,
    $$CountdownsTableCreateCompanionBuilder,
    $$CountdownsTableUpdateCompanionBuilder,
    (Countdown, BaseReferences<_$AppDatabase, $CountdownsTable, Countdown>),
    Countdown,
    PrefetchHooks Function()> {
  $$CountdownsTableTableManager(_$AppDatabase db, $CountdownsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CountdownsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CountdownsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CountdownsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> targetDate = const Value.absent(),
            Value<String?> dynamicKey = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CountdownsCompanion(
            id: id,
            title: title,
            targetDate: targetDate,
            dynamicKey: dynamicKey,
            sortOrder: sortOrder,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String title,
            Value<String?> targetDate = const Value.absent(),
            Value<String?> dynamicKey = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CountdownsCompanion.insert(
            id: id,
            title: title,
            targetDate: targetDate,
            dynamicKey: dynamicKey,
            sortOrder: sortOrder,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CountdownsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CountdownsTable,
    Countdown,
    $$CountdownsTableFilterComposer,
    $$CountdownsTableOrderingComposer,
    $$CountdownsTableAnnotationComposer,
    $$CountdownsTableCreateCompanionBuilder,
    $$CountdownsTableUpdateCompanionBuilder,
    (Countdown, BaseReferences<_$AppDatabase, $CountdownsTable, Countdown>),
    Countdown,
    PrefetchHooks Function()>;
typedef $$HabitsTableCreateCompanionBuilder = HabitsCompanion Function({
  required String id,
  required String name,
  Value<String> type,
  Value<String?> unit,
  Value<int> sortOrder,
  Value<bool> isArchived,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$HabitsTableUpdateCompanionBuilder = HabitsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> type,
  Value<String?> unit,
  Value<int> sortOrder,
  Value<bool> isArchived,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$HabitsTableFilterComposer
    extends Composer<_$AppDatabase, $HabitsTable> {
  $$HabitsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$HabitsTableOrderingComposer
    extends Composer<_$AppDatabase, $HabitsTable> {
  $$HabitsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$HabitsTableAnnotationComposer
    extends Composer<_$AppDatabase, $HabitsTable> {
  $$HabitsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$HabitsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $HabitsTable,
    Habit,
    $$HabitsTableFilterComposer,
    $$HabitsTableOrderingComposer,
    $$HabitsTableAnnotationComposer,
    $$HabitsTableCreateCompanionBuilder,
    $$HabitsTableUpdateCompanionBuilder,
    (Habit, BaseReferences<_$AppDatabase, $HabitsTable, Habit>),
    Habit,
    PrefetchHooks Function()> {
  $$HabitsTableTableManager(_$AppDatabase db, $HabitsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HabitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HabitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HabitsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String?> unit = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<bool> isArchived = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              HabitsCompanion(
            id: id,
            name: name,
            type: type,
            unit: unit,
            sortOrder: sortOrder,
            isArchived: isArchived,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<String> type = const Value.absent(),
            Value<String?> unit = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<bool> isArchived = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              HabitsCompanion.insert(
            id: id,
            name: name,
            type: type,
            unit: unit,
            sortOrder: sortOrder,
            isArchived: isArchived,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$HabitsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $HabitsTable,
    Habit,
    $$HabitsTableFilterComposer,
    $$HabitsTableOrderingComposer,
    $$HabitsTableAnnotationComposer,
    $$HabitsTableCreateCompanionBuilder,
    $$HabitsTableUpdateCompanionBuilder,
    (Habit, BaseReferences<_$AppDatabase, $HabitsTable, Habit>),
    Habit,
    PrefetchHooks Function()>;
typedef $$HabitLogsTableCreateCompanionBuilder = HabitLogsCompanion Function({
  required String id,
  required String habitId,
  required String date,
  Value<double> value,
  Value<String?> note,
  Value<int> rowid,
});
typedef $$HabitLogsTableUpdateCompanionBuilder = HabitLogsCompanion Function({
  Value<String> id,
  Value<String> habitId,
  Value<String> date,
  Value<double> value,
  Value<String?> note,
  Value<int> rowid,
});

class $$HabitLogsTableFilterComposer
    extends Composer<_$AppDatabase, $HabitLogsTable> {
  $$HabitLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get habitId => $composableBuilder(
      column: $table.habitId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));
}

class $$HabitLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $HabitLogsTable> {
  $$HabitLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get habitId => $composableBuilder(
      column: $table.habitId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));
}

class $$HabitLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $HabitLogsTable> {
  $$HabitLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get habitId =>
      $composableBuilder(column: $table.habitId, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<double> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);
}

class $$HabitLogsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $HabitLogsTable,
    HabitLog,
    $$HabitLogsTableFilterComposer,
    $$HabitLogsTableOrderingComposer,
    $$HabitLogsTableAnnotationComposer,
    $$HabitLogsTableCreateCompanionBuilder,
    $$HabitLogsTableUpdateCompanionBuilder,
    (HabitLog, BaseReferences<_$AppDatabase, $HabitLogsTable, HabitLog>),
    HabitLog,
    PrefetchHooks Function()> {
  $$HabitLogsTableTableManager(_$AppDatabase db, $HabitLogsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HabitLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HabitLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HabitLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> habitId = const Value.absent(),
            Value<String> date = const Value.absent(),
            Value<double> value = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              HabitLogsCompanion(
            id: id,
            habitId: habitId,
            date: date,
            value: value,
            note: note,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String habitId,
            required String date,
            Value<double> value = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              HabitLogsCompanion.insert(
            id: id,
            habitId: habitId,
            date: date,
            value: value,
            note: note,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$HabitLogsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $HabitLogsTable,
    HabitLog,
    $$HabitLogsTableFilterComposer,
    $$HabitLogsTableOrderingComposer,
    $$HabitLogsTableAnnotationComposer,
    $$HabitLogsTableCreateCompanionBuilder,
    $$HabitLogsTableUpdateCompanionBuilder,
    (HabitLog, BaseReferences<_$AppDatabase, $HabitLogsTable, HabitLog>),
    HabitLog,
    PrefetchHooks Function()>;
typedef $$ParkedIdeasTableCreateCompanionBuilder = ParkedIdeasCompanion
    Function({
  required String id,
  required String title,
  Value<String?> description,
  Value<String?> category,
  Value<String?> whyTempting,
  Value<String?> potentialValue,
  required String dateCaptured,
  required String reviewDate,
  Value<String> decision,
  Value<bool> directlyHelpsKaizenThisWeek,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$ParkedIdeasTableUpdateCompanionBuilder = ParkedIdeasCompanion
    Function({
  Value<String> id,
  Value<String> title,
  Value<String?> description,
  Value<String?> category,
  Value<String?> whyTempting,
  Value<String?> potentialValue,
  Value<String> dateCaptured,
  Value<String> reviewDate,
  Value<String> decision,
  Value<bool> directlyHelpsKaizenThisWeek,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$ParkedIdeasTableFilterComposer
    extends Composer<_$AppDatabase, $ParkedIdeasTable> {
  $$ParkedIdeasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get whyTempting => $composableBuilder(
      column: $table.whyTempting, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get potentialValue => $composableBuilder(
      column: $table.potentialValue,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dateCaptured => $composableBuilder(
      column: $table.dateCaptured, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reviewDate => $composableBuilder(
      column: $table.reviewDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get decision => $composableBuilder(
      column: $table.decision, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get directlyHelpsKaizenThisWeek => $composableBuilder(
      column: $table.directlyHelpsKaizenThisWeek,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$ParkedIdeasTableOrderingComposer
    extends Composer<_$AppDatabase, $ParkedIdeasTable> {
  $$ParkedIdeasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get whyTempting => $composableBuilder(
      column: $table.whyTempting, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get potentialValue => $composableBuilder(
      column: $table.potentialValue,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dateCaptured => $composableBuilder(
      column: $table.dateCaptured,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reviewDate => $composableBuilder(
      column: $table.reviewDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get decision => $composableBuilder(
      column: $table.decision, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get directlyHelpsKaizenThisWeek => $composableBuilder(
      column: $table.directlyHelpsKaizenThisWeek,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$ParkedIdeasTableAnnotationComposer
    extends Composer<_$AppDatabase, $ParkedIdeasTable> {
  $$ParkedIdeasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get whyTempting => $composableBuilder(
      column: $table.whyTempting, builder: (column) => column);

  GeneratedColumn<String> get potentialValue => $composableBuilder(
      column: $table.potentialValue, builder: (column) => column);

  GeneratedColumn<String> get dateCaptured => $composableBuilder(
      column: $table.dateCaptured, builder: (column) => column);

  GeneratedColumn<String> get reviewDate => $composableBuilder(
      column: $table.reviewDate, builder: (column) => column);

  GeneratedColumn<String> get decision =>
      $composableBuilder(column: $table.decision, builder: (column) => column);

  GeneratedColumn<bool> get directlyHelpsKaizenThisWeek => $composableBuilder(
      column: $table.directlyHelpsKaizenThisWeek, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ParkedIdeasTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ParkedIdeasTable,
    ParkedIdea,
    $$ParkedIdeasTableFilterComposer,
    $$ParkedIdeasTableOrderingComposer,
    $$ParkedIdeasTableAnnotationComposer,
    $$ParkedIdeasTableCreateCompanionBuilder,
    $$ParkedIdeasTableUpdateCompanionBuilder,
    (ParkedIdea, BaseReferences<_$AppDatabase, $ParkedIdeasTable, ParkedIdea>),
    ParkedIdea,
    PrefetchHooks Function()> {
  $$ParkedIdeasTableTableManager(_$AppDatabase db, $ParkedIdeasTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ParkedIdeasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ParkedIdeasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ParkedIdeasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String?> category = const Value.absent(),
            Value<String?> whyTempting = const Value.absent(),
            Value<String?> potentialValue = const Value.absent(),
            Value<String> dateCaptured = const Value.absent(),
            Value<String> reviewDate = const Value.absent(),
            Value<String> decision = const Value.absent(),
            Value<bool> directlyHelpsKaizenThisWeek = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ParkedIdeasCompanion(
            id: id,
            title: title,
            description: description,
            category: category,
            whyTempting: whyTempting,
            potentialValue: potentialValue,
            dateCaptured: dateCaptured,
            reviewDate: reviewDate,
            decision: decision,
            directlyHelpsKaizenThisWeek: directlyHelpsKaizenThisWeek,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String title,
            Value<String?> description = const Value.absent(),
            Value<String?> category = const Value.absent(),
            Value<String?> whyTempting = const Value.absent(),
            Value<String?> potentialValue = const Value.absent(),
            required String dateCaptured,
            required String reviewDate,
            Value<String> decision = const Value.absent(),
            Value<bool> directlyHelpsKaizenThisWeek = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              ParkedIdeasCompanion.insert(
            id: id,
            title: title,
            description: description,
            category: category,
            whyTempting: whyTempting,
            potentialValue: potentialValue,
            dateCaptured: dateCaptured,
            reviewDate: reviewDate,
            decision: decision,
            directlyHelpsKaizenThisWeek: directlyHelpsKaizenThisWeek,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ParkedIdeasTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ParkedIdeasTable,
    ParkedIdea,
    $$ParkedIdeasTableFilterComposer,
    $$ParkedIdeasTableOrderingComposer,
    $$ParkedIdeasTableAnnotationComposer,
    $$ParkedIdeasTableCreateCompanionBuilder,
    $$ParkedIdeasTableUpdateCompanionBuilder,
    (ParkedIdea, BaseReferences<_$AppDatabase, $ParkedIdeasTable, ParkedIdea>),
    ParkedIdea,
    PrefetchHooks Function()>;
typedef $$GoalsTableCreateCompanionBuilder = GoalsCompanion Function({
  required String id,
  required String title,
  Value<String?> description,
  Value<String?> metricName,
  Value<double> currentValue,
  Value<double> targetValue,
  Value<String?> targetDate,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$GoalsTableUpdateCompanionBuilder = GoalsCompanion Function({
  Value<String> id,
  Value<String> title,
  Value<String?> description,
  Value<String?> metricName,
  Value<double> currentValue,
  Value<double> targetValue,
  Value<String?> targetDate,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$GoalsTableFilterComposer extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get metricName => $composableBuilder(
      column: $table.metricName, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get currentValue => $composableBuilder(
      column: $table.currentValue, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get targetValue => $composableBuilder(
      column: $table.targetValue, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get targetDate => $composableBuilder(
      column: $table.targetDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$GoalsTableOrderingComposer
    extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get metricName => $composableBuilder(
      column: $table.metricName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get currentValue => $composableBuilder(
      column: $table.currentValue,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get targetValue => $composableBuilder(
      column: $table.targetValue, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get targetDate => $composableBuilder(
      column: $table.targetDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$GoalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get metricName => $composableBuilder(
      column: $table.metricName, builder: (column) => column);

  GeneratedColumn<double> get currentValue => $composableBuilder(
      column: $table.currentValue, builder: (column) => column);

  GeneratedColumn<double> get targetValue => $composableBuilder(
      column: $table.targetValue, builder: (column) => column);

  GeneratedColumn<String> get targetDate => $composableBuilder(
      column: $table.targetDate, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$GoalsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $GoalsTable,
    Goal,
    $$GoalsTableFilterComposer,
    $$GoalsTableOrderingComposer,
    $$GoalsTableAnnotationComposer,
    $$GoalsTableCreateCompanionBuilder,
    $$GoalsTableUpdateCompanionBuilder,
    (Goal, BaseReferences<_$AppDatabase, $GoalsTable, Goal>),
    Goal,
    PrefetchHooks Function()> {
  $$GoalsTableTableManager(_$AppDatabase db, $GoalsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GoalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GoalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GoalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String?> metricName = const Value.absent(),
            Value<double> currentValue = const Value.absent(),
            Value<double> targetValue = const Value.absent(),
            Value<String?> targetDate = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GoalsCompanion(
            id: id,
            title: title,
            description: description,
            metricName: metricName,
            currentValue: currentValue,
            targetValue: targetValue,
            targetDate: targetDate,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String title,
            Value<String?> description = const Value.absent(),
            Value<String?> metricName = const Value.absent(),
            Value<double> currentValue = const Value.absent(),
            Value<double> targetValue = const Value.absent(),
            Value<String?> targetDate = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              GoalsCompanion.insert(
            id: id,
            title: title,
            description: description,
            metricName: metricName,
            currentValue: currentValue,
            targetValue: targetValue,
            targetDate: targetDate,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$GoalsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $GoalsTable,
    Goal,
    $$GoalsTableFilterComposer,
    $$GoalsTableOrderingComposer,
    $$GoalsTableAnnotationComposer,
    $$GoalsTableCreateCompanionBuilder,
    $$GoalsTableUpdateCompanionBuilder,
    (Goal, BaseReferences<_$AppDatabase, $GoalsTable, Goal>),
    Goal,
    PrefetchHooks Function()>;
typedef $$FreedomTargetsTableCreateCompanionBuilder = FreedomTargetsCompanion
    Function({
  required String id,
  required String title,
  Value<String?> description,
  Value<double> targetMonthlyPassiveIncome,
  Value<double> targetLiquidNetWorth,
  Value<double> currentMonthlyPassiveIncome,
  Value<double> currentLiquidNetWorth,
  Value<String?> targetDate,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$FreedomTargetsTableUpdateCompanionBuilder = FreedomTargetsCompanion
    Function({
  Value<String> id,
  Value<String> title,
  Value<String?> description,
  Value<double> targetMonthlyPassiveIncome,
  Value<double> targetLiquidNetWorth,
  Value<double> currentMonthlyPassiveIncome,
  Value<double> currentLiquidNetWorth,
  Value<String?> targetDate,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$FreedomTargetsTableFilterComposer
    extends Composer<_$AppDatabase, $FreedomTargetsTable> {
  $$FreedomTargetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get targetMonthlyPassiveIncome => $composableBuilder(
      column: $table.targetMonthlyPassiveIncome,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get targetLiquidNetWorth => $composableBuilder(
      column: $table.targetLiquidNetWorth,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get currentMonthlyPassiveIncome => $composableBuilder(
      column: $table.currentMonthlyPassiveIncome,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get currentLiquidNetWorth => $composableBuilder(
      column: $table.currentLiquidNetWorth,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get targetDate => $composableBuilder(
      column: $table.targetDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$FreedomTargetsTableOrderingComposer
    extends Composer<_$AppDatabase, $FreedomTargetsTable> {
  $$FreedomTargetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get targetMonthlyPassiveIncome => $composableBuilder(
      column: $table.targetMonthlyPassiveIncome,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get targetLiquidNetWorth => $composableBuilder(
      column: $table.targetLiquidNetWorth,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get currentMonthlyPassiveIncome => $composableBuilder(
      column: $table.currentMonthlyPassiveIncome,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get currentLiquidNetWorth => $composableBuilder(
      column: $table.currentLiquidNetWorth,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get targetDate => $composableBuilder(
      column: $table.targetDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$FreedomTargetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FreedomTargetsTable> {
  $$FreedomTargetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<double> get targetMonthlyPassiveIncome => $composableBuilder(
      column: $table.targetMonthlyPassiveIncome, builder: (column) => column);

  GeneratedColumn<double> get targetLiquidNetWorth => $composableBuilder(
      column: $table.targetLiquidNetWorth, builder: (column) => column);

  GeneratedColumn<double> get currentMonthlyPassiveIncome => $composableBuilder(
      column: $table.currentMonthlyPassiveIncome, builder: (column) => column);

  GeneratedColumn<double> get currentLiquidNetWorth => $composableBuilder(
      column: $table.currentLiquidNetWorth, builder: (column) => column);

  GeneratedColumn<String> get targetDate => $composableBuilder(
      column: $table.targetDate, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$FreedomTargetsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $FreedomTargetsTable,
    FreedomTarget,
    $$FreedomTargetsTableFilterComposer,
    $$FreedomTargetsTableOrderingComposer,
    $$FreedomTargetsTableAnnotationComposer,
    $$FreedomTargetsTableCreateCompanionBuilder,
    $$FreedomTargetsTableUpdateCompanionBuilder,
    (
      FreedomTarget,
      BaseReferences<_$AppDatabase, $FreedomTargetsTable, FreedomTarget>
    ),
    FreedomTarget,
    PrefetchHooks Function()> {
  $$FreedomTargetsTableTableManager(
      _$AppDatabase db, $FreedomTargetsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FreedomTargetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FreedomTargetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FreedomTargetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<double> targetMonthlyPassiveIncome = const Value.absent(),
            Value<double> targetLiquidNetWorth = const Value.absent(),
            Value<double> currentMonthlyPassiveIncome = const Value.absent(),
            Value<double> currentLiquidNetWorth = const Value.absent(),
            Value<String?> targetDate = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FreedomTargetsCompanion(
            id: id,
            title: title,
            description: description,
            targetMonthlyPassiveIncome: targetMonthlyPassiveIncome,
            targetLiquidNetWorth: targetLiquidNetWorth,
            currentMonthlyPassiveIncome: currentMonthlyPassiveIncome,
            currentLiquidNetWorth: currentLiquidNetWorth,
            targetDate: targetDate,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String title,
            Value<String?> description = const Value.absent(),
            Value<double> targetMonthlyPassiveIncome = const Value.absent(),
            Value<double> targetLiquidNetWorth = const Value.absent(),
            Value<double> currentMonthlyPassiveIncome = const Value.absent(),
            Value<double> currentLiquidNetWorth = const Value.absent(),
            Value<String?> targetDate = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              FreedomTargetsCompanion.insert(
            id: id,
            title: title,
            description: description,
            targetMonthlyPassiveIncome: targetMonthlyPassiveIncome,
            targetLiquidNetWorth: targetLiquidNetWorth,
            currentMonthlyPassiveIncome: currentMonthlyPassiveIncome,
            currentLiquidNetWorth: currentLiquidNetWorth,
            targetDate: targetDate,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$FreedomTargetsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $FreedomTargetsTable,
    FreedomTarget,
    $$FreedomTargetsTableFilterComposer,
    $$FreedomTargetsTableOrderingComposer,
    $$FreedomTargetsTableAnnotationComposer,
    $$FreedomTargetsTableCreateCompanionBuilder,
    $$FreedomTargetsTableUpdateCompanionBuilder,
    (
      FreedomTarget,
      BaseReferences<_$AppDatabase, $FreedomTargetsTable, FreedomTarget>
    ),
    FreedomTarget,
    PrefetchHooks Function()>;
typedef $$RemindersTableCreateCompanionBuilder = RemindersCompanion Function({
  required String id,
  required String title,
  required String message,
  Value<String> type,
  required int hour,
  required int minute,
  Value<bool> enabled,
  required int notificationId,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$RemindersTableUpdateCompanionBuilder = RemindersCompanion Function({
  Value<String> id,
  Value<String> title,
  Value<String> message,
  Value<String> type,
  Value<int> hour,
  Value<int> minute,
  Value<bool> enabled,
  Value<int> notificationId,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$RemindersTableFilterComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get message => $composableBuilder(
      column: $table.message, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get hour => $composableBuilder(
      column: $table.hour, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get minute => $composableBuilder(
      column: $table.minute, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get enabled => $composableBuilder(
      column: $table.enabled, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get notificationId => $composableBuilder(
      column: $table.notificationId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$RemindersTableOrderingComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get message => $composableBuilder(
      column: $table.message, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get hour => $composableBuilder(
      column: $table.hour, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get minute => $composableBuilder(
      column: $table.minute, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get enabled => $composableBuilder(
      column: $table.enabled, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get notificationId => $composableBuilder(
      column: $table.notificationId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$RemindersTableAnnotationComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get message =>
      $composableBuilder(column: $table.message, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get hour =>
      $composableBuilder(column: $table.hour, builder: (column) => column);

  GeneratedColumn<int> get minute =>
      $composableBuilder(column: $table.minute, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<int> get notificationId => $composableBuilder(
      column: $table.notificationId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$RemindersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RemindersTable,
    Reminder,
    $$RemindersTableFilterComposer,
    $$RemindersTableOrderingComposer,
    $$RemindersTableAnnotationComposer,
    $$RemindersTableCreateCompanionBuilder,
    $$RemindersTableUpdateCompanionBuilder,
    (Reminder, BaseReferences<_$AppDatabase, $RemindersTable, Reminder>),
    Reminder,
    PrefetchHooks Function()> {
  $$RemindersTableTableManager(_$AppDatabase db, $RemindersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RemindersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RemindersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RemindersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> message = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<int> hour = const Value.absent(),
            Value<int> minute = const Value.absent(),
            Value<bool> enabled = const Value.absent(),
            Value<int> notificationId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RemindersCompanion(
            id: id,
            title: title,
            message: message,
            type: type,
            hour: hour,
            minute: minute,
            enabled: enabled,
            notificationId: notificationId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String title,
            required String message,
            Value<String> type = const Value.absent(),
            required int hour,
            required int minute,
            Value<bool> enabled = const Value.absent(),
            required int notificationId,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              RemindersCompanion.insert(
            id: id,
            title: title,
            message: message,
            type: type,
            hour: hour,
            minute: minute,
            enabled: enabled,
            notificationId: notificationId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$RemindersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RemindersTable,
    Reminder,
    $$RemindersTableFilterComposer,
    $$RemindersTableOrderingComposer,
    $$RemindersTableAnnotationComposer,
    $$RemindersTableCreateCompanionBuilder,
    $$RemindersTableUpdateCompanionBuilder,
    (Reminder, BaseReferences<_$AppDatabase, $RemindersTable, Reminder>),
    Reminder,
    PrefetchHooks Function()>;
typedef $$IdentityStatementsTableCreateCompanionBuilder
    = IdentityStatementsCompanion Function({
  required String id,
  required String content,
  Value<int> sortOrder,
  Value<int> rowid,
});
typedef $$IdentityStatementsTableUpdateCompanionBuilder
    = IdentityStatementsCompanion Function({
  Value<String> id,
  Value<String> content,
  Value<int> sortOrder,
  Value<int> rowid,
});

class $$IdentityStatementsTableFilterComposer
    extends Composer<_$AppDatabase, $IdentityStatementsTable> {
  $$IdentityStatementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));
}

class $$IdentityStatementsTableOrderingComposer
    extends Composer<_$AppDatabase, $IdentityStatementsTable> {
  $$IdentityStatementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));
}

class $$IdentityStatementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $IdentityStatementsTable> {
  $$IdentityStatementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$IdentityStatementsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $IdentityStatementsTable,
    IdentityStatement,
    $$IdentityStatementsTableFilterComposer,
    $$IdentityStatementsTableOrderingComposer,
    $$IdentityStatementsTableAnnotationComposer,
    $$IdentityStatementsTableCreateCompanionBuilder,
    $$IdentityStatementsTableUpdateCompanionBuilder,
    (
      IdentityStatement,
      BaseReferences<_$AppDatabase, $IdentityStatementsTable, IdentityStatement>
    ),
    IdentityStatement,
    PrefetchHooks Function()> {
  $$IdentityStatementsTableTableManager(
      _$AppDatabase db, $IdentityStatementsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IdentityStatementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IdentityStatementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IdentityStatementsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> content = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              IdentityStatementsCompanion(
            id: id,
            content: content,
            sortOrder: sortOrder,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String content,
            Value<int> sortOrder = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              IdentityStatementsCompanion.insert(
            id: id,
            content: content,
            sortOrder: sortOrder,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$IdentityStatementsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $IdentityStatementsTable,
    IdentityStatement,
    $$IdentityStatementsTableFilterComposer,
    $$IdentityStatementsTableOrderingComposer,
    $$IdentityStatementsTableAnnotationComposer,
    $$IdentityStatementsTableCreateCompanionBuilder,
    $$IdentityStatementsTableUpdateCompanionBuilder,
    (
      IdentityStatement,
      BaseReferences<_$AppDatabase, $IdentityStatementsTable, IdentityStatement>
    ),
    IdentityStatement,
    PrefetchHooks Function()>;
typedef $$SettingsEntriesTableCreateCompanionBuilder = SettingsEntriesCompanion
    Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$SettingsEntriesTableUpdateCompanionBuilder = SettingsEntriesCompanion
    Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$SettingsEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsEntriesTable> {
  $$SettingsEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$SettingsEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsEntriesTable> {
  $$SettingsEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$SettingsEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsEntriesTable> {
  $$SettingsEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SettingsEntriesTable,
    SettingsEntry,
    $$SettingsEntriesTableFilterComposer,
    $$SettingsEntriesTableOrderingComposer,
    $$SettingsEntriesTableAnnotationComposer,
    $$SettingsEntriesTableCreateCompanionBuilder,
    $$SettingsEntriesTableUpdateCompanionBuilder,
    (
      SettingsEntry,
      BaseReferences<_$AppDatabase, $SettingsEntriesTable, SettingsEntry>
    ),
    SettingsEntry,
    PrefetchHooks Function()> {
  $$SettingsEntriesTableTableManager(
      _$AppDatabase db, $SettingsEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SettingsEntriesCompanion(
            key: key,
            value: value,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) =>
              SettingsEntriesCompanion.insert(
            key: key,
            value: value,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SettingsEntriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SettingsEntriesTable,
    SettingsEntry,
    $$SettingsEntriesTableFilterComposer,
    $$SettingsEntriesTableOrderingComposer,
    $$SettingsEntriesTableAnnotationComposer,
    $$SettingsEntriesTableCreateCompanionBuilder,
    $$SettingsEntriesTableUpdateCompanionBuilder,
    (
      SettingsEntry,
      BaseReferences<_$AppDatabase, $SettingsEntriesTable, SettingsEntry>
    ),
    SettingsEntry,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$GrowthMetricsTableTableManager get growthMetrics =>
      $$GrowthMetricsTableTableManager(_db, _db.growthMetrics);
  $$GrowthMetricEntriesTableTableManager get growthMetricEntries =>
      $$GrowthMetricEntriesTableTableManager(_db, _db.growthMetricEntries);
  $$DailyExperimentsTableTableManager get dailyExperiments =>
      $$DailyExperimentsTableTableManager(_db, _db.dailyExperiments);
  $$BudgetCategoriesTableTableManager get budgetCategories =>
      $$BudgetCategoriesTableTableManager(_db, _db.budgetCategories);
  $$TransactionEntriesTableTableManager get transactionEntries =>
      $$TransactionEntriesTableTableManager(_db, _db.transactionEntries);
  $$TimeBudgetsTableTableManager get timeBudgets =>
      $$TimeBudgetsTableTableManager(_db, _db.timeBudgets);
  $$TimeBlocksTableTableManager get timeBlocks =>
      $$TimeBlocksTableTableManager(_db, _db.timeBlocks);
  $$CountdownsTableTableManager get countdowns =>
      $$CountdownsTableTableManager(_db, _db.countdowns);
  $$HabitsTableTableManager get habits =>
      $$HabitsTableTableManager(_db, _db.habits);
  $$HabitLogsTableTableManager get habitLogs =>
      $$HabitLogsTableTableManager(_db, _db.habitLogs);
  $$ParkedIdeasTableTableManager get parkedIdeas =>
      $$ParkedIdeasTableTableManager(_db, _db.parkedIdeas);
  $$GoalsTableTableManager get goals =>
      $$GoalsTableTableManager(_db, _db.goals);
  $$FreedomTargetsTableTableManager get freedomTargets =>
      $$FreedomTargetsTableTableManager(_db, _db.freedomTargets);
  $$RemindersTableTableManager get reminders =>
      $$RemindersTableTableManager(_db, _db.reminders);
  $$IdentityStatementsTableTableManager get identityStatements =>
      $$IdentityStatementsTableTableManager(_db, _db.identityStatements);
  $$SettingsEntriesTableTableManager get settingsEntries =>
      $$SettingsEntriesTableTableManager(_db, _db.settingsEntries);
}
