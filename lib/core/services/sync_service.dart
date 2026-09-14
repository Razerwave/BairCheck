import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/models/app_enums.dart';
import '../../shared/models/inspection.dart';
import '../../shared/models/property.dart';
import 'backend_service.dart';
import 'local_database.dart';

/// Сүүлийн ажиллагааны үр дүн.
class SyncOutcome {
  const SyncOutcome({
    required this.pushed,
    required this.pulled,
    required this.pending,
    this.error,
  });

  const SyncOutcome.idle()
    : pushed = 0,
      pulled = 0,
      pending = 0,
      error = null;

  final int pushed;
  final int pulled;
  final int pending;
  final Object? error;

  bool get hasError => error != null;
}

/// Offline-first синхрончлол: локал SQLite нь үндсэн эх сурвалж, сүлжээ
/// байгаа үед өөрчлөлтийг Supabase руу түлхэж, шинэчлэлтийг татна.
class SyncService {
  SyncService(this._local, this._backend);

  final LocalDatabase _local;
  final BackendService _backend;
  bool _running = false;

  SupabaseClient? get _client => _backend.client;
  String? get _userId => _backend.currentUser?.id;

  bool get canSync => _client != null && _userId != null;

  /// Бүтэн мөчлөг: устгал → байр → үзлэг → татах.
  Future<SyncOutcome> sync() async {
    if (!canSync || _running) {
      return SyncOutcome(pushed: 0, pulled: 0, pending: await _pending());
    }
    _running = true;
    var pushed = 0;
    var pulled = 0;
    try {
      pushed += await _pushDeletions();
      pushed += await _pushProperties();
      pushed += await _pushInspections();
      pulled = await _pull();
      await _local.setLastPulledAt(DateTime.now().toUtc());
      return SyncOutcome(
        pushed: pushed,
        pulled: pulled,
        pending: await _pending(),
      );
    } catch (error) {
      return SyncOutcome(
        pushed: pushed,
        pulled: pulled,
        pending: await _pending(),
        error: error,
      );
    } finally {
      _running = false;
    }
  }

  Future<int> _pending() => _local.pendingChangeCount();

  // -------------------------------------------------------------- push ---

  Future<int> _pushDeletions() async {
    final ids = await _local.pendingDeletions();
    for (final id in ids) {
      await _client!.from('properties').delete().eq('id', id);
      await _local.clearDeletion(id);
    }
    return ids.length;
  }

  Future<int> _pushProperties() async {
    final properties = await _local.dirtyProperties();
    for (final property in properties) {
      await _client!.from('properties').upsert({
        'id': property.id,
        'created_by': _userId,
        'name': property.name,
        'address': property.address,
        'furnishing_type': property.furnishingType.databaseValue,
        'area_square_meters': property.areaSquareMeters,
        'floor': property.floor,
        'created_at': property.createdAt.toUtc().toIso8601String(),
        'updated_at': property.updatedAt.toUtc().toIso8601String(),
      });
      await _local.markClean('properties', property.id);
    }
    return properties.length;
  }

  Future<int> _pushInspections() async {
    final inspections = await _local.dirtyInspections();
    for (final inspection in inspections) {
      await _client!.from('inspections').upsert({
        'id': inspection.id,
        'property_id': inspection.propertyId,
        'inspection_type': inspection.type.databaseValue,
        'status': inspection.status.databaseValue,
        'fill_method': inspection.fillMethod.databaseValue,
        'linked_move_in_id': inspection.linkedMoveInId,
        'tenant_name': inspection.tenantName,
        'tenant_phone': inspection.tenantPhone,
        'tenant_email': inspection.tenantEmail,
        'created_by': _userId,
        'created_at': inspection.createdAt.toUtc().toIso8601String(),
        'updated_at': inspection.updatedAt.toUtc().toIso8601String(),
      });
      await _pushRooms(inspection);
      await _pushMeters(inspection);
      await _pushKeys(inspection);
      await _local.markClean('inspections', inspection.id);
    }
    return inspections.length;
  }

