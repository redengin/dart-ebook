library ebook;

import 'dart:convert';

import 'package:archive/archive_io.dart';
import 'package:xml/xml.dart';
import 'package:xml/xpath.dart';

class EBook {
  late final Archive _archive;
  String? _rootPath;
  EBookInfo? _ebookInfo;

  EBook(String path) {
    _archive = ZipDecoder().decodeBuffer(InputFileStream(path));
  }

  bool validateMimeType() {
    var file = _archive.findFile("mimetype");
    if (file == null) return false;
    return String.fromCharCodes(file.content) == "application/epub+zip";
  }

  bool validateContainer() {
    var file = _archive.findFile("META-INF/container.xml");
    if (file == null) return false;
    var document = XmlDocument.parse(utf8.decode(file.content));
    var roots = document.xpath("container/rootfiles/rootfile");
    if ((roots.length > 1) ||
        (roots.first.getAttribute("media-type") !=
            "application/oebps-package+xml")) {
      return false;
    }
    _rootPath = roots.first.getAttribute("full-path");
    return true;
  }

  EBookInfo? getInfo() {
    if(_ebookInfo != null) return _ebookInfo;

    String? rootPath = _rootPath ?? _getRootPath();
    if(rootPath == null) return null;
    var file = _archive.findFile(rootPath);
    if (file == null) return null;

    var document = XmlDocument.parse(utf8.decode(file.content));
    final identifiers = document.xpath('package/metadata/identifier')
        .map((node) => node.innerText)
        .toList(growable: false);
    final titles = document.xpath('package/metadata/title')
        .map((node) => node.innerText)
        .toList(growable: false);
    final languages = document.xpath('package/metadata/language')
        .map((node) => node.innerText)
        .toList(growable: false);
    final coverImageRefs = document.xpath('package/manifest/item[@properties="cover-image"]')
        .map((node) => CoverImageRef(node.getAttribute("href"), node.getAttribute("media-type")))
        .toList(growable: false);
    // memo the info so we don't need to reparse
    _ebookInfo = EBookInfo(identifiers, titles, languages, coverImageRefs);

    return _ebookInfo;
  }

  String? _getRootPath() {
    var file = _archive.findFile("META-INF/container.xml");
    if (file == null) return null;
    var document = XmlDocument.parse(utf8.decode(file.content));
    var roots = document.xpath("container/rootfiles/rootfile");
    // memo the rootPath so we don't need to reparse
    _rootPath = roots.first.getAttribute("full-path");
    return _rootPath;
  }
}

class EBookInfo {
  final List<String> identifiers;
  final List<String> titles;
  final List<String> languages;
  final List<CoverImageRef> coverImageRefs;

  EBookInfo(this.identifiers, this.titles, this.languages, this.coverImageRefs);
}

class CoverImageRef {
  final String? href;
  final String? mediaType;

  CoverImageRef(this.href, this.mediaType);
}
