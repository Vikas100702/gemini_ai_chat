import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:gemini_ai_chat/core/constants/app_constants.dart';
import 'package:gemini_ai_chat/core/errors/app_exception.dart';
import 'package:image_picker/image_picker.dart';

/// Purpose:
/// Contract for local media and hardware operations (camera, gallery, and file selection).
///
/// Task:
/// 1. Abstracts the third-party [ImagePicker] library behind a clean interface.
/// 2. Ensures the rest of the application remains isolated from platform channels.
abstract interface class MediaLocalDataSource {
  /// What it does:
  /// Captures an image from the camera or picks an existing image from the gallery.
  ///
  /// Why it is needed:
  /// Supplies raw image bytes to the AI repository for multimodal analysis.
  ///
  /// How it works:
  /// - [source]: Specifies [ImageSource.camera] or [ImageSource.gallery].
  ///
  /// Returns:
  /// A [Future] that resolves to raw image bytes ([Uint8List]) or `null` if cancelled.
  Future<Uint8List?> pickImage(ImageSource source);
}

/// Purpose:
/// Production implementation of [MediaLocalDataSource] using [ImagePicker].
///
/// Task:
/// 1. Interacts with native camera and gallery platform channels safely.
/// 2. Applies automatic image compression to prevent Out-of-Memory (OOM) crashes.
/// 3. Validates file size thresholds and converts platform errors into typed domain exceptions.
class MediaLocalDataSourceImpl implements MediaLocalDataSource {
  /// What it does:
  /// Initializes the local media data-source with an optional [ImagePicker] client.
  ///
  /// Why it is needed:
  /// Allows injecting mock picker instances during unit and widget testing.
  ///
  /// How it works:
  /// Defaults to a standard [ImagePicker] if no custom instance is provided.
  MediaLocalDataSourceImpl({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  /// Internal reference to the Flutter ImagePicker plugin.
  final ImagePicker _picker;

  /// What it does:
  /// Opens the device camera or gallery to acquire an image file.
  ///
  /// Why it is needed:
  /// Enables multimodal image chats with Gemini AI while protecting system memory.
  ///
  /// How it works:
  /// 1. Invokes the native image picker with downscaling parameters (max 1024 x 1024, 85% quality).
  /// 2. If the user cancels or closes the dialog, returns `null` immediately.
  /// 3. Converts the selected file into raw bytes.
  /// 4. Checks that the total byte size does not exceed the 4MB limit[cite: 1, 2].
  /// 5. Wraps any platform channel denials or hardware errors into [MediaDeviceException][cite: 1].
  @override
  Future<Uint8List?> pickImage(ImageSource source) async {
    try {
      // Step 1: Open the hardware picker with memory-safe dimensions
      final XFile? file = await _picker.pickImage(source: source, maxWidth: 1024, maxHeight: 1024, imageQuality: 85);

      // Step 2: Handle user cancellation safely without throwing an error
      if (file == null) {
        return null;
      }

      // Step 3: Read file contents into a raw byte buffer
      final Uint8List bytes = await file.readAsBytes();

      // Step 4: Validate image size against our safety guard limit (4 megabytes)[cite: 1, 2]
      if (bytes.lengthInBytes > AppConstants.maxImageSizeInBytes) {
        throw const PayloadSizeLimitException(message: 'The selected image exceeds the maximum supported threshold of 4MB.', code: 'IMAGE_TOO_LARGE');
      }

      return bytes;
    } on PlatformException catch (e, stackTrace) {
      // Step 5a: Catch device permission denials or camera access restrictions
      if (kDebugMode) {
        debugPrint('[MediaLocalDataSourceImpl.pickImage PlatformException]: $e\n$stackTrace');
      }
      throw MediaDeviceException(
        message: 'Could not access the camera or photo library. Please grant permissions in your device settings.',
        code: 'MEDIA_PERMISSION_DENIED',
        stackTrace: stackTrace,
      );
    } on AppException {
      // Step 5b: Re-throw known domain exceptions (like PayloadSizeLimitException)
      rethrow;
    } catch (e, stackTrace) {
      // Step 5c: Catch unexpected I/O or filesystem errors
      if (kDebugMode) {
        debugPrint('[MediaLocalDataSourceImpl.pickImage Unknown Exception]: $e\n$stackTrace');
      }
      throw MediaDeviceException(message: 'An error occurred while loading the image: $e', code: 'HARDWARE_IO_ERROR', stackTrace: stackTrace);
    }
  }
}
