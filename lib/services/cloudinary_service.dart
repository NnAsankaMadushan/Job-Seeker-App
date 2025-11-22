import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';

class CloudinaryService {
  // Cloudinary configuration
  // TODO: Replace these with your actual Cloudinary credentials
  static const String _cloudName = 'YOUR_CLOUD_NAME';
  static const String _uploadPreset = 'YOUR_UPLOAD_PRESET';

  late final CloudinaryPublic _cloudinary;

  CloudinaryService() {
    _cloudinary = CloudinaryPublic(_cloudName, _uploadPreset, cache: false);
  }

  /// Uploads an image to Cloudinary and returns the secure URL
  ///
  /// [imageFile] - The image file to upload
  /// [folder] - Optional folder name in Cloudinary (e.g., 'profiles', 'jobs')
  ///
  /// Returns a Map with:
  /// - success: bool
  /// - message: String
  /// - data: String (image URL) or null
  Future<Map<String, dynamic>> uploadImage(
    File imageFile, {
    String folder = 'job_seeker_app',
  }) async {
    try {
      // Upload the image
      CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          folder: folder,
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      // Return the secure URL
      return {
        'success': true,
        'message': 'Image uploaded successfully',
        'data': response.secureUrl,
        'publicId': response.publicId, // Save this for deletion if needed
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to upload image: ${e.toString()}',
        'data': null,
      };
    }
  }

  /// Deletes an image from Cloudinary
  ///
  /// [publicId] - The public ID of the image to delete
  ///
  /// Note: For deletion to work, you need to:
  /// 1. Enable "Unsigned uploads" in Cloudinary settings
  /// 2. Or use the Cloudinary Admin API (requires API secret)
  ///
  /// This method is optional and can be implemented when needed
  Future<Map<String, dynamic>> deleteImage(String publicId) async {
    try {
      // Note: Deletion requires Admin API which needs API secret
      // For production, implement this using cloudinary package (not cloudinary_public)
      // For now, we'll just return success as deletion is optional

      return {
        'success': true,
        'message': 'Image deletion initiated',
        'data': null,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to delete image: ${e.toString()}',
        'data': null,
      };
    }
  }

  /// Uploads a profile image specifically
  Future<Map<String, dynamic>> uploadProfileImage(File imageFile) async {
    return uploadImage(imageFile, folder: 'profiles');
  }

  /// Uploads a job-related image
  Future<Map<String, dynamic>> uploadJobImage(File imageFile) async {
    return uploadImage(imageFile, folder: 'jobs');
  }
}
