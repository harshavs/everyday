import 'dart:convert';
import 'package:everyday/models/goal.dart';
import 'package:everyday/services/google_auth_service.dart';
import 'package:googleapis/drive/v3.dart' as drive;

class GoogleDriveService {
  final GoogleAuthService _authService;
  static const String _fileName = 'goals.json';

  GoogleDriveService(this._authService);

  Future<drive.DriveApi?> _getDriveApi() async {
    final client = await _authService.authenticatedClient;
    if (client == null) {
      return null;
    }
    return drive.DriveApi(client);
  }

  Future<void> uploadGoals(List<Goal> goals) async {
    final driveApi = await _getDriveApi();
    if (driveApi == null) {
      print('Not signed in. Cannot upload goals.');
      return;
    }

    final goalsJson = jsonEncode(goals.map((g) => g.toJson()).toList());
    final media = drive.Media(
        Stream.value(utf8.encode(goalsJson)), utf8.encode(goalsJson).length,
        contentType: 'application/json; charset=UTF-8');

    final fileId = await _getFileId(driveApi);
    final fileMetadata = drive.File()..name = _fileName;

    if (fileId == null) {
      fileMetadata.parents = ['appDataFolder'];
      await driveApi.files.create(fileMetadata, uploadMedia: media);
      print('Goals uploaded to new file.');
    } else {
      await driveApi.files.update(fileMetadata, fileId, uploadMedia: media);
      print('Goals updated in existing file.');
    }
  }

  Future<List<Goal>?> downloadGoals() async {
    final driveApi = await _getDriveApi();
    if (driveApi == null) {
      print('Not signed in. Cannot download goals.');
      return null;
    }

    final fileId = await _getFileId(driveApi);
    if (fileId == null) {
      print('No backup file found.');
      return [];
    }

    final media = await driveApi.files.get(fileId, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;

    final contentStream = media.stream.transform(utf8.decoder);
    final content = await contentStream.join();

    final List<dynamic> jsonList = jsonDecode(content);
    return jsonList.map((json) => Goal.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<String?> _getFileId(drive.DriveApi driveApi) async {
    try {
      final fileList = await driveApi.files.list(
        q: "name='$_fileName' and trashed = false",
        spaces: 'appDataFolder',
        $fields: 'files(id, name)',
      );

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        return fileList.files!.first.id;
      }
      return null;
    } catch (e) {
      print('Error finding file: $e');
      return null;
    }
  }
}