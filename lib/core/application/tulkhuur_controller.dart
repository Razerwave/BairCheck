import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../shared/models/app_enums.dart';
import '../../shared/models/inspection.dart';
import '../../shared/models/property.dart';
import '../constants/app_strings.dart';
import '../services/backend_service.dart';
import '../services/local_database.dart';
import '../services/sync_service.dart';

class TulkhuurState {
  const TulkhuurState({required this.properties, required this.inspections});

  const TulkhuurState.empty() : properties = const [], inspections = const [];

  final List<Property> properties;
  final List<Inspection> inspections;

  Property? propertyById(String id) {
    for (final property in properties) {
      if (property.id == id) return property;
    }
    return null;
  }

  Inspection? inspectionById(String id) {
    for (final inspection in inspections) {
      if (inspection.id == id) return inspection;
    }
    return null;
  }

  List<Inspection> inspectionsForProperty(String propertyId) => inspections
      .where((inspection) => inspection.propertyId == propertyId)
      .toList(growable: false);
}

final tulkhuurControllerProvider =
    AsyncNotifierProvider<TulkhuurController, TulkhuurState>(
      TulkhuurController.new,
    );

class TulkhuurController extends AsyncNotifier<TulkhuurState> {
  static const _uuid = Uuid();

  TulkhuurRepository get _repository => ref.read(tulkhuurRepositoryProvider);

  /// Хадгалсны дараа сервертэй тааруулна. Алдаа гарвал өөрчлөлт локал дээр
  /// `dirty` хэвээр үлдэж, дараагийн оролдлогод дахин илгээгдэнэ.
  void _syncInBackground() {
    final sync = ref.read(syncServiceProvider);
    if (!sync.canSync) {
      unawaited(
        (_repository as LocalDatabase).pendingChangeCount().then((pending) {
          ref
              .read(syncStatusProvider.notifier)
              .report(SyncOutcome(pushed: 0, pulled: 0, pending: pending));
        }),
      );
      return;
    }
    unawaited(
      sync.sync().then((outcome) {
        ref.read(syncStatusProvider.notifier).report(outcome);
      }),
    );
  }

  @override
  Future<TulkhuurState> build() async {
    final results = await Future.wait([
      _repository.loadProperties(),
      _repository.loadInspections(),
    ]);
    // Апп нээгдэхэд илгээгээгүй өөрчлөлт байвал сервертэй тааруулна.
    _syncInBackground();
    return TulkhuurState(
      properties: results[0] as List<Property>,
      inspections: results[1] as List<Inspection>,
    );
  }

