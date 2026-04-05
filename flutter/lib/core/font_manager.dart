import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Represents a loaded custom font available in the app.
class FontEntry {
  final String displayName;
  final String familyName;
  final String filePath;
  final bool isBundled;
  final DateTime dateAdded;

  const FontEntry({
    required this.displayName,
    required this.familyName,
    required this.filePath,
    required this.isBundled,
    required this.dateAdded,
  });

  Map<String, dynamic> toJson() => {
        'displayName': displayName,
        'familyName': familyName,
        'filePath': filePath,
        'isBundled': isBundled,
        'dateAdded': dateAdded.toIso8601String(),
      };

  factory FontEntry.fromJson(Map<String, dynamic> json) => FontEntry(
        displayName: json['displayName'] as String,
        familyName: json['familyName'] as String,
        filePath: json['filePath'] as String,
        isBundled: json['isBundled'] as bool,
        dateAdded: DateTime.parse(json['dateAdded'] as String),
      );
}

/// Manages font loading, validation, and persistence.
class FontManager {
  static const _prefsKey = 'glyph_fonts';
  static int _fontCounter = 0;

  /// Load a font from raw bytes and register it with Flutter's font system.
  /// Returns the registered family name, or null if loading fails.
  static Future<String?> loadFontFromBytes(
      Uint8List bytes, String familyName) async {
    try {
      final loader = FontLoader(familyName);
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
      await loader.load();
      return familyName;
    } catch (e) {
      return null;
    }
  }

  /// Load a font from a file path on disk.
  static Future<String?> loadFontFromFile(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();
      // Generate a unique family name to avoid collisions
      final familyName = 'CustomFont_${_fontCounter++}_${path.hashCode.abs()}';
      return loadFontFromBytes(bytes, familyName);
    } catch (e) {
      return null;
    }
  }

  /// Pick a font file from the device using the system file picker.
  /// Returns a FontEntry if successful, null otherwise.
  static Future<FontEntry?> pickAndImportFont() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['ttf', 'otf'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return null;
    final file = result.files.first;
    if (file.path == null) return null;

    // Copy to app documents directory for persistence
    final docsDir = await getApplicationDocumentsDirectory();
    final fontsDir = Directory('${docsDir.path}/fonts');
    if (!await fontsDir.exists()) {
      await fontsDir.create(recursive: true);
    }

    final originalFile = File(file.path!);
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
    final destPath = '${fontsDir.path}/$fileName';
    await originalFile.copy(destPath);

    // Load the font
    final familyName = await loadFontFromFile(destPath);
    if (familyName == null) {
      // Clean up the copied file if loading fails
      try {
        await File(destPath).delete();
      } catch (_) {}
      return null;
    }

    // Extract display name from filename (strip extension)
    final displayName = file.name
        .replaceAll(RegExp(r'\.(ttf|otf)$', caseSensitive: false), '')
        .replaceAll(RegExp(r'[-_]'), ' ');

    return FontEntry(
      displayName: displayName,
      familyName: familyName,
      filePath: destPath,
      isBundled: false,
      dateAdded: DateTime.now(),
    );
  }

  /// Save the font list to SharedPreferences.
  static Future<void> saveFontList(List<FontEntry> fonts) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList =
        fonts.where((f) => !f.isBundled).map((f) => f.toJson()).toList();
    await prefs.setString(_prefsKey, jsonEncode(jsonList));
  }

  /// Load the persisted font list and re-register all fonts.
  static Future<List<FontEntry>> loadPersistedFonts() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_prefsKey);
    if (jsonStr == null) return [];

    final List<dynamic> jsonList = jsonDecode(jsonStr) as List<dynamic>;
    final entries = <FontEntry>[];

    for (final json in jsonList) {
      final entry = FontEntry.fromJson(json as Map<String, dynamic>);
      // Re-register the font
      final loaded = await loadFontFromFile(entry.filePath);
      if (loaded != null) {
        // Update with new family name from this session's loader
        entries.add(FontEntry(
          displayName: entry.displayName,
          familyName: loaded,
          filePath: entry.filePath,
          isBundled: false,
          dateAdded: entry.dateAdded,
        ));
      }
    }

    return entries;
  }

  /// Delete a font entry — removes the file and updates persistence.
  static Future<void> deleteFont(FontEntry entry) async {
    if (entry.isBundled) return;
    try {
      final file = File(entry.filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}

/// Riverpod state for the font list.
class FontListNotifier extends StateNotifier<List<FontEntry>> {
  FontListNotifier() : super([]) {
    _init();
  }

  Future<void> _init() async {
    // Load persisted custom fonts
    final persisted = await FontManager.loadPersistedFonts();
    state = [..._bundledFonts, ...persisted];
  }

  /// Bundled fonts that ship with the app — all Google Fonts loaded dynamically.
  static final List<FontEntry> _bundledFonts = [
    FontEntry(
      displayName: 'Playfair Display',
      familyName: 'Playfair Display',
      filePath: '',
      isBundled: true,
      dateAdded: DateTime(2024),
    ),
    FontEntry(
      displayName: 'Space Grotesk',
      familyName: 'Space Grotesk',
      filePath: '',
      isBundled: true,
      dateAdded: DateTime(2024),
    ),
    FontEntry(
      displayName: 'Archivo Black',
      familyName: 'Archivo Black',
      filePath: '',
      isBundled: true,
      dateAdded: DateTime(2024),
    ),
    FontEntry(
      displayName: 'Caveat',
      familyName: 'Caveat',
      filePath: '',
      isBundled: true,
      dateAdded: DateTime(2024),
    ),
    FontEntry(
      displayName: 'DM Serif Display',
      familyName: 'DM Serif Display',
      filePath: '',
      isBundled: true,
      dateAdded: DateTime(2024),
    ),
  ];

  Future<FontEntry?> importFont() async {
    final entry = await FontManager.pickAndImportFont();
    if (entry == null) return null;
    state = [...state, entry];
    await FontManager.saveFontList(state);
    return entry;
  }

  Future<void> removeFont(FontEntry entry) async {
    await FontManager.deleteFont(entry);
    state = state.where((f) => f.familyName != entry.familyName).toList();
    await FontManager.saveFontList(state);
  }
}

final fontListProvider =
    StateNotifierProvider<FontListNotifier, List<FontEntry>>(
  (ref) => FontListNotifier(),
);
