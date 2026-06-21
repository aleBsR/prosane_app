// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SyncStateRowsTable extends SyncStateRows
    with TableInfo<$SyncStateRowsTable, SyncStateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncStateRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _featureMeta = const VerificationMeta(
    'feature',
  );
  @override
  late final GeneratedColumn<String> feature = GeneratedColumn<String>(
    'feature',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [feature, lastSyncedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_state_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncStateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('feature')) {
      context.handle(
        _featureMeta,
        feature.isAcceptableOrUnknown(data['feature']!, _featureMeta),
      );
    } else if (isInserting) {
      context.missing(_featureMeta);
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {feature};
  @override
  SyncStateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncStateRow(
      feature: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}feature'],
      )!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      ),
    );
  }

  @override
  $SyncStateRowsTable createAlias(String alias) {
    return $SyncStateRowsTable(attachedDatabase, alias);
  }
}

class SyncStateRow extends DataClass implements Insertable<SyncStateRow> {
  final String feature;
  final DateTime? lastSyncedAt;
  const SyncStateRow({required this.feature, this.lastSyncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['feature'] = Variable<String>(feature);
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    return map;
  }

  SyncStateRowsCompanion toCompanion(bool nullToAbsent) {
    return SyncStateRowsCompanion(
      feature: Value(feature),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
    );
  }

  factory SyncStateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncStateRow(
      feature: serializer.fromJson<String>(json['feature']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'feature': serializer.toJson<String>(feature),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
    };
  }

  SyncStateRow copyWith({
    String? feature,
    Value<DateTime?> lastSyncedAt = const Value.absent(),
  }) => SyncStateRow(
    feature: feature ?? this.feature,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
  );
  SyncStateRow copyWithCompanion(SyncStateRowsCompanion data) {
    return SyncStateRow(
      feature: data.feature.present ? data.feature.value : this.feature,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateRow(')
          ..write('feature: $feature, ')
          ..write('lastSyncedAt: $lastSyncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(feature, lastSyncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncStateRow &&
          other.feature == this.feature &&
          other.lastSyncedAt == this.lastSyncedAt);
}

class SyncStateRowsCompanion extends UpdateCompanion<SyncStateRow> {
  final Value<String> feature;
  final Value<DateTime?> lastSyncedAt;
  final Value<int> rowid;
  const SyncStateRowsCompanion({
    this.feature = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncStateRowsCompanion.insert({
    required String feature,
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : feature = Value(feature);
  static Insertable<SyncStateRow> custom({
    Expression<String>? feature,
    Expression<DateTime>? lastSyncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (feature != null) 'feature': feature,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncStateRowsCompanion copyWith({
    Value<String>? feature,
    Value<DateTime?>? lastSyncedAt,
    Value<int>? rowid,
  }) {
    return SyncStateRowsCompanion(
      feature: feature ?? this.feature,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (feature.present) {
      map['feature'] = Variable<String>(feature.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateRowsCompanion(')
          ..write('feature: $feature, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedSessionRowsTable extends CachedSessionRows
    with TableInfo<$CachedSessionRowsTable, CachedSessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedSessionRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
    'nombre',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rolNameMeta = const VerificationMeta(
    'rolName',
  );
  @override
  late final GeneratedColumn<String> rolName = GeneratedColumn<String>(
    'rol_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rolLabelMeta = const VerificationMeta(
    'rolLabel',
  );
  @override
  late final GeneratedColumn<String> rolLabel = GeneratedColumn<String>(
    'rol_label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accionesJsonMeta = const VerificationMeta(
    'accionesJson',
  );
  @override
  late final GeneratedColumn<String> accionesJson = GeneratedColumn<String>(
    'acciones_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _metaVersionMeta = const VerificationMeta(
    'metaVersion',
  );
  @override
  late final GeneratedColumn<String> metaVersion = GeneratedColumn<String>(
    'meta_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _permissionsSyncedAtMeta =
      const VerificationMeta('permissionsSyncedAt');
  @override
  late final GeneratedColumn<DateTime> permissionsSyncedAt =
      GeneratedColumn<DateTime>(
        'permissions_synced_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    email,
    nombre,
    rolName,
    rolLabel,
    accionesJson,
    metaVersion,
    permissionsSyncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_session_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedSessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('nombre')) {
      context.handle(
        _nombreMeta,
        nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta),
      );
    }
    if (data.containsKey('rol_name')) {
      context.handle(
        _rolNameMeta,
        rolName.isAcceptableOrUnknown(data['rol_name']!, _rolNameMeta),
      );
    } else if (isInserting) {
      context.missing(_rolNameMeta);
    }
    if (data.containsKey('rol_label')) {
      context.handle(
        _rolLabelMeta,
        rolLabel.isAcceptableOrUnknown(data['rol_label']!, _rolLabelMeta),
      );
    } else if (isInserting) {
      context.missing(_rolLabelMeta);
    }
    if (data.containsKey('acciones_json')) {
      context.handle(
        _accionesJsonMeta,
        accionesJson.isAcceptableOrUnknown(
          data['acciones_json']!,
          _accionesJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_accionesJsonMeta);
    }
    if (data.containsKey('meta_version')) {
      context.handle(
        _metaVersionMeta,
        metaVersion.isAcceptableOrUnknown(
          data['meta_version']!,
          _metaVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_metaVersionMeta);
    }
    if (data.containsKey('permissions_synced_at')) {
      context.handle(
        _permissionsSyncedAtMeta,
        permissionsSyncedAt.isAcceptableOrUnknown(
          data['permissions_synced_at']!,
          _permissionsSyncedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedSessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedSessionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      nombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre'],
      ),
      rolName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rol_name'],
      )!,
      rolLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rol_label'],
      )!,
      accionesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}acciones_json'],
      )!,
      metaVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meta_version'],
      )!,
      permissionsSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}permissions_synced_at'],
      ),
    );
  }

  @override
  $CachedSessionRowsTable createAlias(String alias) {
    return $CachedSessionRowsTable(attachedDatabase, alias);
  }
}

class CachedSessionRow extends DataClass
    implements Insertable<CachedSessionRow> {
  final String id;
  final String userId;
  final String email;
  final String? nombre;
  final String rolName;
  final String rolLabel;
  final String accionesJson;
  final String metaVersion;
  final DateTime? permissionsSyncedAt;
  const CachedSessionRow({
    required this.id,
    required this.userId,
    required this.email,
    this.nombre,
    required this.rolName,
    required this.rolLabel,
    required this.accionesJson,
    required this.metaVersion,
    this.permissionsSyncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['email'] = Variable<String>(email);
    if (!nullToAbsent || nombre != null) {
      map['nombre'] = Variable<String>(nombre);
    }
    map['rol_name'] = Variable<String>(rolName);
    map['rol_label'] = Variable<String>(rolLabel);
    map['acciones_json'] = Variable<String>(accionesJson);
    map['meta_version'] = Variable<String>(metaVersion);
    if (!nullToAbsent || permissionsSyncedAt != null) {
      map['permissions_synced_at'] = Variable<DateTime>(permissionsSyncedAt);
    }
    return map;
  }

  CachedSessionRowsCompanion toCompanion(bool nullToAbsent) {
    return CachedSessionRowsCompanion(
      id: Value(id),
      userId: Value(userId),
      email: Value(email),
      nombre: nombre == null && nullToAbsent
          ? const Value.absent()
          : Value(nombre),
      rolName: Value(rolName),
      rolLabel: Value(rolLabel),
      accionesJson: Value(accionesJson),
      metaVersion: Value(metaVersion),
      permissionsSyncedAt: permissionsSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(permissionsSyncedAt),
    );
  }

  factory CachedSessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedSessionRow(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      email: serializer.fromJson<String>(json['email']),
      nombre: serializer.fromJson<String?>(json['nombre']),
      rolName: serializer.fromJson<String>(json['rolName']),
      rolLabel: serializer.fromJson<String>(json['rolLabel']),
      accionesJson: serializer.fromJson<String>(json['accionesJson']),
      metaVersion: serializer.fromJson<String>(json['metaVersion']),
      permissionsSyncedAt: serializer.fromJson<DateTime?>(
        json['permissionsSyncedAt'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'email': serializer.toJson<String>(email),
      'nombre': serializer.toJson<String?>(nombre),
      'rolName': serializer.toJson<String>(rolName),
      'rolLabel': serializer.toJson<String>(rolLabel),
      'accionesJson': serializer.toJson<String>(accionesJson),
      'metaVersion': serializer.toJson<String>(metaVersion),
      'permissionsSyncedAt': serializer.toJson<DateTime?>(permissionsSyncedAt),
    };
  }

  CachedSessionRow copyWith({
    String? id,
    String? userId,
    String? email,
    Value<String?> nombre = const Value.absent(),
    String? rolName,
    String? rolLabel,
    String? accionesJson,
    String? metaVersion,
    Value<DateTime?> permissionsSyncedAt = const Value.absent(),
  }) => CachedSessionRow(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    email: email ?? this.email,
    nombre: nombre.present ? nombre.value : this.nombre,
    rolName: rolName ?? this.rolName,
    rolLabel: rolLabel ?? this.rolLabel,
    accionesJson: accionesJson ?? this.accionesJson,
    metaVersion: metaVersion ?? this.metaVersion,
    permissionsSyncedAt: permissionsSyncedAt.present
        ? permissionsSyncedAt.value
        : this.permissionsSyncedAt,
  );
  CachedSessionRow copyWithCompanion(CachedSessionRowsCompanion data) {
    return CachedSessionRow(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      email: data.email.present ? data.email.value : this.email,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      rolName: data.rolName.present ? data.rolName.value : this.rolName,
      rolLabel: data.rolLabel.present ? data.rolLabel.value : this.rolLabel,
      accionesJson: data.accionesJson.present
          ? data.accionesJson.value
          : this.accionesJson,
      metaVersion: data.metaVersion.present
          ? data.metaVersion.value
          : this.metaVersion,
      permissionsSyncedAt: data.permissionsSyncedAt.present
          ? data.permissionsSyncedAt.value
          : this.permissionsSyncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedSessionRow(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('email: $email, ')
          ..write('nombre: $nombre, ')
          ..write('rolName: $rolName, ')
          ..write('rolLabel: $rolLabel, ')
          ..write('accionesJson: $accionesJson, ')
          ..write('metaVersion: $metaVersion, ')
          ..write('permissionsSyncedAt: $permissionsSyncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    email,
    nombre,
    rolName,
    rolLabel,
    accionesJson,
    metaVersion,
    permissionsSyncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedSessionRow &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.email == this.email &&
          other.nombre == this.nombre &&
          other.rolName == this.rolName &&
          other.rolLabel == this.rolLabel &&
          other.accionesJson == this.accionesJson &&
          other.metaVersion == this.metaVersion &&
          other.permissionsSyncedAt == this.permissionsSyncedAt);
}

class CachedSessionRowsCompanion extends UpdateCompanion<CachedSessionRow> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> email;
  final Value<String?> nombre;
  final Value<String> rolName;
  final Value<String> rolLabel;
  final Value<String> accionesJson;
  final Value<String> metaVersion;
  final Value<DateTime?> permissionsSyncedAt;
  final Value<int> rowid;
  const CachedSessionRowsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.email = const Value.absent(),
    this.nombre = const Value.absent(),
    this.rolName = const Value.absent(),
    this.rolLabel = const Value.absent(),
    this.accionesJson = const Value.absent(),
    this.metaVersion = const Value.absent(),
    this.permissionsSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedSessionRowsCompanion.insert({
    required String id,
    required String userId,
    required String email,
    this.nombre = const Value.absent(),
    required String rolName,
    required String rolLabel,
    required String accionesJson,
    required String metaVersion,
    this.permissionsSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       email = Value(email),
       rolName = Value(rolName),
       rolLabel = Value(rolLabel),
       accionesJson = Value(accionesJson),
       metaVersion = Value(metaVersion);
  static Insertable<CachedSessionRow> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? email,
    Expression<String>? nombre,
    Expression<String>? rolName,
    Expression<String>? rolLabel,
    Expression<String>? accionesJson,
    Expression<String>? metaVersion,
    Expression<DateTime>? permissionsSyncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (email != null) 'email': email,
      if (nombre != null) 'nombre': nombre,
      if (rolName != null) 'rol_name': rolName,
      if (rolLabel != null) 'rol_label': rolLabel,
      if (accionesJson != null) 'acciones_json': accionesJson,
      if (metaVersion != null) 'meta_version': metaVersion,
      if (permissionsSyncedAt != null)
        'permissions_synced_at': permissionsSyncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedSessionRowsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? email,
    Value<String?>? nombre,
    Value<String>? rolName,
    Value<String>? rolLabel,
    Value<String>? accionesJson,
    Value<String>? metaVersion,
    Value<DateTime?>? permissionsSyncedAt,
    Value<int>? rowid,
  }) {
    return CachedSessionRowsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      nombre: nombre ?? this.nombre,
      rolName: rolName ?? this.rolName,
      rolLabel: rolLabel ?? this.rolLabel,
      accionesJson: accionesJson ?? this.accionesJson,
      metaVersion: metaVersion ?? this.metaVersion,
      permissionsSyncedAt: permissionsSyncedAt ?? this.permissionsSyncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (rolName.present) {
      map['rol_name'] = Variable<String>(rolName.value);
    }
    if (rolLabel.present) {
      map['rol_label'] = Variable<String>(rolLabel.value);
    }
    if (accionesJson.present) {
      map['acciones_json'] = Variable<String>(accionesJson.value);
    }
    if (metaVersion.present) {
      map['meta_version'] = Variable<String>(metaVersion.value);
    }
    if (permissionsSyncedAt.present) {
      map['permissions_synced_at'] = Variable<DateTime>(
        permissionsSyncedAt.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedSessionRowsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('email: $email, ')
          ..write('nombre: $nombre, ')
          ..write('rolName: $rolName, ')
          ..write('rolLabel: $rolLabel, ')
          ..write('accionesJson: $accionesJson, ')
          ..write('metaVersion: $metaVersion, ')
          ..write('permissionsSyncedAt: $permissionsSyncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HijosRowsTable extends HijosRows
    with TableInfo<$HijosRowsTable, HijosRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HijosRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now().toUtc(),
  );
  @override
  late final GeneratedColumnWithTypeConverter<SyncStatus, int> syncStatus =
      GeneratedColumn<int>(
        'sync_status',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: Constant(SyncStatus.pendiente.index),
      ).withConverter<SyncStatus>($HijosRowsTable.$convertersyncStatus);
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tutorIdMeta = const VerificationMeta(
    'tutorId',
  );
  @override
  late final GeneratedColumn<String> tutorId = GeneratedColumn<String>(
    'tutor_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nombreNnaMeta = const VerificationMeta(
    'nombreNna',
  );
  @override
  late final GeneratedColumn<String> nombreNna = GeneratedColumn<String>(
    'nombre_nna',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _apellidoNnaMeta = const VerificationMeta(
    'apellidoNna',
  );
  @override
  late final GeneratedColumn<String> apellidoNna = GeneratedColumn<String>(
    'apellido_nna',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    syncStatus,
    deletedAt,
    tutorId,
    nombreNna,
    apellidoNna,
    payloadJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'hijos_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<HijosRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('tutor_id')) {
      context.handle(
        _tutorIdMeta,
        tutorId.isAcceptableOrUnknown(data['tutor_id']!, _tutorIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tutorIdMeta);
    }
    if (data.containsKey('nombre_nna')) {
      context.handle(
        _nombreNnaMeta,
        nombreNna.isAcceptableOrUnknown(data['nombre_nna']!, _nombreNnaMeta),
      );
    }
    if (data.containsKey('apellido_nna')) {
      context.handle(
        _apellidoNnaMeta,
        apellidoNna.isAcceptableOrUnknown(
          data['apellido_nna']!,
          _apellidoNnaMeta,
        ),
      );
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HijosRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HijosRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      syncStatus: $HijosRowsTable.$convertersyncStatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}sync_status'],
        )!,
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      tutorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tutor_id'],
      )!,
      nombreNna: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre_nna'],
      )!,
      apellidoNna: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}apellido_nna'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
    );
  }

  @override
  $HijosRowsTable createAlias(String alias) {
    return $HijosRowsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncStatus, int, int> $convertersyncStatus =
      const EnumIndexConverter<SyncStatus>(SyncStatus.values);
}

class HijosRow extends DataClass implements Insertable<HijosRow> {
  final String id;
  final DateTime updatedAt;
  final SyncStatus syncStatus;
  final DateTime? deletedAt;
  final String tutorId;
  final String nombreNna;
  final String apellidoNna;
  final String payloadJson;
  const HijosRow({
    required this.id,
    required this.updatedAt,
    required this.syncStatus,
    this.deletedAt,
    required this.tutorId,
    required this.nombreNna,
    required this.apellidoNna,
    required this.payloadJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    {
      map['sync_status'] = Variable<int>(
        $HijosRowsTable.$convertersyncStatus.toSql(syncStatus),
      );
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['tutor_id'] = Variable<String>(tutorId);
    map['nombre_nna'] = Variable<String>(nombreNna);
    map['apellido_nna'] = Variable<String>(apellidoNna);
    map['payload_json'] = Variable<String>(payloadJson);
    return map;
  }

  HijosRowsCompanion toCompanion(bool nullToAbsent) {
    return HijosRowsCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      syncStatus: Value(syncStatus),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      tutorId: Value(tutorId),
      nombreNna: Value(nombreNna),
      apellidoNna: Value(apellidoNna),
      payloadJson: Value(payloadJson),
    );
  }

  factory HijosRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HijosRow(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncStatus: $HijosRowsTable.$convertersyncStatus.fromJson(
        serializer.fromJson<int>(json['syncStatus']),
      ),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      tutorId: serializer.fromJson<String>(json['tutorId']),
      nombreNna: serializer.fromJson<String>(json['nombreNna']),
      apellidoNna: serializer.fromJson<String>(json['apellidoNna']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncStatus': serializer.toJson<int>(
        $HijosRowsTable.$convertersyncStatus.toJson(syncStatus),
      ),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'tutorId': serializer.toJson<String>(tutorId),
      'nombreNna': serializer.toJson<String>(nombreNna),
      'apellidoNna': serializer.toJson<String>(apellidoNna),
      'payloadJson': serializer.toJson<String>(payloadJson),
    };
  }

  HijosRow copyWith({
    String? id,
    DateTime? updatedAt,
    SyncStatus? syncStatus,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? tutorId,
    String? nombreNna,
    String? apellidoNna,
    String? payloadJson,
  }) => HijosRow(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    tutorId: tutorId ?? this.tutorId,
    nombreNna: nombreNna ?? this.nombreNna,
    apellidoNna: apellidoNna ?? this.apellidoNna,
    payloadJson: payloadJson ?? this.payloadJson,
  );
  HijosRow copyWithCompanion(HijosRowsCompanion data) {
    return HijosRow(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      tutorId: data.tutorId.present ? data.tutorId.value : this.tutorId,
      nombreNna: data.nombreNna.present ? data.nombreNna.value : this.nombreNna,
      apellidoNna: data.apellidoNna.present
          ? data.apellidoNna.value
          : this.apellidoNna,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HijosRow(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('tutorId: $tutorId, ')
          ..write('nombreNna: $nombreNna, ')
          ..write('apellidoNna: $apellidoNna, ')
          ..write('payloadJson: $payloadJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    updatedAt,
    syncStatus,
    deletedAt,
    tutorId,
    nombreNna,
    apellidoNna,
    payloadJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HijosRow &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.syncStatus == this.syncStatus &&
          other.deletedAt == this.deletedAt &&
          other.tutorId == this.tutorId &&
          other.nombreNna == this.nombreNna &&
          other.apellidoNna == this.apellidoNna &&
          other.payloadJson == this.payloadJson);
}

class HijosRowsCompanion extends UpdateCompanion<HijosRow> {
  final Value<String> id;
  final Value<DateTime> updatedAt;
  final Value<SyncStatus> syncStatus;
  final Value<DateTime?> deletedAt;
  final Value<String> tutorId;
  final Value<String> nombreNna;
  final Value<String> apellidoNna;
  final Value<String> payloadJson;
  final Value<int> rowid;
  const HijosRowsCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.tutorId = const Value.absent(),
    this.nombreNna = const Value.absent(),
    this.apellidoNna = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HijosRowsCompanion.insert({
    required String id,
    this.updatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String tutorId,
    this.nombreNna = const Value.absent(),
    this.apellidoNna = const Value.absent(),
    required String payloadJson,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       tutorId = Value(tutorId),
       payloadJson = Value(payloadJson);
  static Insertable<HijosRow> custom({
    Expression<String>? id,
    Expression<DateTime>? updatedAt,
    Expression<int>? syncStatus,
    Expression<DateTime>? deletedAt,
    Expression<String>? tutorId,
    Expression<String>? nombreNna,
    Expression<String>? apellidoNna,
    Expression<String>? payloadJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (tutorId != null) 'tutor_id': tutorId,
      if (nombreNna != null) 'nombre_nna': nombreNna,
      if (apellidoNna != null) 'apellido_nna': apellidoNna,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HijosRowsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? updatedAt,
    Value<SyncStatus>? syncStatus,
    Value<DateTime?>? deletedAt,
    Value<String>? tutorId,
    Value<String>? nombreNna,
    Value<String>? apellidoNna,
    Value<String>? payloadJson,
    Value<int>? rowid,
  }) {
    return HijosRowsCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      deletedAt: deletedAt ?? this.deletedAt,
      tutorId: tutorId ?? this.tutorId,
      nombreNna: nombreNna ?? this.nombreNna,
      apellidoNna: apellidoNna ?? this.apellidoNna,
      payloadJson: payloadJson ?? this.payloadJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(
        $HijosRowsTable.$convertersyncStatus.toSql(syncStatus.value),
      );
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (tutorId.present) {
      map['tutor_id'] = Variable<String>(tutorId.value);
    }
    if (nombreNna.present) {
      map['nombre_nna'] = Variable<String>(nombreNna.value);
    }
    if (apellidoNna.present) {
      map['apellido_nna'] = Variable<String>(apellidoNna.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HijosRowsCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('tutorId: $tutorId, ')
          ..write('nombreNna: $nombreNna, ')
          ..write('apellidoNna: $apellidoNna, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SyncStateRowsTable syncStateRows = $SyncStateRowsTable(this);
  late final $CachedSessionRowsTable cachedSessionRows =
      $CachedSessionRowsTable(this);
  late final $HijosRowsTable hijosRows = $HijosRowsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    syncStateRows,
    cachedSessionRows,
    hijosRows,
  ];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$SyncStateRowsTableCreateCompanionBuilder =
    SyncStateRowsCompanion Function({
      required String feature,
      Value<DateTime?> lastSyncedAt,
      Value<int> rowid,
    });
typedef $$SyncStateRowsTableUpdateCompanionBuilder =
    SyncStateRowsCompanion Function({
      Value<String> feature,
      Value<DateTime?> lastSyncedAt,
      Value<int> rowid,
    });

class $$SyncStateRowsTableFilterComposer
    extends Composer<_$AppDatabase, $SyncStateRowsTable> {
  $$SyncStateRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get feature => $composableBuilder(
    column: $table.feature,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncStateRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncStateRowsTable> {
  $$SyncStateRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get feature => $composableBuilder(
    column: $table.feature,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncStateRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncStateRowsTable> {
  $$SyncStateRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get feature =>
      $composableBuilder(column: $table.feature, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );
}

class $$SyncStateRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncStateRowsTable,
          SyncStateRow,
          $$SyncStateRowsTableFilterComposer,
          $$SyncStateRowsTableOrderingComposer,
          $$SyncStateRowsTableAnnotationComposer,
          $$SyncStateRowsTableCreateCompanionBuilder,
          $$SyncStateRowsTableUpdateCompanionBuilder,
          (
            SyncStateRow,
            BaseReferences<_$AppDatabase, $SyncStateRowsTable, SyncStateRow>,
          ),
          SyncStateRow,
          PrefetchHooks Function()
        > {
  $$SyncStateRowsTableTableManager(_$AppDatabase db, $SyncStateRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncStateRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncStateRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncStateRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> feature = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncStateRowsCompanion(
                feature: feature,
                lastSyncedAt: lastSyncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String feature,
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncStateRowsCompanion.insert(
                feature: feature,
                lastSyncedAt: lastSyncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncStateRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncStateRowsTable,
      SyncStateRow,
      $$SyncStateRowsTableFilterComposer,
      $$SyncStateRowsTableOrderingComposer,
      $$SyncStateRowsTableAnnotationComposer,
      $$SyncStateRowsTableCreateCompanionBuilder,
      $$SyncStateRowsTableUpdateCompanionBuilder,
      (
        SyncStateRow,
        BaseReferences<_$AppDatabase, $SyncStateRowsTable, SyncStateRow>,
      ),
      SyncStateRow,
      PrefetchHooks Function()
    >;
typedef $$CachedSessionRowsTableCreateCompanionBuilder =
    CachedSessionRowsCompanion Function({
      required String id,
      required String userId,
      required String email,
      Value<String?> nombre,
      required String rolName,
      required String rolLabel,
      required String accionesJson,
      required String metaVersion,
      Value<DateTime?> permissionsSyncedAt,
      Value<int> rowid,
    });
typedef $$CachedSessionRowsTableUpdateCompanionBuilder =
    CachedSessionRowsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> email,
      Value<String?> nombre,
      Value<String> rolName,
      Value<String> rolLabel,
      Value<String> accionesJson,
      Value<String> metaVersion,
      Value<DateTime?> permissionsSyncedAt,
      Value<int> rowid,
    });

class $$CachedSessionRowsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedSessionRowsTable> {
  $$CachedSessionRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rolName => $composableBuilder(
    column: $table.rolName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rolLabel => $composableBuilder(
    column: $table.rolLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accionesJson => $composableBuilder(
    column: $table.accionesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metaVersion => $composableBuilder(
    column: $table.metaVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get permissionsSyncedAt => $composableBuilder(
    column: $table.permissionsSyncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedSessionRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedSessionRowsTable> {
  $$CachedSessionRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rolName => $composableBuilder(
    column: $table.rolName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rolLabel => $composableBuilder(
    column: $table.rolLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accionesJson => $composableBuilder(
    column: $table.accionesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metaVersion => $composableBuilder(
    column: $table.metaVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get permissionsSyncedAt => $composableBuilder(
    column: $table.permissionsSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedSessionRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedSessionRowsTable> {
  $$CachedSessionRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumn<String> get rolName =>
      $composableBuilder(column: $table.rolName, builder: (column) => column);

  GeneratedColumn<String> get rolLabel =>
      $composableBuilder(column: $table.rolLabel, builder: (column) => column);

  GeneratedColumn<String> get accionesJson => $composableBuilder(
    column: $table.accionesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get metaVersion => $composableBuilder(
    column: $table.metaVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get permissionsSyncedAt => $composableBuilder(
    column: $table.permissionsSyncedAt,
    builder: (column) => column,
  );
}

class $$CachedSessionRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedSessionRowsTable,
          CachedSessionRow,
          $$CachedSessionRowsTableFilterComposer,
          $$CachedSessionRowsTableOrderingComposer,
          $$CachedSessionRowsTableAnnotationComposer,
          $$CachedSessionRowsTableCreateCompanionBuilder,
          $$CachedSessionRowsTableUpdateCompanionBuilder,
          (
            CachedSessionRow,
            BaseReferences<
              _$AppDatabase,
              $CachedSessionRowsTable,
              CachedSessionRow
            >,
          ),
          CachedSessionRow,
          PrefetchHooks Function()
        > {
  $$CachedSessionRowsTableTableManager(
    _$AppDatabase db,
    $CachedSessionRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedSessionRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedSessionRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedSessionRowsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String?> nombre = const Value.absent(),
                Value<String> rolName = const Value.absent(),
                Value<String> rolLabel = const Value.absent(),
                Value<String> accionesJson = const Value.absent(),
                Value<String> metaVersion = const Value.absent(),
                Value<DateTime?> permissionsSyncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedSessionRowsCompanion(
                id: id,
                userId: userId,
                email: email,
                nombre: nombre,
                rolName: rolName,
                rolLabel: rolLabel,
                accionesJson: accionesJson,
                metaVersion: metaVersion,
                permissionsSyncedAt: permissionsSyncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String email,
                Value<String?> nombre = const Value.absent(),
                required String rolName,
                required String rolLabel,
                required String accionesJson,
                required String metaVersion,
                Value<DateTime?> permissionsSyncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedSessionRowsCompanion.insert(
                id: id,
                userId: userId,
                email: email,
                nombre: nombre,
                rolName: rolName,
                rolLabel: rolLabel,
                accionesJson: accionesJson,
                metaVersion: metaVersion,
                permissionsSyncedAt: permissionsSyncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedSessionRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedSessionRowsTable,
      CachedSessionRow,
      $$CachedSessionRowsTableFilterComposer,
      $$CachedSessionRowsTableOrderingComposer,
      $$CachedSessionRowsTableAnnotationComposer,
      $$CachedSessionRowsTableCreateCompanionBuilder,
      $$CachedSessionRowsTableUpdateCompanionBuilder,
      (
        CachedSessionRow,
        BaseReferences<
          _$AppDatabase,
          $CachedSessionRowsTable,
          CachedSessionRow
        >,
      ),
      CachedSessionRow,
      PrefetchHooks Function()
    >;
typedef $$HijosRowsTableCreateCompanionBuilder =
    HijosRowsCompanion Function({
      required String id,
      Value<DateTime> updatedAt,
      Value<SyncStatus> syncStatus,
      Value<DateTime?> deletedAt,
      required String tutorId,
      Value<String> nombreNna,
      Value<String> apellidoNna,
      required String payloadJson,
      Value<int> rowid,
    });
typedef $$HijosRowsTableUpdateCompanionBuilder =
    HijosRowsCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<SyncStatus> syncStatus,
      Value<DateTime?> deletedAt,
      Value<String> tutorId,
      Value<String> nombreNna,
      Value<String> apellidoNna,
      Value<String> payloadJson,
      Value<int> rowid,
    });

class $$HijosRowsTableFilterComposer
    extends Composer<_$AppDatabase, $HijosRowsTable> {
  $$HijosRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SyncStatus, SyncStatus, int> get syncStatus =>
      $composableBuilder(
        column: $table.syncStatus,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tutorId => $composableBuilder(
    column: $table.tutorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombreNna => $composableBuilder(
    column: $table.nombreNna,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get apellidoNna => $composableBuilder(
    column: $table.apellidoNna,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HijosRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $HijosRowsTable> {
  $$HijosRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tutorId => $composableBuilder(
    column: $table.tutorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombreNna => $composableBuilder(
    column: $table.nombreNna,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get apellidoNna => $composableBuilder(
    column: $table.apellidoNna,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HijosRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $HijosRowsTable> {
  $$HijosRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncStatus, int> get syncStatus =>
      $composableBuilder(
        column: $table.syncStatus,
        builder: (column) => column,
      );

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get tutorId =>
      $composableBuilder(column: $table.tutorId, builder: (column) => column);

  GeneratedColumn<String> get nombreNna =>
      $composableBuilder(column: $table.nombreNna, builder: (column) => column);

  GeneratedColumn<String> get apellidoNna => $composableBuilder(
    column: $table.apellidoNna,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );
}

class $$HijosRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HijosRowsTable,
          HijosRow,
          $$HijosRowsTableFilterComposer,
          $$HijosRowsTableOrderingComposer,
          $$HijosRowsTableAnnotationComposer,
          $$HijosRowsTableCreateCompanionBuilder,
          $$HijosRowsTableUpdateCompanionBuilder,
          (HijosRow, BaseReferences<_$AppDatabase, $HijosRowsTable, HijosRow>),
          HijosRow,
          PrefetchHooks Function()
        > {
  $$HijosRowsTableTableManager(_$AppDatabase db, $HijosRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HijosRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HijosRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HijosRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<SyncStatus> syncStatus = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> tutorId = const Value.absent(),
                Value<String> nombreNna = const Value.absent(),
                Value<String> apellidoNna = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HijosRowsCompanion(
                id: id,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                deletedAt: deletedAt,
                tutorId: tutorId,
                nombreNna: nombreNna,
                apellidoNna: apellidoNna,
                payloadJson: payloadJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<DateTime> updatedAt = const Value.absent(),
                Value<SyncStatus> syncStatus = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required String tutorId,
                Value<String> nombreNna = const Value.absent(),
                Value<String> apellidoNna = const Value.absent(),
                required String payloadJson,
                Value<int> rowid = const Value.absent(),
              }) => HijosRowsCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                deletedAt: deletedAt,
                tutorId: tutorId,
                nombreNna: nombreNna,
                apellidoNna: apellidoNna,
                payloadJson: payloadJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HijosRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HijosRowsTable,
      HijosRow,
      $$HijosRowsTableFilterComposer,
      $$HijosRowsTableOrderingComposer,
      $$HijosRowsTableAnnotationComposer,
      $$HijosRowsTableCreateCompanionBuilder,
      $$HijosRowsTableUpdateCompanionBuilder,
      (HijosRow, BaseReferences<_$AppDatabase, $HijosRowsTable, HijosRow>),
      HijosRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SyncStateRowsTableTableManager get syncStateRows =>
      $$SyncStateRowsTableTableManager(_db, _db.syncStateRows);
  $$CachedSessionRowsTableTableManager get cachedSessionRows =>
      $$CachedSessionRowsTableTableManager(_db, _db.cachedSessionRows);
  $$HijosRowsTableTableManager get hijosRows =>
      $$HijosRowsTableTableManager(_db, _db.hijosRows);
}
