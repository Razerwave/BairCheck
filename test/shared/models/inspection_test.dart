import 'package:flutter_test/flutter_test.dart';
import 'package:tulkhuur/shared/models/app_enums.dart' hide ComparisonResult;
import 'package:tulkhuur/shared/models/app_enums.dart' as domain
    show ComparisonResult;
import 'package:tulkhuur/shared/models/inspection.dart';

void main() {
  group('compareConditions', () {
    test('detects new damage', () {
      expect(
        compareConditions(
          InspectionCondition.good,
          InspectionCondition.damaged,
        ),
        domain.ComparisonResult.newDamage,
      );
    });

    test('detects improvement', () {
      expect(
        compareConditions(
          InspectionCondition.damaged,
          InspectionCondition.minorDamage,
        ),
        domain.ComparisonResult.improved,
      );
    });

    test('detects a newly missing item', () {
      expect(
        compareConditions(
          InspectionCondition.good,
          InspectionCondition.missing,
        ),
        domain.ComparisonResult.missing,
      );
    });

    test('does not compare not-applicable items', () {
      expect(
        compareConditions(
          InspectionCondition.notApplicable,
          InspectionCondition.good,
        ),
        domain.ComparisonResult.notComparable,
      );
    });
  });

  test('inspection survives a JSON round trip with photo status', () {
    final timestamp = DateTime.utc(2026, 9, 10, 8, 30);
    final original = Inspection(
      id: 'inspection-id',
      propertyId: 'property-id',
      type: InspectionType.moveOut,
      status: InspectionStatus.revisionRequested,
      fillMethod: FillMethod.tenant,
      linkedMoveInId: 'move-in-id',
      tenantName: 'Бат',
      tenantPhone: '99112233',
      tenantEmail: null,
      rooms: [
        InspectionRoom(
          id: 'room-id',
          name: 'Зочны өрөө',
          isCustom: false,
          items: [
            InspectionItem(
              id: 'item-id',
              name: 'Хана',
              isCustom: false,
              condition: InspectionCondition.minorDamage,
              notes: 'Жижиг сэвтэй',
              photos: const [
                EvidencePhoto(
                  id: 'photo-id',
                  localPath: '/local/photo.jpg',
                  uploadStatus: PhotoUploadStatus.failed,
                  errorMessage: 'offline',
                ),
              ],
            ),
          ],
        ),
      ],
      meterReadings: const [
        MeterReading(
          id: 'meter-id',
          type: 'Цахилгаан',
          reading: 123.45,
          unit: 'кВт.ц',
          notes: '',
        ),
      ],
      keys: const [
        InspectionKey(
          id: 'key-id',
          type: 'Үндсэн хаалга',
          quantity: 2,
          notes: '',
        ),
      ],
      revisionRequests: [
        RevisionRequest(
          id: 'revision-id',
          message: 'Дахин зураг авна уу.',
          requestsNewPhoto: true,
          createdAt: timestamp,
        ),
      ],
      ownerConfirmed: false,
      tenantConfirmed: true,
      createdAt: timestamp,
      updatedAt: timestamp,
    );

    final restored = Inspection.fromJson(original.toJson());

    expect(restored.type, InspectionType.moveOut);
    expect(
      restored.rooms.single.items.single.condition,
      InspectionCondition.minorDamage,
    );
    expect(
      restored.rooms.single.items.single.photos.single.uploadStatus,
      PhotoUploadStatus.failed,
    );
    expect(restored.revisionRequests.single.requestsNewPhoto, isTrue);
    expect(restored.meterReadings.single.reading, 123.45);
    expect(restored.keys.single.quantity, 2);
    expect(restored.tenantConfirmed, isTrue);
  });
}
