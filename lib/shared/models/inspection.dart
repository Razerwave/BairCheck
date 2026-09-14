import 'app_enums.dart';

class EvidencePhoto {
  const EvidencePhoto({
    required this.id,
    required this.localPath,
    required this.uploadStatus,
    this.remotePath,
    this.errorMessage,
  });

  final String id;
  final String localPath;
  final String? remotePath;
  final PhotoUploadStatus uploadStatus;
  final String? errorMessage;

  EvidencePhoto copyWith({
    String? remotePath,
    PhotoUploadStatus? uploadStatus,
    String? errorMessage,
    bool clearError = false,
  }) => EvidencePhoto(
    id: id,
    localPath: localPath,
    remotePath: remotePath ?? this.remotePath,
    uploadStatus: uploadStatus ?? this.uploadStatus,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'local_path': localPath,
    'remote_path': remotePath,
    'upload_status': uploadStatus.databaseValue,
    'error_message': errorMessage,
  };

  factory EvidencePhoto.fromJson(Map<String, Object?> json) => EvidencePhoto(
    id: json['id']! as String,
    localPath: json['local_path']! as String,
    remotePath: json['remote_path'] as String?,
    uploadStatus: PhotoUploadStatusX.fromDatabase(
      json['upload_status']! as String,
    ),
    errorMessage: json['error_message'] as String?,
  );
}

class InspectionItem {
  const InspectionItem({
    required this.id,
    required this.name,
    required this.isCustom,
    required this.condition,
    required this.notes,
    required this.photos,
  });

  final String id;
  final String name;
  final bool isCustom;
  final InspectionCondition condition;
  final String notes;
  final List<EvidencePhoto> photos;

  InspectionItem copyWith({
    String? name,
    InspectionCondition? condition,
    String? notes,
    List<EvidencePhoto>? photos,
  }) => InspectionItem(
    id: id,
    name: name ?? this.name,
    isCustom: isCustom,
    condition: condition ?? this.condition,
    notes: notes ?? this.notes,
    photos: photos ?? this.photos,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'is_custom': isCustom,
    'condition': condition.databaseValue,
    'notes': notes,
    'photos': photos.map((photo) => photo.toJson()).toList(),
  };

  factory InspectionItem.fromJson(Map<String, Object?> json) => InspectionItem(
    id: json['id']! as String,
    name: json['name']! as String,
    isCustom: json['is_custom']! as bool,
    condition: InspectionConditionX.fromDatabase(json['condition']! as String),
    notes: json['notes']! as String,
    photos: (json['photos']! as List<Object?>)
        .map(
          (photo) =>
              EvidencePhoto.fromJson(Map<String, Object?>.from(photo! as Map)),
        )
        .toList(growable: false),
  );
}

class InspectionRoom {
  const InspectionRoom({
    required this.id,
    required this.name,
    required this.isCustom,
    required this.items,
  });

  final String id;
  final String name;
  final bool isCustom;
  final List<InspectionItem> items;

  InspectionRoom copyWith({String? name, List<InspectionItem>? items}) =>
      InspectionRoom(
        id: id,
        name: name ?? this.name,
        isCustom: isCustom,
        items: items ?? this.items,
      );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'is_custom': isCustom,
    'items': items.map((item) => item.toJson()).toList(),
  };

  factory InspectionRoom.fromJson(Map<String, Object?> json) => InspectionRoom(
    id: json['id']! as String,
    name: json['name']! as String,
    isCustom: json['is_custom']! as bool,
    items: (json['items']! as List<Object?>)
        .map(
          (item) =>
              InspectionItem.fromJson(Map<String, Object?>.from(item! as Map)),
        )
        .toList(growable: false),
  );
}

class MeterReading {
  const MeterReading({
    required this.id,
    required this.type,
    required this.reading,
    required this.unit,
    required this.notes,
  });

  final String id;
  final String type;
  final double reading;
  final String unit;
  final String notes;

  Map<String, Object?> toJson() => {
    'id': id,
    'type': type,
    'reading': reading,
    'unit': unit,
    'notes': notes,
  };

  factory MeterReading.fromJson(Map<String, Object?> json) => MeterReading(
    id: json['id']! as String,
    type: json['type']! as String,
    reading: (json['reading']! as num).toDouble(),
    unit: json['unit']! as String,
    notes: json['notes']! as String,
  );
}

class InspectionKey {
  const InspectionKey({
    required this.id,
    required this.type,
    required this.quantity,
    required this.notes,
  });

  final String id;
  final String type;
  final int quantity;
  final String notes;

  Map<String, Object?> toJson() => {
    'id': id,
    'type': type,
    'quantity': quantity,
    'notes': notes,
  };

  factory InspectionKey.fromJson(Map<String, Object?> json) => InspectionKey(
    id: json['id']! as String,
    type: json['type']! as String,
    quantity: (json['quantity']! as num).toInt(),
    notes: json['notes']! as String,
  );
}

class RevisionRequest {
  const RevisionRequest({
    required this.id,
    required this.message,
    required this.requestsNewPhoto,
    required this.createdAt,
    this.roomId,
    this.itemId,
  });

  final String id;
  final String message;
  final bool requestsNewPhoto;
  final DateTime createdAt;
  final String? roomId;
  final String? itemId;

  Map<String, Object?> toJson() => {
    'id': id,
    'message': message,
    'requests_new_photo': requestsNewPhoto,
    'created_at': createdAt.toIso8601String(),
    'room_id': roomId,
    'item_id': itemId,
  };

  factory RevisionRequest.fromJson(Map<String, Object?> json) =>
      RevisionRequest(
        id: json['id']! as String,
        message: json['message']! as String,
        requestsNewPhoto: json['requests_new_photo']! as bool,
        createdAt: DateTime.parse(json['created_at']! as String),
        roomId: json['room_id'] as String?,
        itemId: json['item_id'] as String?,
      );
}

