import 'dart:typed_data';

import 'package:homeslot_client/homeslot_client.dart';
import 'package:image_picker/image_picker.dart';

import 'client.dart';

/// Picks a photo, uploads it to the server's public storage and returns its
/// URL (room photos and profile pictures). Returns null when cancelled.
Future<String?> pickAndUploadImage({required String kind}) async {
  final file = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 1280,
    maxHeight: 1280,
    imageQuality: 80,
  );
  if (file == null) return null;
  final bytes = await file.readAsBytes();
  final name = file.name.toLowerCase();
  final extension = name.contains('.') ? name.split('.').last : 'jpg';
  final ticket = await client.upload.createUpload(kind, extension);
  final ok = await FileUploader(
    ticket.description,
  ).uploadByteData(ByteData.sublistView(bytes));
  if (!ok) throw Exception('Upload failed');
  return client.upload.verifyUpload(ticket.path);
}
