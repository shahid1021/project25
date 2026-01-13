import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  List<String> uploadedFiles = [];

  Future<bool> requestStoragePermission() async {
    // Simple storage permission for Android 10 and below
    if (await Permission.storage.isGranted) return true;

    var status = await Permission.storage.request();

    if (status.isGranted) return true;

    // Android 13+ automatically splits permissions
    if (await Permission.photos.isGranted ||
        await Permission.videos.isGranted ||
        await Permission.audio.isGranted) {
      return true;
    }

    // If nothing works → send user to settings
    await openAppSettings();
    return false;
  }

  // ⭐ File Picker Function
  Future<void> pickFile() async {
    print("PICKER OPENING...");

    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
      withData: true,
      withReadStream: true,
    );

    print("PICKER RAN");

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;

      setState(() {
        uploadedFiles.add(file.name);
      });

      print("FILE SELECTED → ${file.name}");
    } else {
      print("User cancelled");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text(
          "Upload Files",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      body: Padding(
        padding: const EdgeInsets.all(240),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Upload your project files:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.upload_file),
                label: const Text(
                  "Choose File",
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFE5A72E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),

                onPressed: () async {
                  print("BUTTON WORKED");

                  // STEP 1 → Ask Vivo for FULL FILE ACCESS
                  bool allowed = await requestStoragePermission();
                  if (!allowed) {
                    print("Permission not granted");
                    return;
                  }

                  // STEP 2 → Open file picker
                  await pickFile();
                },
              ),
            ),

            const SizedBox(height: 80),
            if (uploadedFiles.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    print("PUBLISH CLICKED");
                    // Here you will later add database upload code
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFE5A72E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Publish",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
