import 'dart:io';
import 'package:path_provider/path_provider.dart';

class FileHelper {
  static Future<Map<String, String>> buatFolderDefault() async {
    final Directory baseDir     = await getApplicationDocumentsDirectory();
    final Directory dataDir     = Directory('${baseDir.path}/data');
    final Directory gambar1Dir  = Directory('${dataDir.path}/input/gambar1');
    final Directory gambar2Dir  = Directory('${dataDir.path}/input/gambar2');
    final Directory csvDir      = Directory('${dataDir.path}/input/csv');
    final Directory exportDir   = Directory('${dataDir.path}/export');
    final Directory logDir      = Directory('${dataDir.path}/log');

    for (final dir in [dataDir, gambar1Dir, gambar2Dir, csvDir, exportDir, logDir]) {
      if (!(await dir.exists())) {
        await dir.create(recursive: true);
      }
    }

    return {
      'base'    : dataDir.path,
      'log'     : logDir.path,
      'gambar1' : gambar1Dir.path,
      'gambar2' : gambar2Dir.path,
      'csv'     : csvDir.path,
      'export'  : exportDir.path,
    };
  }
}
