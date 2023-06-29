library ebook;

import 'dart:convert';

import 'package:archive/archive_io.dart';
import 'package:xml/xml.dart';

class EBook {
  late final Archive _archive;

  EBook(String path) {
    _archive = ZipDecoder().decodeBuffer(InputFileStream(path));
  }

  bool validateMimeType() {
    var file = _archive.findFile("mimetype");
    if(file == null) return false;
    return String.fromCharCodes(file.content) == "application/epub+zip";
  }

  bool validateContainer() {
    var file = _archive.findFile("META-INF/container.xml");
    if(file == null) return false;
    var containerDocument = XmlDocument.parse(utf8.decode(file.content));
    var roots = containerDocument.findAllElements("rootfile");
    return roots.length == 1;
  }

// final ZipFile zipfile;
//
// Ebook(istream) {
//   this.zipFile = ZipFile(istream);
// }
//
}
