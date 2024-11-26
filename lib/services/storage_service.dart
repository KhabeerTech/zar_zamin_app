import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class StorageService {
  static final supabase = Supabase.instance.client;
  static const String BUCKET_NAME = 'worker-images';

  // Rasmni yuklash
  static Future<String?> uploadImage(File imageFile) async {
    File? compressedFile;
    try {
      debugPrint('Rasm yuklash boshlandi...');

      // Fayl hajmini tekshirish
      final fileSize = await imageFile.length();
      debugPrint(
          'Asl rasm hajmi: ${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB');

      if (fileSize > 10 * 1024 * 1024) {
        throw Exception(
            'Rasm hajmi juda katta. Iltimos, kichikroq rasm tanlang');
      }

      // Rasm hajmi katta bo'lsa, kichraytirish
      File fileToUpload = imageFile;
      if (fileSize > 2 * 1024 * 1024) {
        debugPrint('Rasm hajmi 2MB dan katta, kichraytirilmoqda...');
        compressedFile = await _compressImage(imageFile);
        if (compressedFile != null) {
          fileToUpload = compressedFile;
          final compressedSize = await compressedFile.length();
          debugPrint(
              'Kichraytirilgan rasm hajmi: ${(compressedSize / 1024 / 1024).toStringAsFixed(2)}MB');
        }
      }

      // Fayl nomini yaratish
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}${path.extension(fileToUpload.path)}';
      debugPrint('Yuklanmoqda: $fileName');

      // Rasmni baytlarga o'girish
      final bytes = await fileToUpload.readAsBytes();
      debugPrint('Fayl baytlarga o\'girildi, hajmi: ${bytes.length} bytes');

      // Supabase Storage'ga yuklash
      final response = await supabase.storage.from(BUCKET_NAME).uploadBinary(
            fileName,
            bytes,
            fileOptions:
                const FileOptions(contentType: 'image/jpeg', upsert: false),
          );

      if (response == null || response.isEmpty) {
        throw Exception(
            'Rasmni yuklab bo\'lmadi. Iltimos, qayta urinib ko\'ring');
      }

      // Yuklangan rasm URL manzilini olish
      final imageUrl =
          supabase.storage.from(BUCKET_NAME).getPublicUrl(fileName);
      debugPrint('Rasm muvaffaqiyatli yuklandi: $imageUrl');

      return imageUrl;
    } catch (e) {
      debugPrint('Rasmni yuklashda muammo: $e');
      rethrow;
    } finally {
      if (compressedFile != null) {
        try {
          await compressedFile.delete();
          debugPrint('Vaqtinchalik fayl o\'chirildi');
        } catch (e) {
          debugPrint('Vaqtinchalik faylni o\'chirishda muammo: $e');
        }
      }
    }
  }

  // Rasmni kichraytirish
  static Future<File?> _compressImage(File imageFile) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath =
          path.join(dir.path, 'compressed_${path.basename(imageFile.path)}');

      debugPrint('Rasm kichraytirilmoqda...');
      var result = await FlutterImageCompress.compressAndGetFile(
        imageFile.path,
        targetPath,
        quality: 85,
        minWidth: 1024,
        minHeight: 1024,
        format: CompressFormat.jpeg,
        keepExif: true,
      );

      if (result != null) {
        final compressedSize = await result.length();
        final originalSize = await imageFile.length();
        final compressionRatio =
            (compressedSize / originalSize * 100).toStringAsFixed(2);
        debugPrint('Kichraytirish natijasi:');
        debugPrint(
            '- Asl hajm: ${(originalSize / 1024 / 1024).toStringAsFixed(2)}MB');
        debugPrint(
            '- Kichraytirilgan hajm: ${(compressedSize / 1024 / 1024).toStringAsFixed(2)}MB');
        debugPrint('- Kichraytirish foizi: $compressionRatio%');
      }

      return result != null ? File(result.path) : null;
    } catch (e) {
      debugPrint('Rasmni kichraytirishda muammo: $e');
      return null;
    }
  }

  // Rasmni o'chirish
  static Future<bool> deleteImage(String imageUrl) async {
    try {
      final uri = Uri.parse(imageUrl);
      final fileName = path.basename(uri.path);

      await supabase.storage.from(BUCKET_NAME).remove([fileName]);
      debugPrint('Rasm muvaffaqiyatli o\'chirildi');
      return true;
    } catch (e) {
      debugPrint('Rasmni o\'chirishda muammo: $e');
      return false;
    }
  }
}
