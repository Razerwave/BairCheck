import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../shared/models/app_enums.dart';
import '../../shared/models/inspection.dart';

class PhotoService {
  PhotoService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;
  static const _uuid = Uuid();

  Future<EvidencePhoto?> pickAndPreserve(ImageSource source) async {
    final selected = await _picker.pickImage(source: source, imageQuality: 100);
    if (selected == null) return null;

    final documentDirectory = await getApplicationDocumentsDirectory();
    final photoDirectory = Directory(
      p.join(documentDirectory.path, 'rentcheck', 'inspection_photos'),
    );
    await photoDirectory.create(recursive: true);

    final id = _uuid.v7();
    final compressedPath = p.join(photoDirectory.path, '$id.jpg');
    final compressed = await FlutterImageCompress.compressAndGetFile(
      selected.path,
      compressedPath,
      quality: 88,
      minWidth: 1920,
      minHeight: 1080,
      keepExif: true,
    );

    final preservedPath =
        compressed?.path ??
        (await File(selected.path).copy(
          p.join(photoDirectory.path, '$id${p.extension(selected.path)}'),
        )).path;
    return EvidencePhoto(
      id: id,
      localPath: preservedPath,
      uploadStatus: PhotoUploadStatus.pending,
    );
  }

  Future<void> deletePreserved(EvidencePhoto photo) async {
    final file = File(photo.localPath);
    if (await file.exists()) await file.delete();
  }
}

final photoServiceProvider = Provider<PhotoService>((ref) => PhotoService());