class Inspection {
  const Inspection({
    required this.id,
    required this.propertyId,
    required this.type,
    required this.status,
    required this.fillMethod,
    required this.rooms,
    required this.meterReadings,
    required this.keys,
    required this.revisionRequests,
    required this.ownerConfirmed,
    required this.tenantConfirmed,
    required this.createdAt,
    required this.updatedAt,
    this.linkedMoveInId,
    this.tenantName,
    this.tenantPhone,
    this.tenantEmail,
  });

  final String id;
  final String propertyId;
  final InspectionType type;
  final InspectionStatus status;
  final FillMethod fillMethod;
  final String? linkedMoveInId;
  final String? tenantName;
  final String? tenantPhone;
  final String? tenantEmail;
  final List<InspectionRoom> rooms;
  final List<MeterReading> meterReadings;
  final List<InspectionKey> keys;
  final List<RevisionRequest> revisionRequests;
  final bool ownerConfirmed;
  final bool tenantConfirmed;
  final DateTime createdAt;
  final DateTime updatedAt;

  Inspection copyWith({
    InspectionStatus? status,
    List<InspectionRoom>? rooms,
    List<MeterReading>? meterReadings,
    List<InspectionKey>? keys,
    List<RevisionRequest>? revisionRequests,
    bool? ownerConfirmed,
    bool? tenantConfirmed,
    DateTime? updatedAt,
  }) => Inspection(
    id: id,
    propertyId: propertyId,
    type: type,
    status: status ?? this.status,
    fillMethod: fillMethod,
    linkedMoveInId: linkedMoveInId,
    tenantName: tenantName,
    tenantPhone: tenantPhone,
    tenantEmail: tenantEmail,
    rooms: rooms ?? this.rooms,
    meterReadings: meterReadings ?? this.meterReadings,
    keys: keys ?? this.keys,
    revisionRequests: revisionRequests ?? this.revisionRequests,
    ownerConfirmed: ownerConfirmed ?? this.ownerConfirmed,
    tenantConfirmed: tenantConfirmed ?? this.tenantConfirmed,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'property_id': propertyId,
    'type': type.databaseValue,
    'status': status.databaseValue,
    'fill_method': fillMethod.databaseValue,
    'linked_move_in_id': linkedMoveInId,
    'tenant_name': tenantName,
    'tenant_phone': tenantPhone,
    'tenant_email': tenantEmail,
    'rooms': rooms.map((room) => room.toJson()).toList(),
    'meter_readings': meterReadings.map((meter) => meter.toJson()).toList(),
    'keys': keys.map((key) => key.toJson()).toList(),
    'revision_requests': revisionRequests
        .map((request) => request.toJson())
        .toList(),
    'owner_confirmed': ownerConfirmed,
    'tenant_confirmed': tenantConfirmed,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory Inspection.fromJson(Map<String, Object?> json) => Inspection(
    id: json['id']! as String,
    propertyId: json['property_id']! as String,
    type: InspectionTypeX.fromDatabase(json['type']! as String),
    status: InspectionStatusX.fromDatabase(json['status']! as String),
    fillMethod: FillMethodX.fromDatabase(json['fill_method']! as String),
    linkedMoveInId: json['linked_move_in_id'] as String?,
    tenantName: json['tenant_name'] as String?,
    tenantPhone: json['tenant_phone'] as String?,
    tenantEmail: json['tenant_email'] as String?,
    rooms: (json['rooms']! as List<Object?>)
        .map(
          (room) =>
              InspectionRoom.fromJson(Map<String, Object?>.from(room! as Map)),
        )
        .toList(growable: false),
    meterReadings: ((json['meter_readings'] as List<Object?>?) ?? const [])
        .map(
          (meter) => MeterReading.fromJson(
            Map<String, Object?>.from(meter! as Map),
          ),
        )
        .toList(growable: false),
    keys: ((json['keys'] as List<Object?>?) ?? const [])
        .map(
          (key) => InspectionKey.fromJson(
            Map<String, Object?>.from(key! as Map),
          ),
        )
        .toList(growable: false),
    revisionRequests: (json['revision_requests']! as List<Object?>)
        .map(
          (request) => RevisionRequest.fromJson(
            Map<String, Object?>.from(request! as Map),
          ),
        )
        .toList(growable: false),
    ownerConfirmed: json['owner_confirmed']! as bool,
    tenantConfirmed: json['tenant_confirmed']! as bool,
    createdAt: DateTime.parse(json['created_at']! as String),
    updatedAt: DateTime.parse(json['updated_at']! as String),
  );
}

ComparisonResult compareConditions(
  InspectionCondition before,
  InspectionCondition after,
) {
  if (before == InspectionCondition.notApplicable ||
      after == InspectionCondition.notApplicable) {
    return ComparisonResult.notComparable;
  }
  if (after == InspectionCondition.missing) {
    return before == InspectionCondition.missing
        ? ComparisonResult.unchanged
        : ComparisonResult.missing;
  }
  if (before == InspectionCondition.missing) {
    return ComparisonResult.improved;
  }

  const severity = {
    InspectionCondition.good: 0,
    InspectionCondition.minorDamage: 1,
    InspectionCondition.damaged: 2,
  };
  final beforeSeverity = severity[before];
  final afterSeverity = severity[after];
  if (beforeSeverity == null || afterSeverity == null) {
    return ComparisonResult.notComparable;
  }
  if (afterSeverity > beforeSeverity) return ComparisonResult.newDamage;
  if (afterSeverity < beforeSeverity) return ComparisonResult.improved;
  return ComparisonResult.unchanged;
}
