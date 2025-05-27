import 'dart:io';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;

class BackupService {
  static final List<String> _dbFiles = ['settings.db', 'events.db'];

  static Future<drive.DriveApi?> _getDriveApi() async {
    final googleSignIn = GoogleSignIn.standard(
      scopes: [drive.DriveApi.driveFileScope],
    );
    final account =
        googleSignIn.currentUser ?? await googleSignIn.signInSilently();
    if (account == null) {
      print('❌ לא מחובר לגוגל');
      return null;
    }

    final authHeaders = await account.authHeaders;
    final client = _GoogleAuthClient(authHeaders);
    return drive.DriveApi(client);
  }

  static Future<void> backupDatabases() async {
    final driveApi = await _getDriveApi();
    if (driveApi == null) return;

    final dbPath = await getDatabasesPath();
    for (final dbFile in _dbFiles) {
      final filePath = p.join(dbPath, dbFile);
      final file = File(filePath);
      if (await file.exists()) {
        final media = drive.Media(file.openRead(), await file.length());
        final driveFile =
            drive.File()
              ..name = dbFile
              ..parents = ['appDataFolder'];

        final existingFile = await _findExistingFile(driveApi, dbFile);
        if (existingFile != null) {
          await driveApi.files.update(
            driveFile,
            existingFile.id!,
            uploadMedia: media,
          );
          print('✅ עודכן $dbFile בגיבוי Google Drive');
        } else {
          await driveApi.files.create(driveFile, uploadMedia: media);
          print('✅ נשמר קובץ $dbFile חדש בגיבוי Google Drive');
        }
      } else {
        print('⚠️ הקובץ $dbFile לא נמצא במכשיר');
      }
    }
  }

  static Future<void> restoreDatabases() async {
    final driveApi = await _getDriveApi();
    if (driveApi == null) return;

    final dbPath = await getDatabasesPath();
    for (final dbFile in _dbFiles) {
      final existingFile = await _findExistingFile(driveApi, dbFile);
      if (existingFile != null) {
        final media = await driveApi.files.get(
          existingFile.id!,
          downloadOptions: drive.DownloadOptions.fullMedia,
        );
        if (media is drive.Media) {
          final file = File(p.join(dbPath, dbFile));
          final sink = file.openWrite();
          await media.stream.pipe(sink);
          await sink.close();
          print('✅ הקובץ $dbFile שוחזר מהמגבה ל־Device');
        }
      } else {
        print('⚠️ הקובץ $dbFile לא נמצא ב־Google Drive');
      }
    }
  }

  static Future<drive.File?> _findExistingFile(
    drive.DriveApi api,
    String fileName,
  ) async {
    final files = await api.files.list(
      spaces: 'appDataFolder',
      q: "name='$fileName' and trashed=false",
    );
    return files.files?.isNotEmpty == true ? files.files!.first : null;
  }
}

class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}
