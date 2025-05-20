import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:yaml/yaml.dart';

late Map<String, dynamic> config;
late String version;

Future<void> main() async {
  print("🚀 מתחילים פרסום גרסה...");

  // שלב 1: טען הגדרות מ־deploy_config.json
  final configFile = File('deploy_config.json');
  if (!await configFile.exists()) {
    print("❌ קובץ config לא נמצא!");
    return;
  }
  config = json.decode(await configFile.readAsString());

  // שלב 2: קריאת גרסה מ־pubspec.yaml
  version = await incrementPatchVersionInPubspec();

  // שלב 3: בדוק שה־APK קיים
  final apkFile = File(config['apk_path']);
  if (!await apkFile.exists()) {
    print("❌ קובץ APK לא נמצא: ${config['apk_path']}");
    return;
  }
  print("✅ APK נמצא: ${config['apk_path']}");

  // שלב 4: יצירת ריליס והעלאת APK
  await createGithubRelease();
  await uploadApkToRelease();
  await generateVersionJsonAndPush();
}

// 📤 יצירת Release חדש ב־GitHub
Future<void> createGithubRelease() async {
  print("🚀 יוצרים Release חדש בגיטהאב...");

  final uri = Uri.parse(
    "https://api.github.com/repos/${config['repo']}/releases",
  );
  final headers = {
    'Authorization': 'token ${config['token']}',
    'Accept': 'application/vnd.github+json',
  };

  final body = json.encode({
    "tag_name": "v$version",
    "name": "${config['release_title_prefix']} $version",
    "body": "שחרור גרסה $version",
    "draft": false,
    "prerelease": false,
  });

  final response = await http.post(uri, headers: headers, body: body);

  if (response.statusCode == 201) {
    print("✅ Release נוצר בהצלחה");
  } else if (response.statusCode == 422) {
    print("ℹ️ Release כבר קיים (כנראה שכפול)");
  } else {
    print("❌ שגיאה ביצירת Release: ${response.statusCode}");
    print(response.body);
    exit(1);
  }
}

// 📦 העלאת APK ל־Release שנוצר
Future<void> uploadApkToRelease() async {
  print("📤 מעלים APK ל־Release...");

  final releaseUri = Uri.parse(
    "https://api.github.com/repos/${config['repo']}/releases/tags/v$version",
  );
  final headers = {
    'Authorization': 'token ${config['token']}',
    'Accept': 'application/vnd.github+json',
  };

  final releaseRes = await http.get(releaseUri, headers: headers);
  if (releaseRes.statusCode != 200) {
    print("❌ לא ניתן לאתר את ה־Release שנוצר");
    print(releaseRes.body);
    exit(1);
  }

  final release = json.decode(releaseRes.body);
  final assets = release['assets'] as List<dynamic>;
  final exists = assets.any((a) => a['name'] == 'app-release.apk');
  if (exists) {
    print("ℹ️ הקובץ app-release.apk כבר קיים בריליס – מדלג על העלאה");
    return;
  }

  final uploadUrl = release['upload_url'].toString().replaceAll(
    '{?name,label}',
    '?name=app-release.apk',
  );

  final apkFile = File(config['apk_path']);
  final apkBytes = await apkFile.readAsBytes();

  final uploadRes = await http.post(
    Uri.parse(uploadUrl),
    headers: {
      ...headers,
      'Content-Type': 'application/vnd.android.package-archive',
    },
    body: apkBytes,
  );

  if (uploadRes.statusCode == 201) {
    print("✅ APK הועלה בהצלחה ל־Release");
  } else {
    print("❌ שגיאה בהעלאת APK: ${uploadRes.statusCode}");
    print(uploadRes.body);
    exit(1);
  }
}

Future<void> generateVersionJsonAndPush() async {
  print("📝 מייצר קובץ version.json...");

  // בקשה לשורת שינוי מגרסה
  stdout.write("📋 נא להזין תיאור לגרסה (changelog):\n> ");
  final changelog = stdin.readLineSync() ?? '';

  // כתיבת הקובץ
  final versionJson = {
    "version": version,
    "apkUrl":
        "https://github.com/${config['repo']}/releases/download/v$version/app-release.apk",
    "changelog": changelog,
    "timestamp": DateTime.now().toIso8601String(),
  };

  final file = File("version.json");
  await file.writeAsString(JsonEncoder.withIndent("  ").convert(versionJson));

  print("✅ נוצר version.json");

  // ביצוע git commit ו־push
  final resultAdd = await Process.run('git', ['add', 'version.json']);
  if (resultAdd.exitCode != 0) {
    print("❌ git add נכשל: ${resultAdd.stderr}");
    return;
  }

  final resultCommit = await Process.run('git', [
    'commit',
    '-m',
    '🚀 עדכון גרסה $version',
  ]);
  if (resultCommit.exitCode != 0) {
    print("ℹ️ אין מה לקומט – אולי הקובץ כבר זהה לגרסה הקודמת");
  } else {
    print("✅ בוצע commit");
  }

  final resultPush = await Process.run('git', [
    'push',
    'origin',
    config['branch'],
  ]);
  if (resultPush.exitCode != 0) {
    print("❌ git push נכשל: ${resultPush.stderr}");
    return;
  }

  print("🚀 הקובץ version.json נשלח ל־GitHub בהצלחה");
}

Future<String> incrementPatchVersionInPubspec() async {
  final pubspec = File('pubspec.yaml');
  if (!await pubspec.exists()) {
    print("❌ קובץ pubspec.yaml לא נמצא");
    exit(1);
  }

  final lines = await pubspec.readAsLines();
  final newLines = <String>[];
  String newVersion = '';

  for (final line in lines) {
    if (line.startsWith('version:')) {
      final raw = line.split(':')[1].trim();
      final versionPart = raw.split('+').first;
      final buildPart = raw.contains('+') ? raw.split('+')[1] : '0';
      final parts = versionPart.split('.').map(int.parse).toList();

      parts[2]++; // העלאת ה־patch

      newVersion =
          '${parts.join('.')}${buildPart.isNotEmpty ? '+$buildPart' : ''}';
      print("🔁 גרסה עודכנה ל־$newVersion");

      newLines.add('version: $newVersion');
    } else {
      newLines.add(line);
    }
  }

  await pubspec.writeAsString(newLines.join('\n'));
  return newVersion.split('+').first; // מחזיר רק את המספר בלי ה־build
}
