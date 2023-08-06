library ebook;

import 'dart:io';

import 'package:archive/archive_io.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:xml/xml.dart';
import 'package:xml/xpath.dart';
import 'package:path/path.dart' as Path;

class EBook {
  final File file;
  late final Archive _archive;
  EBookInfo? _ebookInfo;

  EBook(this.file) {
    _archive = ZipDecoder().decodeBuffer(InputFileStream(this.file.path));
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
    _rootfilePath = roots.first.getAttribute("full-path");
    return true;
  }

  EBookInfo? getInfo() {
    if(_ebookInfo != null) return _ebookInfo;

    String? rootPath = _getRootfilePath();
    if(rootPath == null) return null;
    var file = _archive.findFile(rootPath);
    if (file == null) return null;

    var document = XmlDocument.parse(utf8.decode(file.content));
    // FIXME dc namespace is not a requirement, but this xpath doesn't support local-name()
    final identifiers = document.xpath('//package/metadata/dc:identifier')
        .map((node) => node.innerText)
        .toList(growable: false);
    final titles = document.xpath('//package/metadata/dc:title')
        .map((node) => node.innerText)
        .toList(growable: false);
    final languages = document.xpath('//package/metadata/dc:language')
        .map((node) => node.innerText)
        .toList(growable: false);
    final coverImageRefs = document.xpath('package/manifest/item[@properties="cover-image"]')
        .map((node) => ImageRef(node.getAttribute("href")!, node.getAttribute("media-type")))
        .toList(growable: false);
    // memo the info so we don't need to reparse
    _ebookInfo = EBookInfo(this, identifiers, titles, languages, coverImageRefs);

    return _ebookInfo;
  }

  Uint8List? readContainerFile(String href) {
    var containerPath = _getContainerPath();
    if(containerPath == null)
      return null;

    var file = _archive.findFile(Path.join(containerPath, href));
    if(file == null)
      return null;

    return file.content;
  }

  String? _rootfilePath;
  String? _getRootfilePath() {
    // shortcut if we've already found the file
    if(_rootfilePath != null)
      return _rootfilePath;

    // parse the container.xml
    var file = _archive.findFile("META-INF/container.xml");
    if (file == null) return null;
    var document = XmlDocument.parse(utf8.decode(file.content));
    var roots = document.xpath("container/rootfiles/rootfile");
    // memo the rootPath so we don't need to reparse
    _rootfilePath = roots.first.getAttribute("full-path");
    return _rootfilePath;
  }

  String? _getContainerPath() {
    final rootfilePath = _getRootfilePath();
    if(rootfilePath == null)
      return null;
    return Path.dirname(rootfilePath);
  }
}

class EBookInfo {
  final EBook ebook;
  final List<String> identifiers;
  final List<String> titles;
  final List<String> languages;
  final List<ImageRef> coverImageRefs;

  EBookInfo(this.ebook, this.identifiers, this.titles, this.languages, this.coverImageRefs);
}

class ImageRef {
  final String href;
  final String? mediaType;

  ImageRef(this.href, this.mediaType);
}