  Future<void> _pushRooms(Inspection inspection) async {
    final rooms = inspection.rooms;
    if (rooms.isNotEmpty) {
      await _client!.from('inspection_rooms').upsert([
        for (var i = 0; i < rooms.length; i++)
          {
            'id': rooms[i].id,
            'inspection_id': inspection.id,
            'name': rooms[i].name,
            'is_custom': rooms[i].isCustom,
            'sort_order': i,
          },
      ]);
    }
    await _prune('inspection_rooms', 'inspection_id', inspection.id, [
      for (final room in rooms) room.id,
    ]);

    for (final room in rooms) {
      final items = room.items;
      if (items.isNotEmpty) {
        await _client!.from('inspection_items').upsert([
          for (var i = 0; i < items.length; i++)
            {
              'id': items[i].id,
              'room_id': room.id,
              'name': items[i].name,
              'is_custom': items[i].isCustom,
              'condition': items[i].condition.databaseValue,
              'notes': items[i].notes,
              'sort_order': i,
            },
        ]);
      }
      await _prune('inspection_items', 'room_id', room.id, [
        for (final item in items) item.id,
      ]);

      for (final item in items) {
        final photos = item.photos;
        if (photos.isNotEmpty) {
          await _client!.from('inspection_photos').upsert([
            for (final photo in photos)
              {
                'id': photo.id,
                'item_id': item.id,
                'uploaded_by': _userId,
                'storage_path': photo.remotePath,
                'upload_status': photo.uploadStatus.databaseValue,
              },
          ]);
        }
        await _prune('inspection_photos', 'item_id', item.id, [
          for (final photo in photos) photo.id,
        ]);
      }
    }
  }

  Future<void> _pushMeters(Inspection inspection) async {
    final meters = inspection.meterReadings;
    if (meters.isNotEmpty) {
      await _client!.from('meter_readings').upsert([
        for (final meter in meters)
          {
            'id': meter.id,
            'inspection_id': inspection.id,
            'meter_type': meter.type,
            'reading': meter.reading,
            'unit': meter.unit,
            'notes': meter.notes,
          },
      ]);
    }
    await _prune('meter_readings', 'inspection_id', inspection.id, [
      for (final meter in meters) meter.id,
    ]);
  }

  Future<void> _pushKeys(Inspection inspection) async {
    final keys = inspection.keys;
    if (keys.isNotEmpty) {
      await _client!.from('inspection_keys').upsert([
        for (final key in keys)
          {
            'id': key.id,
            'inspection_id': inspection.id,
            'key_type': key.type,
            'quantity': key.quantity,
            'notes': key.notes,
          },
      ]);
    }
    await _prune('inspection_keys', 'inspection_id', inspection.id, [
      for (final key in keys) key.id,
    ]);
  }

  /// Локал дээр устгагдсан хүүхэд мөрүүдийг серверээс арилгана.
  Future<void> _prune(
    String table,
    String parentColumn,
    String parentId,
    List<String> keepIds,
  ) async {
    final query = _client!.from(table).delete().eq(parentColumn, parentId);
    if (keepIds.isEmpty) {
      await query;
    } else {
      await query.not('id', 'in', '(${keepIds.join(',')})');
    }
  }

  // -------------------------------------------------------------- pull ---

  Future<int> _pull() async {
    final since =
        (await _local.lastPulledAt() ??
                DateTime.fromMillisecondsSinceEpoch(0))
            .toUtc()
            .toIso8601String();

    final propertyRows = await _client!
        .from('properties')
        .select()
        .gt('updated_at', since);
    for (final row in propertyRows) {
      await _local.savePropertyFromRemote(_propertyFromRemote(row));
    }

    final inspectionRows = await _client!
        .from('inspections')
        .select(
          '*, inspection_rooms(*, inspection_items(*, inspection_photos(*))), '
          'meter_readings(*), inspection_keys(*)',
        )
        .gt('updated_at', since);
    for (final row in inspectionRows) {
      await _local.saveInspectionFromRemote(_inspectionFromRemote(row));
    }
    return propertyRows.length + inspectionRows.length;
  }