  Future<Property> saveProperty({
    String? id,
    required String name,
    required String address,
    required FurnishingType furnishingType,
    required double areaSquareMeters,
    required int floor,
  }) async {
    final current = state.requireValue;
    final existing = id == null ? null : current.propertyById(id);
    final now = DateTime.now();
    final property = Property(
      id: id ?? _uuid.v7(),
      name: name.trim(),
      address: address.trim(),
      furnishingType: furnishingType,
      areaSquareMeters: areaSquareMeters,
      floor: floor,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    await _repository.saveProperty(property);
    _syncInBackground();
    final properties = [
      property,
      ...current.properties.where((item) => item.id != property.id),
    ];
    state = AsyncData(
      TulkhuurState(properties: properties, inspections: current.inspections),
    );
    return property;
  }

  Future<void> deleteProperty(String propertyId) async {
    final current = state.requireValue;
    if (current.inspections.any(
      (inspection) => inspection.propertyId == propertyId,
    )) {
      throw StateError(AppStrings.propertyDeleteDescription);
    }
    await _repository.deleteProperty(propertyId);
    _syncInBackground();
    state = AsyncData(
      TulkhuurState(
        properties: current.properties
            .where((property) => property.id != propertyId)
            .toList(growable: false),
        inspections: current.inspections,
      ),
    );
  }

  Future<Inspection> createInspection({
    required String propertyId,
    required InspectionType type,
    required FillMethod fillMethod,
    String? tenantName,
    String? tenantPhone,
    String? tenantEmail,
  }) async {
    final current = state.requireValue;
    if (current.propertyById(propertyId) == null) {
      throw StateError(AppStrings.propertyNotFound);
    }

    Inspection? linkedMoveIn;
    if (type == InspectionType.moveOut) {
      final candidates = current.inspections.where(
        (inspection) =>
            inspection.propertyId == propertyId &&
            inspection.type == InspectionType.moveIn &&
            {
              InspectionStatus.approved,
              InspectionStatus.partiallyConfirmed,
              InspectionStatus.finalized,
            }.contains(inspection.status),
      );
      if (candidates.isEmpty) throw StateError(AppStrings.moveInRequired);
      linkedMoveIn = candidates.reduce(
        (a, b) => a.updatedAt.isAfter(b.updatedAt) ? a : b,
      );
    }

    final now = DateTime.now();
    final inspection = Inspection(
      id: _uuid.v7(),
      propertyId: propertyId,
      type: type,
      status: InspectionStatus.draft,
      fillMethod: fillMethod,
      linkedMoveInId: linkedMoveIn?.id,
      tenantName: _cleanOptional(tenantName),
      tenantPhone: _cleanOptional(tenantPhone),
      tenantEmail: _cleanOptional(tenantEmail),
      rooms: linkedMoveIn == null
          ? _defaultRooms()
          : _cloneRoomsForMoveOut(linkedMoveIn.rooms),
      meterReadings: const [],
      keys: const [],
      revisionRequests: const [],
      ownerConfirmed: false,
      tenantConfirmed: false,
      createdAt: now,
      updatedAt: now,
    );
    await _saveInspectionToState(inspection);
    return inspection;
  }

  Future<void> updateItem({
    required String inspectionId,
    required String roomId,
    required InspectionItem item,
  }) async {
    final inspection = _requireInspection(inspectionId);
    final rooms = inspection.rooms
        .map(
          (room) => room.id == roomId
              ? room.copyWith(
                  items: room.items
                      .map(
                        (existing) => existing.id == item.id ? item : existing,
                      )
                      .toList(growable: false),
                )
              : room,
        )
        .toList(growable: false);
    await _saveInspectionToState(
      inspection.copyWith(rooms: rooms, updatedAt: DateTime.now()),
    );
  }

  Future<void> addRoom(String inspectionId, String roomName) async {
    final inspection = _requireInspection(inspectionId);
    final room = InspectionRoom(
      id: _uuid.v7(),
      name: roomName.trim(),
      isCustom: true,
      items: const [],
    );
    await _saveInspectionToState(
      inspection.copyWith(
        rooms: [...inspection.rooms, room],
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> removeRoom(String inspectionId, String roomId) async {
    final inspection = _requireInspection(inspectionId);
    final room = inspection.rooms.where((item) => item.id == roomId).first;
    if (!room.isCustom) throw StateError(AppStrings.customOnlyRemoval);
    await _saveInspectionToState(
      inspection.copyWith(
        rooms: inspection.rooms
            .where((item) => item.id != roomId)
            .toList(growable: false),
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> addItem(
    String inspectionId,
    String roomId,
    String itemName,
  ) async {
    final item = InspectionItem(
      id: _uuid.v7(),
      name: itemName.trim(),
      isCustom: true,
      condition: InspectionCondition.good,
      notes: '',
      photos: const [],
    );
    final inspection = _requireInspection(inspectionId);
    final room = inspection.rooms.where((item) => item.id == roomId).first;
    await updateItemCollection(
      inspectionId: inspectionId,
      roomId: roomId,
      items: [...room.items, item],
    );
  }

  Future<void> removeItem(
    String inspectionId,
    String roomId,
    String itemId,
  ) async {
    final inspection = _requireInspection(inspectionId);
    final room = inspection.rooms.where((item) => item.id == roomId).first;
    final item = room.items.where((entry) => entry.id == itemId).first;
    if (!item.isCustom) throw StateError(AppStrings.customOnlyRemoval);
    await updateItemCollection(
      inspectionId: inspectionId,
      roomId: roomId,
      items: room.items.where((entry) => entry.id != itemId).toList(),
    );
  }

  Future<void> updateItemCollection({
    required String inspectionId,
    required String roomId,
    required List<InspectionItem> items,
  }) async {
    final inspection = _requireInspection(inspectionId);
    final rooms = inspection.rooms
        .map((room) => room.id == roomId ? room.copyWith(items: items) : room)
        .toList(growable: false);
    await _saveInspectionToState(
      inspection.copyWith(rooms: rooms, updatedAt: DateTime.now()),
    );
  }

  Future<void> submitForReview(String inspectionId) async {
    final inspection = _requireInspection(inspectionId);
    await _saveInspectionToState(
      inspection.copyWith(
        status: InspectionStatus.reviewRequired,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> addMeterReading({
    required String inspectionId,
    required String type,
    required double reading,
    required String unit,
    required String notes,
  }) async {
    final inspection = _requireInspection(inspectionId);
    final meter = MeterReading(
      id: _uuid.v7(),
      type: type.trim(),
      reading: reading,
      unit: unit.trim(),
      notes: notes.trim(),
    );
    await _saveInspectionToState(
      inspection.copyWith(
        meterReadings: [...inspection.meterReadings, meter],
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> removeMeterReading(String inspectionId, String meterId) async {
    final inspection = _requireInspection(inspectionId);
    await _saveInspectionToState(
      inspection.copyWith(
        meterReadings: inspection.meterReadings
            .where((meter) => meter.id != meterId)
            .toList(growable: false),
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> addKey({
    required String inspectionId,
    required String type,
    required int quantity,
    required String notes,
  }) async {
    final inspection = _requireInspection(inspectionId);
    final key = InspectionKey(
      id: _uuid.v7(),
      type: type.trim(),
      quantity: quantity,
      notes: notes.trim(),
    );
    await _saveInspectionToState(
      inspection.copyWith(
        keys: [...inspection.keys, key],
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> removeKey(String inspectionId, String keyId) async {
    final inspection = _requireInspection(inspectionId);
    await _saveInspectionToState(
      inspection.copyWith(
        keys: inspection.keys
            .where((key) => key.id != keyId)
            .toList(growable: false),
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> approve(String inspectionId) async {
    final inspection = _requireInspection(inspectionId);
    await _saveInspectionToState(
      inspection.copyWith(
        status: InspectionStatus.approved,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> requestRevision({
    required String inspectionId,
    required String message,
    required bool requestsNewPhoto,
  }) async {
    final inspection = _requireInspection(inspectionId);
    final request = RevisionRequest(
      id: _uuid.v7(),
      message: message.trim(),
      requestsNewPhoto: requestsNewPhoto,
      createdAt: DateTime.now(),
    );
    await _saveInspectionToState(
      inspection.copyWith(
        status: InspectionStatus.revisionRequested,
        revisionRequests: [...inspection.revisionRequests, request],
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> confirm({
    required String inspectionId,
    required bool asOwner,
  }) async {
    final inspection = _requireInspection(inspectionId);
    final ownerConfirmed = asOwner || inspection.ownerConfirmed;
    final tenantConfirmed = !asOwner || inspection.tenantConfirmed;
    final status = ownerConfirmed && tenantConfirmed
        ? InspectionStatus.finalized
        : InspectionStatus.partiallyConfirmed;
    await _saveInspectionToState(
      inspection.copyWith(
        status: status,
        ownerConfirmed: ownerConfirmed,
        tenantConfirmed: tenantConfirmed,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> addPhoto({
    required String inspectionId,
    required String roomId,
    required String itemId,
    required EvidencePhoto photo,
  }) async {
    final item = _requireItem(inspectionId, roomId, itemId);
    await updateItem(
      inspectionId: inspectionId,
      roomId: roomId,
      item: item.copyWith(photos: [...item.photos, photo]),
    );
    unawaited(
      retryPhotoUpload(
        inspectionId: inspectionId,
        roomId: roomId,
        itemId: itemId,
        photoId: photo.id,
      ),
    );
  }

  Future<void> removePhoto({
    required String inspectionId,
    required String roomId,
    required String itemId,
    required String photoId,
  }) async {
    final item = _requireItem(inspectionId, roomId, itemId);
    await updateItem(
      inspectionId: inspectionId,
      roomId: roomId,
      item: item.copyWith(
        photos: item.photos
            .where((photo) => photo.id != photoId)
            .toList(growable: false),
      ),
    );
  }

  Future<void> retryPhotoUpload({
    required String inspectionId,
    required String roomId,
    required String itemId,
    required String photoId,
  }) async {
    final backend = ref.read(backendServiceProvider);
    final currentPhoto = _requirePhoto(inspectionId, roomId, itemId, photoId);
    if (!backend.isConfigured || backend.currentUser == null) {
      await _replacePhoto(
        inspectionId,
        roomId,
        itemId,
        currentPhoto.copyWith(
          uploadStatus: PhotoUploadStatus.failed,
          errorMessage: backend.isConfigured
              ? AppStrings.signInRequired
              : AppStrings.backendNotConfigured,
        ),
      );
      return;
    }

    await _replacePhoto(
      inspectionId,
      roomId,
      itemId,
      currentPhoto.copyWith(
        uploadStatus: PhotoUploadStatus.uploading,
        clearError: true,
      ),
    );
    try {
      final remotePath = await backend.uploadInspectionPhoto(
        inspectionId: inspectionId,
        itemId: itemId,
        photoId: photoId,
        localPath: currentPhoto.localPath,
      );
      await _replacePhoto(
        inspectionId,
        roomId,
        itemId,
        currentPhoto.copyWith(
          uploadStatus: PhotoUploadStatus.uploaded,
          remotePath: remotePath,
          clearError: true,
        ),
      );
    } catch (error) {
      await _replacePhoto(
        inspectionId,
        roomId,
        itemId,
        currentPhoto.copyWith(
          uploadStatus: PhotoUploadStatus.failed,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> retryPendingUploads() async {
    final current = state.value;
    if (current == null) return;
    for (final inspection in current.inspections) {
      for (final room in inspection.rooms) {
        for (final item in room.items) {
          for (final photo in item.photos) {
            if (photo.uploadStatus == PhotoUploadStatus.pending ||
                photo.uploadStatus == PhotoUploadStatus.failed) {
              await retryPhotoUpload(
                inspectionId: inspection.id,
                roomId: room.id,
                itemId: item.id,
                photoId: photo.id,
              );
            }
          }
        }
      }
    }
  }

  Future<void> _replacePhoto(
    String inspectionId,
    String roomId,
    String itemId,
    EvidencePhoto replacement,
  ) async {
    final item = _requireItem(inspectionId, roomId, itemId);
    await updateItem(
      inspectionId: inspectionId,
      roomId: roomId,
      item: item.copyWith(
        photos: item.photos
            .map((photo) => photo.id == replacement.id ? replacement : photo)
            .toList(growable: false),
      ),
    );
  }

  Future<void> _saveInspectionToState(Inspection inspection) async {
    await _repository.saveInspection(inspection);
    _syncInBackground();
    final current = state.requireValue;
    state = AsyncData(
      TulkhuurState(
        properties: current.properties,
        inspections: [
          inspection,
          ...current.inspections.where((item) => item.id != inspection.id),
        ],
      ),
    );
  }

  Inspection _requireInspection(String id) {
    final inspection = state.requireValue.inspectionById(id);
    if (inspection == null) throw StateError(AppStrings.inspectionNotFound);
    return inspection;
  }

  InspectionItem _requireItem(
    String inspectionId,
    String roomId,
    String itemId,
  ) {
    final inspection = _requireInspection(inspectionId);
    final room = inspection.rooms.where((entry) => entry.id == roomId).first;
    return room.items.where((entry) => entry.id == itemId).first;
  }

  EvidencePhoto _requirePhoto(
    String inspectionId,
    String roomId,
    String itemId,
    String photoId,
  ) => _requireItem(
    inspectionId,
    roomId,
    itemId,
  ).photos.where((photo) => photo.id == photoId).first;

  static String? _cleanOptional(String? value) {
    final cleaned = value?.trim();
    return cleaned == null || cleaned.isEmpty ? null : cleaned;
  }

  static List<InspectionRoom> _cloneRoomsForMoveOut(
    List<InspectionRoom> rooms,
  ) => rooms
      .map(
        (room) => InspectionRoom(
          id: _uuid.v7(),
          name: room.name,
          isCustom: room.isCustom,
          items: room.items
              .map(
                (item) => InspectionItem(
                  id: _uuid.v7(),
                  name: item.name,
                  isCustom: item.isCustom,
                  condition: InspectionCondition.good,
                  notes: '',
                  photos: const [],
                ),
              )
              .toList(growable: false),
        ),
      )
      .toList(growable: false);

  static List<InspectionRoom> _defaultRooms() {
    InspectionItem item(String name) => InspectionItem(
      id: _uuid.v7(),
      name: name,
      isCustom: false,
      condition: InspectionCondition.good,
      notes: '',
      photos: const [],
    );

    InspectionRoom room(String name, List<String> names) => InspectionRoom(
      id: _uuid.v7(),
      name: name,
      isCustom: false,
      items: names.map(item).toList(growable: false),
    );

    const standard = [
      AppStrings.itemWall,
      AppStrings.itemFloor,
      AppStrings.itemCeiling,
      AppStrings.itemDoor,
      AppStrings.itemWindow,
      AppStrings.itemWindowSill,
      AppStrings.itemLight,
      AppStrings.itemSwitch,
      AppStrings.itemSocket,
      AppStrings.itemRadiator,
    ];
    return [
      room(AppStrings.roomLiving, standard),
      room(AppStrings.roomBedroom, standard),
      room(AppStrings.roomKitchen, [
        ...standard,
        AppStrings.itemSink,
        AppStrings.itemFaucet,
      ]),
      room(AppStrings.roomBathroom, [
        AppStrings.itemWall,
        AppStrings.itemFloor,
        AppStrings.itemCeiling,
        AppStrings.itemDoor,
        AppStrings.itemLight,
        AppStrings.itemSwitch,
        AppStrings.itemSink,
        AppStrings.itemFaucet,
        AppStrings.itemToilet,
        AppStrings.itemShower,
      ]),
      room(AppStrings.roomBalcony, [
        AppStrings.itemWall,
        AppStrings.itemFloor,
        AppStrings.itemDoor,
        AppStrings.itemWindow,
        AppStrings.itemBalcony,
      ]),
    ];
  }
}
