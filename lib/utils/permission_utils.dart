import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

class PermissionUtils {

  static Future<bool> requestStoragePermission() async {
    try {
      var status = await Permission.storage.status;
      
      if (status.isGranted) {
        return true;
      }
      
      status = await Permission.storage.request();
      
      if (!status.isGranted) {
        if (status.isPermanentlyDenied) {
          await openAppSettings();
        }
        return false;
      }
      
      if (Platform.isAndroid) {
        final androidStatus = await Permission.manageExternalStorage.status;
        if (!androidStatus.isGranted) {
          final result = await Permission.manageExternalStorage.request();
          return result.isGranted;
        }
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> checkStoragePermission() async {
    try {
      var status = await Permission.storage.status;
      
      if (!status.isGranted) {
        return false;
      }
      
      if (Platform.isAndroid) {
        final androidStatus = await Permission.manageExternalStorage.status;
        return androidStatus.isGranted || !androidStatus.isDenied;
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> requestCameraPermission() async {
    try {
      var status = await Permission.camera.status;
      
      if (status.isGranted) {
        return true;
      }
      
      status = await Permission.camera.request();
      
      if (!status.isGranted) {
        if (status.isPermanentlyDenied) {
          await openAppSettings();
        }
        return false;
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> requestPhotosPermission() async {
    try {
      var status = await Permission.photos.status;
      
      if (status.isGranted) {
        return true;
      }
      
      status = await Permission.photos.request();
      
      if (!status.isGranted) {
        if (status.isPermanentlyDenied) {
          await openAppSettings();
        }
        return false;
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> requestNotificationPermission() async {
    try {
      var status = await Permission.notification.status;
      
      if (status.isGranted) {
        return true;
      }
      
      status = await Permission.notification.request();
      
      return status.isGranted;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> openAppSettings() async {
    try {
      return await openAppSettings();
    } catch (e) {
      return false;
    }
  }

  static Future<bool> ensureDownloadPermission() async {
    final hasPermission = await requestStoragePermission();
    
    if (!hasPermission) {
      return false;
    }
    
    return true;
  }
}
