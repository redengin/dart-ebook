import 'dart:js_interop';

import 'package:test/test.dart';

import 'package:ebook/ebook.dart';
import 'dart:io';
import 'package:path/path.dart' as Path;

final Uri referenceEbookUrl = Uri.parse(
    "https://github.com/IDPF/epub3-samples/releases/download/20170606/accessible_epub_3.epub");

void main() async {
  final request = await HttpClient().getUrl(referenceEbookUrl);
  final response = await request.close();
  final tmpDir = await Directory(".").createTemp("ebook-test-");
  final tmpFile = await File(Path.join(tmpDir.path, "ebook.pub"));
  final ebook_data = await response.pipe(
    tmpFile.openWrite()
  );
  final ebook = EBook(tmpFile.path);

  test('validate epub3 mimetype', () {
    assert(ebook.validateMimeType());
  });

  test('validate META-INF/container.xml', () {
    assert(ebook.validateContainer());
  });

  test('get EBook Info', () {
    var info = ebook.getInfo();
    assert(info!.identifiers.isNotEmpty);
    assert(info!.titles.isNotEmpty);
    assert(info!.languages.isNotEmpty);
    assert(info!.coverImageRefs.isNotEmpty);
    assert(ebook.getImage(info!.coverImageRefs[0])!.lengthInBytes > 0);
  });

  tmpDir.delete(recursive: true);
}
