// import 'dart:developer';
// import 'dart:io';
// import 'dart:typed_data';

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:firebase_storage/firebase_storage.dart';

// void pickFiles() async {
//   FilePickerResult? result = await FilePicker.platform
//       .pickFiles(withReadStream: true, type: FileType.image);
//   log('result: ${result!.files.first.name}');

//   if (result != null) {
//     File file = File(result.files.single.path!);
//     Uint8List fileBytes = await file.readAsBytes();
//     log('Files: ${file.uri}');
//     UploadTask task =
//         FirebaseStorage.instance.ref('images/vegies/$file').putData(fileBytes);
//     TaskSnapshot snap = await task;
//     String downloadUrl = await snap.ref.getDownloadURL();

//     FirebaseFirestore.instance.collection('files').add({
//       'name': file.uri,
//       'url': downloadUrl,
//     });
//   }
// }