  Property _propertyFromRemote(Map<String, dynamic> row) => Property(
    id: row['id'] as String,
    name: row['name'] as String,
    address: row['address'] as String,
    furnishingType: FurnishingTypeX.fromDatabase(
      row['furnishing_type'] as String,
    ),
    areaSquareMeters: (row['area_square_meters'] as num).toDouble(),
    floor: (row['floor'] as num).toInt(),
    createdAt: DateTime.parse(row['created_at'] as String),
    updatedAt: DateTime.parse(row['updated_at'] as String),
  );

  Inspection _inspectionFromRemote(Map<String, dynamic> row) {
    final rooms = <InspectionRoom>[
      for (final roomRow in _sorted(row['inspection_rooms']))
        InspectionRoom(
          id: roomRow['id'] as String,
          name: roomRow['name'] as String,
          isCustom: roomRow['is_custom'] as bool? ?? false,
          items: [
            for (final itemRow in _sorted(roomRow['inspection_items']))
              InspectionItem(
                id: itemRow['id'] as String,
                name: itemRow['name'] as String,
                isCustom: itemRow['is_custom'] as bool? ?? false,
                condition: InspectionConditionX.fromDatabase(
                  itemRow['condition'] as String,
                ),
                notes: itemRow['notes'] as String? ?? '',
                photos: [
                  for (final photoRow
                      in (itemRow['inspection_photos'] as List? ?? []))
                    EvidencePhoto(
                      id: photoRow['id'] as String,
                      localPath: '',
                      remotePath: photoRow['storage_path'] as String?,
                      uploadStatus: PhotoUploadStatusX.fromDatabase(
                        photoRow['upload_status'] as String,
                      ),
                    ),
                ],
              ),
          ],
        ),
    ];

    return Inspection(
      id: row['id'] as String,
      propertyId: row['property_id'] as String,
      type: InspectionTypeX.fromDatabase(row['inspection_type'] as String),
      status: InspectionStatusX.fromDatabase(row['status'] as String),
      fillMethod: (row['fill_method'] as String) == 'TENANT'
          ? FillMethod.tenant
          : FillMethod.self,
      linkedMoveInId: row['linked_move_in_id'] as String?,
      tenantName: row['tenant_name'] as String?,
      tenantPhone: row['tenant_phone'] as String?,
      tenantEmail: row['tenant_email'] as String?,
      rooms: rooms,
      meterReadings: [
        for (final meterRow in (row['meter_readings'] as List? ?? []))
          MeterReading(
            id: meterRow['id'] as String,
            type: meterRow['meter_type'] as String,
            reading: (meterRow['reading'] as num).toDouble(),
            unit: meterRow['unit'] as String,
            notes: meterRow['notes'] as String? ?? '',
          ),
      ],
      keys: [
        for (final keyRow in (row['inspection_keys'] as List? ?? []))
          InspectionKey(
            id: keyRow['id'] as String,
            type: keyRow['key_type'] as String,
            quantity: (keyRow['quantity'] as num).toInt(),
            notes: keyRow['notes'] as String? ?? '',
          ),
      ],
      revisionRequests: const [],
      ownerConfirmed: false,
      tenantConfirmed: false,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  List<Map<String, dynamic>> _sorted(Object? rows) {
    final list = <Map<String, dynamic>>[
      for (final row in (rows as List? ?? []))
        Map<String, dynamic>.from(row as Map),
    ];
    list.sort(
      (a, b) => ((a['sort_order'] as num?) ?? 0).compareTo(
        (b['sort_order'] as num?) ?? 0,
      ),
    );
    return list;
  }
}

/// Сүүлийн синхрончлолын төлөв — UI-д харуулахад.
class SyncStatus extends Notifier<SyncOutcome> {
  @override
  SyncOutcome build() => const SyncOutcome.idle();

  void report(SyncOutcome outcome) => state = outcome;
}

final syncStatusProvider = NotifierProvider<SyncStatus, SyncOutcome>(
  SyncStatus.new,
);

final syncServiceProvider = Provider<SyncService>((ref) {
  final repository = ref.watch(tulkhuurRepositoryProvider);
  return SyncService(
    repository as LocalDatabase,
    ref.watch(backendServiceProvider),
  );
});
