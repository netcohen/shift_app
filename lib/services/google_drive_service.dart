import 'dart:io';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class GoogleDriveService {
  static drive.DriveApi? _driveApi;

  static Future<void> init(GoogleSignInAccount account) async {
    final authHeaders = await account.authHeaders;
    final client = _GoogleAuthClient(authHeaders);
    _driveApi = drive.DriveApi(client);
    print("✅ Google Drive API מוכן");
  }

  static Future<void> uploadFile(File file, String fileName) async {
    if (_driveApi == null) {
      throw Exception("⛔️ Google Drive API לא מאותחל");
    }

    final media = drive.Media(file.openRead(), file.lengthSync());
    final driveFile =
        drive.File()
          ..name = fileName
          ..parents = ['appDataFolder']; // 🏠 נשמר בתיקיית האפליקציה

    final existingFiles = await _driveApi!.files.list(
      q: "name='$fileName'",
      spaces: 'appDataFolder',
    );

    if (existingFiles.files != null && existingFiles.files!.isNotEmpty) {
      final fileId = existingFiles.files!.first.id;
      if (fileId != null) {
        await _driveApi!.files.update(driveFile, fileId, uploadMedia: media);
        print("📝 עודכן $fileName ב-Drive");
        return;
      }
    }

    await _driveApi!.files.create(driveFile, uploadMedia: media);
    print("🆕 נוסף $fileName ל-Drive");
  }

  static Future<void> downloadFile(String fileName, String savePath) async {
    if (_driveApi == null) {
      throw Exception("⛔️ Google Drive API לא מאותחל");
    }

    final files = await _driveApi!.files.list(
      q: "name='$fileName'",
      spaces: 'appDataFolder',
    );

    if (files.files != null && files.files!.isNotEmpty) {
      final fileId = files.files!.first.id;
      if (fileId != null) {
        final media =
            await _driveApi!.files.get(
                  fileId,
                  downloadOptions: drive.DownloadOptions.fullMedia,
                )
                as drive.Media;

        final file = File(savePath);
        final sink = file.openWrite();
        await media.stream.pipe(sink);
        await sink.close();
        print("✅ $fileName נשמר ל-$savePath");
      }
    } else {
      print("⚠️ הקובץ $fileName לא נמצא בדרייב");
    }
  }
}

class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}
