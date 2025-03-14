import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:talent_turbo_new/AppColors.dart';
import 'package:talent_turbo_new/AppConstants.dart';
import 'package:talent_turbo_new/Utils.dart';
import 'package:talent_turbo_new/docx_viewer.dart';
import 'package:talent_turbo_new/models/candidate_profile_model.dart';
import 'package:talent_turbo_new/models/login_data_model.dart';
import 'package:talent_turbo_new/models/user_data_model.dart';
import 'package:talent_turbo_new/progress_dialog.dart';
import 'package:talent_turbo_new/screens/editPhoto/editphoto.dart';
import 'package:talent_turbo_new/screens/main/AddDeleteSkills.dart';
import 'package:talent_turbo_new/screens/main/AddEducation.dart';
import 'package:talent_turbo_new/screens/main/AddEmployment.dart';
import 'package:talent_turbo_new/screens/main/edit_personal_details.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class PersonalDetails extends StatefulWidget {
  const PersonalDetails({super.key});

  @override
  State<PersonalDetails> createState() => _PersonalDetailsState();
}

class _PersonalDetailsState extends State<PersonalDetails> {
  bool isLoading = false;
  final databaseRef =
      FirebaseDatabase.instance.ref().child(AppConstants.APP_NAME);
  List<String> userSkills = [];

  List<dynamic> educationList = [];
  List<dynamic> workList = [];
  List<dynamic> skillsList = [];

  var resumeData = null;
  CandidateProfileModel? candidateProfileModel;
  UserData? retrievedUserData;

  String email = '';
  String resumeUpdatedDate = '';

  Future<void> deleteEducation(String id) async {
    final url = Uri.parse(
        AppConstants.BASE_URL + AppConstants.DELETE_EDUCATION + '/${id}');

    try {
      setState(() {
        isLoading = true;
      });

      Fluttertoast.showToast(
          msg: 'Deleting education detail. Please wait.',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Color(0xff2D2D2D),
          textColor: Colors.white,
          fontSize: 16.0);

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': retrievedUserData!.token
        },
      );

      if (kDebugMode) {
        print(
            'Response code ${response.statusCode} :: Response => ${response.body}');
      }

      Fluttertoast.showToast(
          msg: 'Deleted education detail successfully',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Color(0xff2D2D2D),
          textColor: Colors.white,
          fontSize: 16.0);

      if (response.statusCode == 200 || response.statusCode == 202) {
        Fluttertoast.showToast(
            msg: 'Refreshing profile. Please wait a moment',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Color(0xff2D2D2D),
            textColor: Colors.white,
            fontSize: 16.0);
        fetchCandidateProfileData(
            retrievedUserData!.profileId, retrievedUserData!.token);
      }
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
    }
  }

  String formatDate(String date) {
    if (date == '1970-01-01') return 'Present'; // Handle "Present" case
    try {
      DateTime parsedDate = DateTime.parse(date);
      return DateFormat('dd-MMM-yyyy').format(parsedDate);
    } catch (e) {
      return date;
    }
  }

  Future<void> deleteEmployment(String id) async {
    final url = Uri.parse(
        AppConstants.BASE_URL + AppConstants.DELETE_EMPLOYMENT + '/${id}');

    try {
      setState(() {
        isLoading = true;
      });

      Fluttertoast.showToast(
          msg: 'Deleting experience detail. Please wait.',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Color(0xff2D2D2D),
          textColor: Colors.white,
          fontSize: 16.0);

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': retrievedUserData!.token
        },
      );

      if (kDebugMode) {
        print(
            'Response code ${response.statusCode} :: Response => ${response.body}');
      }

      Fluttertoast.showToast(
          msg: 'Deleted experience detail successfully',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Color(0xff2D2D2D),
          textColor: Colors.white,
          fontSize: 16.0);

      if (response.statusCode == 200 || response.statusCode == 202) {
        Fluttertoast.showToast(
            msg: 'Refreshing profile. Please wait a moment',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Color(0xff2D2D2D),
            textColor: Colors.white,
            fontSize: 16.0);
        fetchCandidateProfileData(
            retrievedUserData!.profileId, retrievedUserData!.token);
      }
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
    }
  }

  Future<void> deleteResume(int id) async {
    final url =
        Uri.parse(AppConstants.BASE_URL + AppConstants.DELETE_RESUME + '${id}');

    try {
      setState(() {
        isLoading = true;
      });

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': retrievedUserData!.token
        },
      );

      if (kDebugMode) {
        print(
            'Response code ${response.statusCode} :: Response => ${response.body}');
      }

      Fluttertoast.showToast(
          msg: 'Resume deleted successfully',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Color(0xff2D2D2D),
          textColor: Colors.white,
          fontSize: 16.0);

      if (response.statusCode == 200 || response.statusCode == 202) {
        Fluttertoast.showToast(
            msg: 'Refreshing profile. Please wait a moment',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Color(0xff2D2D2D),
            textColor: Colors.white,
            fontSize: 16.0);
        fetchCandidateProfileData(
            retrievedUserData!.profileId, retrievedUserData!.token);
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  Future<void> fetchSkills() async {
    final String sanitizedEmail = email.replaceAll('.', ',');
    final DatabaseReference skillRef =
        databaseRef.child('$sanitizedEmail/mySkills');

    // Listen for value changes in Firebase
    skillRef.onValue.listen((event) {
      final Map<dynamic, dynamic>? data = event.snapshot.value as Map?;
      if (data != null) {
        setState(() {
          userSkills = data.values.cast<String>().toList();
          //skillKeys = data.map((key, value) => MapEntry(value, key));
          isLoading = false;
        });
      } else {
        setState(() {
          userSkills = [];
          //skillKeys = {};
          isLoading = false;
        });
      }
    });
  }

  Future<void> _launchURL() async {
    final String? filePath = candidateProfileModel?.filePath;

    if (filePath != null && await canLaunchUrl(Uri.parse(filePath))) {
      //await launchUrlString(filePath, mode: LaunchMode.externalApplication);
      await launchUrl(Uri.parse(filePath));
      //await launch(filePath, forceSafariVC: false, forceWebView: false);
    } else {
      Fluttertoast.showToast(
          msg: 'Could not launch ${filePath}',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Color(0xff2D2D2D),
          textColor: Colors.white,
          fontSize: 16.0);
      throw 'Could not launch ${candidateProfileModel!.filePath}';
    }
  }

  Future<void> fetchCandidateProfileData(int profileId, String token,
      [int show = 1]) async {
    //final url = Uri.parse(AppConstants.BASE_URL + AppConstants.REFERRAL_PROFILE + profileId.toString());
    final url = Uri.parse(AppConstants.BASE_URL +
        AppConstants.CANDIDATE_PROFILE +
        profileId.toString());

    try {
      setState(() {
        isLoading = true;
      });

      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json', 'Authorization': token},
      );

      if (kDebugMode) {
        //Debug mode print
        print(
            'Response code ${response.statusCode} :: Response => ${response.body}');
      }

      if (response.statusCode == 200) {
        var resOBJ = jsonDecode(response.body);

        String statusMessage = resOBJ['message'];

        if (statusMessage.toLowerCase().contains('success')) {
          if (show == 1) {
            Fluttertoast.showToast(
                msg: 'Personal details updated successfully',
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
                timeInSecForIosWeb: 1,
                backgroundColor: Color(0xff2D2D2D),
                textColor: Colors.white,
                fontSize: 16.0);
          }
          final Map<String, dynamic> data = resOBJ['data'];
          //ReferralData referralData = ReferralData.fromJson(data);
          CandidateProfileModel candidateData =
              CandidateProfileModel.fromJson(data);

          await saveCandidateProfileData(candidateData);

          /*Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => PersonalDetails()),
                (Route<dynamic> route) => route.isFirst, // This will keep Screen 1
          );*/

          //Navigator.pop(context);
          fetchProfileFromPref();
          setState(() {
            isLoading = false;
          });
        }
      } else {
        print(response);
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print(e);
    }
  }

  bool _isValidExtension(String extension) {
    const allowedExtensions = ['pdf', 'doc', 'docx'];
    return allowedExtensions.contains(extension);
  }

  Future<File?> pickPDF() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      //allowedExtensions: ['pdf'],
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);

      String extension = file.path.split('.').last.toLowerCase();
      if (!_isValidExtension(extension)) {
        Fluttertoast.showToast(
            msg: 'Unsupported file type.',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Color(0xff2D2D2D),
            textColor: Colors.white,
            fontSize: 16.0);

        return null;
      }

      final fileSize = await file.length(); // Get file size in bytes
      if (fileSize <= 0) {
        Fluttertoast.showToast(
          msg: 'File must be greater than 0MB.',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Color(0xff2D2D2D),
          textColor: Colors.white,
          fontSize: 16.0,
        );
        return null;
      } else if (fileSize > 5 * 1024 * 1024) {
        // 5MB in bytes
        Fluttertoast.showToast(
          msg: 'File must be less than 5MB.',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Color(0xff2D2D2D),
          textColor: Colors.white,
          fontSize: 16.0,
        );
        return null;
      }

      return file;
    }

    return null;
  }

  File? selectedFile;

  Future<void> setUpdatedTimeInRTDB() async {
    try {
      final String sanitizedEmail = email.replaceAll('.', ',');

      final DatabaseReference resumeUpdatedRef =
          databaseRef.child('$sanitizedEmail/resumeUpdated');

      await resumeUpdatedRef.set(DateTime.now().toIso8601String());

      print('Resume updated time set successfully.');
    } catch (e) {
      print('Failed to update resume time: $e');
    }
  }

  Future<void> fetchAndFormatUpdatedTime() async {
    try {
      final String sanitizedEmail = email.replaceAll('.', ',');

      final DatabaseReference resumeUpdatedRef =
          databaseRef.child('$sanitizedEmail/resumeUpdated');

      final DataSnapshot snapshot = await resumeUpdatedRef.get();

      if (snapshot.exists) {
        String isoDateString = snapshot.value as String;
        DateTime dateTime = DateTime.parse(isoDateString);

        String formattedDate = DateFormat('dd-MM-yyyy').format(dateTime);
        setState(() {
          resumeUpdatedDate = formattedDate;
        });

        print('Formatted Date: $formattedDate');
      } else {
        print('No timestamp found in the database.');
      }
    } catch (e) {
      print('Error fetching or formatting timestamp: $e');
    }
  }

  String formatResumeDate(String? inputDate) {
    if (inputDate != null) {
      DateTime dateTime = DateTime.parse(inputDate);
      String formattedDate = DateFormat('dd-MM-yyyy').format(dateTime);

      return formattedDate;
    } else {
      return "Unknown date";
    }
  }

  Future<void> uploadPDF(File file) async {
  Dio dio = Dio();

  String url = 'https://mobileapidev.talentturbo.us/api/v1/resumeresource/uploadresume';

  FormData formData = FormData.fromMap({
    "id": retrievedUserData!.profileId.toString(),
    "file": await MultipartFile.fromFile(
      file.path,
      filename: file.path.split('/').last,
    ),
  });

  String token = retrievedUserData!.token;

  try {
    setState(() {
      isLoading = true;
    });

    Response response = await dio.post(
      url,
      data: formData,
      options: Options(
        headers: {
          'Authorization': token, // Ensure the token is correct
          'Content-Type': 'multipart/form-data',
        },
      ),
    );

    if (response.statusCode == 200 || response.statusCode == 202) {
      print('Upload success: ${response.statusCode}');
      setUpdatedTimeInRTDB();

      Fluttertoast.showToast(
        msg: 'Successfully uploaded',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Color(0xff2D2D2D),
        textColor: Colors.white,
        fontSize: 16.0,
      );

      fetchCandidateProfileData(retrievedUserData!.profileId, token);
    } else if (response.statusCode == 401) {
      // Handle Unauthorized (401)
      print("Error: Unauthorized (401). Please log in again.");

      Fluttertoast.showToast(
        msg: 'Session expired. Please log in again.',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );

      // Redirect to login screen
      Navigator.pushReplacementNamed(context, '/login'); // Adjust as needed
    } else {
      throw Exception("Unexpected status code: ${response.statusCode}");
    }
  } catch (e) {
    print('Upload failed: $e');

    Fluttertoast.showToast(
      msg: 'Upload failed: ${e.toString()}',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Color(0xff2D2D2D),
      textColor: Colors.white,
      fontSize: 16.0,
    );
  } finally {
    setState(() {
      isLoading = false;
    });
  }
}


  Future<void> pickAndUploadPDF() async {
    File? file = await pickPDF();
    if (file != null) {
      setState(() {
        selectedFile = file;
      });
      await uploadPDF(file);
    }
  }

  void showResumeDeleteConfirmationDialog(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          actionsPadding: EdgeInsets.fromLTRB(20, 0, 20, 20),
          contentPadding: EdgeInsets.fromLTRB(22, 15, 15, 22),
          title: Text(
            'Delete resume',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xff333333)),
          ),
          content: Text(
            'Are you sure you want to delete your resume?',
            style: TextStyle(
                height: 1.4,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xff333333)),
          ),
          actions: [
            InkWell(
              onTap: () {
                Navigator.pop(context);
              },
              child: Container(
                height: 40,
                width: 100,
                decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(width: 1, color: AppColors.primaryColor),
                    borderRadius: BorderRadius.circular(10)),
                child: Center(
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.primaryColor),
                  ),
                ),
              ),
            ),
            InkWell(
              onTap: () {
                Navigator.pop(context);
                deleteResume(id);
              },
              child: Container(
                height: 40,
                width: 100,
                decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(10)),
                child: Center(
                  child: Text(
                    'Delete',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            )
          ],
        );
      },
    );
  }

  void showDeleteConfirmationDialog(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          actionsPadding: EdgeInsets.fromLTRB(20, 0, 20, 20),
          contentPadding: EdgeInsets.fromLTRB(22, 15, 15, 22),
          title: Text(
            'Delete educational details',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xff333333)),
          ),
          content: Text(
            'Are you sure you want to delete your educational details?',
            style: TextStyle(
                height: 1.4,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xff333333)),
          ),
          actions: [
            InkWell(
              onTap: () {
                Navigator.pop(context);
              },
              child: Container(
                height: 40,
                width: 100,
                decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(width: 1, color: AppColors.primaryColor),
                    borderRadius: BorderRadius.circular(10)),
                child: Center(
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.primaryColor),
                  ),
                ),
              ),
            ),
            InkWell(
              onTap: () {
                Navigator.pop(context);
                deleteEducation(id);
              },
              child: Container(
                height: 40,
                width: 100,
                decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(10)),
                child: Center(
                  child: Text(
                    'Delete',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            )
          ],
        );
      },
    );
  }

  void showExperienceDeleteConfirmationDialog(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          actionsPadding: EdgeInsets.fromLTRB(20, 0, 20, 20),
          contentPadding: EdgeInsets.fromLTRB(22, 15, 15, 22),
          title: Text(
            'Delete employment details',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xff333333)),
          ),
          content: Text(
            'Are you sure you want to delete this employment detail?',
            style: TextStyle(
                height: 1.4,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xff333333)),
          ),
          actions: [
            InkWell(
              onTap: () {
                Navigator.pop(context);
              },
              child: Container(
                height: 40,
                width: 100,
                decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(width: 1, color: AppColors.primaryColor),
                    borderRadius: BorderRadius.circular(10)),
                child: Center(
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.primaryColor),
                  ),
                ),
              ),
            ),
            InkWell(
              onTap: () {
                Navigator.pop(context);
                deleteEmployment(id);
              },
              child: Container(
                height: 40,
                width: 100,
                decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(10)),
                child: Center(
                  child: Text(
                    'Delete',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            )
          ],
        );
      },
    );
  }

  Future<void> downloadAndShareCV(String fileUrl, String fileName) async {
    try {
      double downloadProgress = 0.0;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return ProgressDialog(progress: downloadProgress);
        },
      );

      // Download the file
      final tempDir = await getTemporaryDirectory();
      String filePath =
          '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_${fileName}';

      // Using Dio to download the file
      Dio dio = Dio();
      await dio.download(fileUrl, filePath,
          onReceiveProgress: (received, total) {
        if (total != -1) {
          downloadProgress = received / total;

          // Update the progress dialog
          Navigator.of(context).pop();
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return ProgressDialog(progress: downloadProgress);
            },
          );
        }
      });

      Navigator.of(context).pop();
      // Share the downloaded file
      await Share.shareXFiles([XFile(filePath)], text: 'Check out my CV');
    } catch (e) {
      print('Error downloading or sharing file: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffF7F7F7),
      body: RefreshIndicator(
        onRefresh: () async {
          await fetchCandidateProfileData(
              retrievedUserData!.profileId, retrievedUserData!.token, 0);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 40,
                )
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    PhysicalModel(
                      elevation: 0.5,
                      color: Color(0xffFCFCFC),
                      child: Column(
                        children: [
                          Container(
                            height: MediaQuery.of(context).size.height * 0.35,
                            child: Stack(
                              children: [
                                Container(
                                  width: double.infinity,
                                  height:
                                      MediaQuery.of(context).size.height * 0.2,
                                  decoration: BoxDecoration(
                                    color: Color(0xff001B3E),
                                    borderRadius: BorderRadius.only(
                                      bottomLeft: Radius.circular(10),
                                      bottomRight: Radius.circular(10),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 30,
                                  left: 10,
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          Icons.arrow_back_ios_new,
                                          color: Colors.white,
                                        ),
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                      ),
                                      InkWell(
                                        onTap: () {
                                          Navigator.pop(context);
                                        },
                                        child: Container(
                                          height: 40,
                                          alignment: Alignment.center,
                                          child: Text(
                                            'Back',
                                            style: TextStyle(
                                              fontFamily: 'Lato',
                                              fontSize: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  top:
                                      MediaQuery.of(context).size.height * 0.14,
                                  left:
                                      (MediaQuery.of(context).size.width / 2) -
                                          55,
                                  child: Container(
                                    width: MediaQuery.of(context).size.width *
                                        0.25,
                                    height: MediaQuery.of(context).size.width *
                                        0.25,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: Colors.white, width: 2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: InkWell(
                                      onTap: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  EditPhotoPage()),
                                        );
                                        fetchProfileFromPref();
                                      },
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(50),
                                        child: (candidateProfileModel != null &&
                                                candidateProfileModel!
                                                        .imagePath !=
                                                    null)
                                            ? Image.network(
                                                candidateProfileModel!
                                                    .imagePath!,
                                                fit: BoxFit.cover,
                                              )
                                            : Image.asset(
                                                'assets/images/profile.jfif',
                                                fit: BoxFit.cover,
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: (MediaQuery.of(context).size.width /
                                          2) +
                                      MediaQuery.of(context).size.width * 0.05,
                                  top:
                                      MediaQuery.of(context).size.height * 0.22,
                                  child: SvgPicture.asset(
                                    'assets/icon/DpEdit.svg',
                                    width: MediaQuery.of(context).size.width *
                                        0.08,
                                  ),
                                ),
                                Positioned(
                                  right:
                                      MediaQuery.of(context).size.width * 0.05,
                                  top:
                                      MediaQuery.of(context).size.height * 0.22,
                                  child: InkWell(
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                EditPersonalDetails()),
                                      );
                                      fetchProfileFromPref();
                                    },
                                    child: Row(
                                      children: [
                                        SvgPicture.asset(
                                          'assets/icon/edit.svg',
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.05,
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.05,
                                        ),
                                        SizedBox(width: 3),
                                        Text(
                                          'Edit',
                                          style: TextStyle(
                                            color: Color(0xff001B3E),
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top:
                                      MediaQuery.of(context).size.height * 0.26,
                                  left:
                                      MediaQuery.of(context).size.width * 0.03,
                                  right:
                                      MediaQuery.of(context).size.width * 0.03,
                                  child: Center(
                                    child: Column(
                                      children: [
                                        Text(
                                          '${candidateProfileModel!.candidateName}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xff333333),
                                            fontSize: 20,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 5),
                                        Text(
                                          '${candidateProfileModel!.position ?? 'Designation not updated'}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w400,
                                            color: Color(0xff545454),
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              ListTile(
                                dense: true,
                                leading: SvgPicture.asset(
                                  'assets/icon/location.svg',
                                  width:
                                      MediaQuery.of(context).size.width * 0.07,
                                  height:
                                      MediaQuery.of(context).size.width * 0.07,
                                ),
                                minLeadingWidth: 10,
                                title: Text(
                                  '${candidateProfileModel?.location ?? 'Location not updated'}',
                                  style: TextStyle(
                                    fontSize: 16, // Static font size
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xff333333),
                                  ),
                                ),
                              ),
                              ListTile(
                                dense: true,
                                leading: SvgPicture.asset(
                                  'assets/icon/newJob.svg',
                                  width:
                                      MediaQuery.of(context).size.width * 0.07,
                                  height:
                                      MediaQuery.of(context).size.width * 0.07,
                                ),
                                minLeadingWidth: 10,
                                title: Text(
                                  candidateProfileModel!.experience != null
                                      ? '${candidateProfileModel!.experience} Years'
                                      : 'Experience not updated',
                                  style: TextStyle(
                                    fontSize: 16, // Static font size
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xff333333),
                                  ),
                                ),
                              ),
                              ListTile(
                                dense: true,
                                leading: SvgPicture.asset(
                                  'assets/icon/phone.svg',
                                  width:
                                      MediaQuery.of(context).size.width * 0.07,
                                  height:
                                      MediaQuery.of(context).size.width * 0.07,
                                ),
                                minLeadingWidth: 10,
                                title: Text(
                                  '${candidateProfileModel!.mobile}',
                                  style: TextStyle(
                                    fontSize: 16, // Static font size
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xff333333),
                                  ),
                                ),
                              ),
                              ListTile(
                                dense: true,
                                leading: SvgPicture.asset(
                                  'assets/icon/mail.svg',
                                  width:
                                      MediaQuery.of(context).size.width * 0.07,
                                  height:
                                      MediaQuery.of(context).size.width * 0.07,
                                ),
                                minLeadingWidth: 10,
                                title: Text(
                                  '${candidateProfileModel!.email}',
                                  style: TextStyle(
                                    fontSize: 16, // Static font size
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xff333333),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.03),
                        ],
                      ),
                    ),
                    isLoading
                        ? Container(
                            width: MediaQuery.of(context).size.width,
                            child: Center(
                              child: Visibility(
                                visible: isLoading,
                                child: Column(
                                  children: [
                                    SizedBox(
                                      height: 30,
                                    ),
                                    LoadingAnimationWidget.fourRotatingDots(
                                      color: AppColors.primaryColor,
                                      size: 40,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : Container(),
                    SizedBox(
                      height: 15,
                    ),
                    Container(
                      width: 550,
                      decoration: BoxDecoration(
                          color: Color(0xffFCFCFC),
                          border:
                              Border.all(width: 0.3, color: Color(0xffD2D2D2))),
                      padding: EdgeInsets.fromLTRB(25, 15, 25, 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(0),
                            child: Text(
                              'Resume',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'Lato',
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xff333333)),
                            ),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          candidateProfileModel!.fileName == null
                              ? InkWell(
                                  onTap: () {
                                    pickAndUploadPDF();
                                  },
                                  child: Container(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Upload file',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xff004C99)),
                                            ),
                                            SizedBox(
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .height *
                                                  0.012, // Responsive height
                                            ),
                                            Text(
                                              'File types: pdf, .doc, .docx  Max file size: 5MB',
                                              style: TextStyle(
                                                  color: Color(0xff7D7C7C),
                                                  fontSize: 12),
                                            )
                                          ],
                                        ),
                                        SvgPicture.asset(
                                            'assets/images/mage_upload.svg',
                                            width: 30,
                                            height: 30)
                                      ],
                                    ),
                                  ),
                                )
                              : InkWell(
                                  onTap: () => {
                                    showMaterialModalBottomSheet(
                                      backgroundColor: Color(0x00000000),
                                      context: context,
                                      builder: (context) => Container(
                                        padding: EdgeInsets.symmetric(
                                            vertical: 30, horizontal: 10),
                                        decoration: BoxDecoration(
                                          color: Color(0xffFCFCFC),
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(25),
                                            topRight: Radius.circular(25),
                                          ),
                                        ),
                                        width:
                                            MediaQuery.of(context).size.width,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.25,
                                              height: 5,
                                              decoration: BoxDecoration(
                                                color: Colors.black,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                            ListTile(
                                              onTap: () {
                                                final String? filePath =
                                                    candidateProfileModel
                                                        ?.filePath;
                                                if (filePath != null) {
                                                  Navigator.pop(context);
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          DocViewerPage(
                                                              url: filePath),
                                                    ),
                                                  );
                                                }
                                              },
                                              //leading: Icon(Icons.visibility_outlined),
                                              leading: SvgPicture.asset(
                                                  'assets/images/ic_resume_view.svg'),
                                              title: Text('View Resume'),
                                            ),
                                            ListTile(
                                              onTap: () {
                                                Navigator.pop(context);
                                                pickAndUploadPDF();
                                              },
                                              //leading: Icon(Icons.refresh),
                                              leading: SvgPicture.asset(
                                                  'assets/images/ic_resume_change.svg'),
                                              title: Text('Change Resume'),
                                            ),
                                            ListTile(
                                              onTap: () {
                                                _launchURL();
                                              },
                                              //leading: Icon(Icons.download),
                                              leading: SvgPicture.asset(
                                                  'assets/images/ic_resume_download.svg'),
                                              title: Text('Download'),
                                            ),
                                            ListTile(
                                              onTap: () {
                                                final String? filePath =
                                                    candidateProfileModel
                                                        ?.filePath;
                                                final String? fileName =
                                                    candidateProfileModel!
                                                        .fileName;
                                                if (filePath != null &&
                                                    fileName != null) {
                                                  Navigator.pop(context);
                                                  downloadAndShareCV(
                                                      filePath, fileName);
                                                }
                                              },
                                              //leading: Icon(Icons.download),
                                              leading: SvgPicture.asset(
                                                  'assets/images/ic_share_resume.svg'),
                                              title: Text('Share'),
                                            ),
                                            ListTile(
                                              onTap: () {
                                                Navigator.pop(context);

                                                final int? resumeId =
                                                    candidateProfileModel
                                                        ?.resumeId;
                                                if (kDebugMode) {
                                                  print(resumeId);
                                                }

                                                if (resumeId != null) {
                                                  showResumeDeleteConfirmationDialog(
                                                      context, resumeId);
                                                }
                                              },
                                              //leading: Icon(Icons.download),
                                              leading: SvgPicture.asset(
                                                  'assets/images/ic_resume_delete.svg'),
                                              title: Text('Delete'),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  },
                                  child: Container(
                                    padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: Color(0xafFAFCFF)),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Image.asset(
                                                'assets/images/ic_curriculum.png',
                                                width: 55,
                                                height: 55),
                                            SizedBox(
                                              width: 10,
                                            ),
                                            Container(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width -
                                                  150,
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Flexible(
                                                      fit: FlexFit.loose,
                                                      child: Text(
                                                        softWrap: true,
                                                        '${candidateProfileModel!.fileName}',
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: TextStyle(
                                                            color: Color(
                                                                0xff004C99),
                                                            fontSize: 14,
                                                            fontFamily:
                                                                'NunitoSans',
                                                            fontWeight:
                                                                FontWeight
                                                                    .w600),
                                                      )),
                                                  //resumeUpdatedDate.isEmpty? SizedBox() : Text('Last updated ${resumeUpdatedDate}', style: TextStyle(color: Color(0xff004C99), fontFamily: 'NunitoSans', fontWeight: FontWeight.normal),),
                                                  Text(
                                                    'Last updated ${formatResumeDate(candidateProfileModel!.lastResumeUpdatedDate)}',
                                                    style: TextStyle(
                                                        color:
                                                            Color(0xff545454),
                                                        fontSize: 12,
                                                        fontFamily:
                                                            'NunitoSans',
                                                        fontWeight:
                                                            FontWeight.normal),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(
                                              height: 56,
                                              child: Align(
                                                alignment: Alignment.center,
                                                child: SvgPicture.asset(
                                                    'assets/icon/moreDot.svg'),
                                              ),
                                            )
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 15,
                    ),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          border:
                              Border.all(width: 0.3, color: Color(0xffD2D2D2)),
                          color: Color(0xffFCFCFC)),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 20,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Work Experience',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xff333333),
                                ),
                              ),
                              InkWell(
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (BuildContext context) =>
                                          Addemployment(
                                        emplomentData: null,
                                      ),
                                    ),
                                  );
                                  fetchProfileFromPref();
                                },
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    right: MediaQuery.of(context).size.width *
                                        0.02,
                                  ),
                                  child: SvgPicture.asset(
                                    'assets/icon/add.svg',
                                    width: 30,
                                    height: 30,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          workList.length == 0
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      height: 10,
                                    ),
                                    Text(
                                      'Include your work experience to help recruiters match your profile with suitable job openings.',
                                      textAlign: TextAlign.start,
                                      style: TextStyle(
                                          fontWeight: FontWeight.w400,
                                          height: 1.5,
                                          color: Color(0xff7D7C7C),
                                          fontSize: 14),
                                    )
                                  ],
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemCount: workList.length,
                                  itemBuilder: (context, index) {
                                    return Column(
                                      children: [
                                        InkWell(
                                          onTap: () {
                                            showMaterialModalBottomSheet(
                                              isDismissible: true,
                                              context: context,
                                              backgroundColor:
                                                  Color(0x00000000),
                                              builder: (context) => Container(
                                                padding: EdgeInsets.symmetric(
                                                    vertical: 30,
                                                    horizontal: 10),
                                                decoration: BoxDecoration(
                                                  color: Color(0xffFCFCFC),
                                                  borderRadius:
                                                      BorderRadius.only(
                                                    topLeft:
                                                        Radius.circular(25),
                                                    topRight:
                                                        Radius.circular(25),
                                                  ),
                                                ),
                                                width: MediaQuery.of(context)
                                                    .size
                                                    .width,
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Container(
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              0.25,
                                                      height: 5,
                                                      decoration: BoxDecoration(
                                                        color: Colors.black,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                      ),
                                                    ),
                                                    ListTile(
                                                      leading: SvgPicture.asset(
                                                          'assets/images/tabler_edit.svg'),
                                                      title: Text('Edit'),
                                                      onTap: () async {
                                                        Navigator.pop(context);
                                                        await Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (BuildContext
                                                                    context) =>
                                                                Addemployment(
                                                              emplomentData:
                                                                  workList[
                                                                      index],
                                                            ),
                                                          ),
                                                        );
                                                        fetchProfileFromPref();
                                                      },
                                                    ),
                                                    ListTile(
                                                      leading: Icon(
                                                          Icons.delete,
                                                          color: Colors.black),
                                                      title: Text('Delete'),
                                                      onTap: () {
                                                        Navigator.pop(context);
                                                        setState(() {
                                                          showExperienceDeleteConfirmationDialog(
                                                            context,
                                                            workList[index]
                                                                    ['id']
                                                                .toString(),
                                                          );
                                                        });
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Column(
                                                    children: [
                                                      SizedBox(
                                                        height: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .height *
                                                            0.01, // 1% of screen height
                                                      ),
                                                      Column(
                                                        children: [
                                                          Container(
                                                            width: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width *
                                                                0.03, // Responsive dot size
                                                            height: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width *
                                                                0.03,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Colors
                                                                  .transparent, // Transparent inside
                                                              shape: BoxShape
                                                                  .circle,
                                                              border:
                                                                  Border.all(
                                                                color: Color(
                                                                    0xff004C99), // Border color
                                                                width: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width *
                                                                    0.006, // Responsive border thickness
                                                              ),
                                                            ),
                                                          ),

                                                          SizedBox(
                                                              height: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .height *
                                                                  0.005), // Responsive spacing

                                                          if (index !=
                                                              workList.length -
                                                                  1) // Only add line if not last item
                                                            Container(
                                                              width: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width *
                                                                  0.007, // Responsive line thickness
                                                              height: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .height *
                                                                  0.1, // Adjust based on screen
                                                              color: Color(
                                                                  0xff004C99),
                                                            ),
                                                        ],
                                                      )
                                                    ],
                                                  ),
                                                  SizedBox(width: 17),
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        workList[index]
                                                            ['jobTitle'],
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: 16,
                                                          color:
                                                              Color(0xff333333),
                                                        ),
                                                      ),
                                                      SizedBox(height: 10),
                                                      Text(
                                                        workList[index]
                                                            ['companyName'],
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        maxLines: 1,
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w400,
                                                          fontSize: 14,
                                                          color:
                                                              Color(0xff333333),
                                                        ),
                                                      ),
                                                      SizedBox(height: 10),
                                                      Text(
                                                        '${formatDate(workList[index]['employedFrom'])} - ${formatDate(workList[index]['employedTo'])}',
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w400,
                                                          fontSize: 14,
                                                          color:
                                                              Color(0xff7D7C7C),
                                                        ),
                                                      ),
                                                      SizedBox(height: 10),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              Padding(
                                                padding: EdgeInsets.only(
                                                  right: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.02,
                                                ),
                                                child: SvgPicture.asset(
                                                    'assets/icon/moreDot.svg'),
                                              )
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 15,
                    ),
                    Container(
                      padding: EdgeInsets.all(
                          MediaQuery.of(context).size.width *
                              0.03), // Responsive padding
                      decoration: BoxDecoration(
                        border:
                            Border.all(width: 0.3, color: Color(0xffD2D2D2)),
                        color: Color(0xffFCFCFC),
                      ),
                      child: Column(
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height *
                                0.02, // 2% of screen height
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Educational Details',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xff333333),
                                ),
                              ),
                              InkWell(
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (BuildContext context) =>
                                          Addeducation(
                                        educationDetail: null,
                                      ),
                                    ),
                                  );
                                  fetchProfileFromPref();
                                },
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    right: MediaQuery.of(context).size.width *
                                        0.02,
                                  ),
                                  child: SvgPicture.asset(
                                    'assets/icon/add.svg',
                                    width: 30,
                                    height: 30,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          educationList.isEmpty
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.015,
                                    ),
                                    Text(
                                      'Update your education details to boost your chances of securing a job more quickly.',
                                      textAlign: TextAlign.start,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w400,
                                        height: 1.5,
                                        color: Color(0xff7D7C7C),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemCount: educationList.length,
                                  itemBuilder: (context, index) {
                                    return Column(
                                      children: [
                                        InkWell(
                                          onTap: () {
                                            showMaterialModalBottomSheet(
                                              backgroundColor:
                                                  Color(0x00000000),
                                              isDismissible: true,
                                              context: context,
                                              builder: (context) => Container(
                                                padding: EdgeInsets.symmetric(
                                                  vertical:
                                                      MediaQuery.of(context)
                                                              .size
                                                              .height *
                                                          0.03,
                                                  horizontal:
                                                      MediaQuery.of(context)
                                                              .size
                                                              .width *
                                                          0.03,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Color(0xffFCFCFC),
                                                  borderRadius:
                                                      BorderRadius.only(
                                                    topLeft:
                                                        Radius.circular(25),
                                                    topRight:
                                                        Radius.circular(25),
                                                  ),
                                                ),
                                                width: MediaQuery.of(context)
                                                    .size
                                                    .width,
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Container(
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              0.25,
                                                      height: 5,
                                                      decoration: BoxDecoration(
                                                        color: Colors.black,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                      ),
                                                    ),
                                                    ListTile(
                                                      leading: SvgPicture.asset(
                                                          'assets/images/tabler_edit.svg'),
                                                      title: Text('Edit'),
                                                      onTap: () async {
                                                        Navigator.pop(context);
                                                        await Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (BuildContext
                                                                    context) =>
                                                                Addeducation(
                                                              educationDetail:
                                                                  educationList[
                                                                      index],
                                                            ),
                                                          ),
                                                        );
                                                        fetchProfileFromPref();
                                                      },
                                                    ),
                                                    ListTile(
                                                      leading: Icon(
                                                        Icons.delete,
                                                        color: Colors.black,
                                                      ),
                                                      title: Text('Delete'),
                                                      onTap: () {
                                                        Navigator.pop(context);
                                                        setState(() {
                                                          showDeleteConfirmationDialog(
                                                              context,
                                                              educationList[
                                                                          index]
                                                                      ['id']
                                                                  .toString());
                                                        });
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  // Responsive Dot
                                                  Column(
                                                    children: [
                                                      SizedBox(
                                                          height: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .height *
                                                              0.008),
                                                      Container(
                                                        width: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width *
                                                            0.03, // Responsive dot size
                                                        height: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width *
                                                            0.03,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors
                                                              .transparent, // Transparent inside
                                                          shape:
                                                              BoxShape.circle,
                                                          border: Border.all(
                                                            color: Color(
                                                                0xff004C99), // Border color
                                                            width: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width *
                                                                0.006, // Responsive border thickness
                                                          ),
                                                        ),
                                                      ),

                                                      SizedBox(
                                                          height: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .height *
                                                              0.005), // Responsive spacing

                                                      if (index !=
                                                          workList.length -
                                                              1) // Only add line if not last item
                                                        Container(
                                                          width: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width *
                                                              0.007, // Responsive line thickness
                                                          height: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .height *
                                                              0.1, // Adjust based on screen
                                                          color:
                                                              Color(0xff004C99),
                                                        ),
                                                    ],
                                                  ),
                                                  SizedBox(
                                                      width: MediaQuery.of(
                                                                  context)
                                                              .size
                                                              .width *
                                                          0.04), // Spacing before text

                                                  // Education Details Column
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        educationList[index][
                                                                'specialization'] ??
                                                            'Unknown',
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width *
                                                              0.04,
                                                          color:
                                                              Color(0xff333333),
                                                        ),
                                                      ),
                                                      SizedBox(
                                                          height: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .height *
                                                              0.01),
                                                      Text(
                                                        educationList[index][
                                                                'schoolName'] ??
                                                            'Unknown',
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        maxLines: 1,
                                                        softWrap: true,
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w400,
                                                          fontSize: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width *
                                                              0.035,
                                                          color:
                                                              Color(0xff333333),
                                                        ),
                                                      ),
                                                      SizedBox(
                                                          height: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .height *
                                                              0.01),
                                                      Text(
                                                        '${formatDate(educationList[index]['graduatedFrom'])} - ${educationList[index]['graduatedTo'] == '1970-01-01' ? 'Present' : formatDate(educationList[index]['graduatedTo'])}',
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w400,
                                                          fontSize: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width *
                                                              0.035,
                                                          color:
                                                              Color(0xff7D7C7C),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),

                                              // More Options Icon
                                              Padding(
                                                padding: EdgeInsets.only(
                                                  right: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.02,
                                                ),
                                                child: SvgPicture.asset(
                                                    'assets/icon/moreDot.svg'),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.02,
                    ),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          border:
                              Border.all(width: 0.3, color: Color(0xffD2D2D2)),
                          color: Color(0xffFCFCFC)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 20,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Skills',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xff333333),
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (BuildContext context) =>
                                            Adddeleteskills()),
                                  );
                                },
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    right: MediaQuery.of(context).size.width *
                                        0.02,
                                  ),
                                  child: SvgPicture.asset(
                                    'assets/icon/add.svg',
                                    width: 30,
                                    height: 30,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          userSkills.length == 0
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      height: 10,
                                    ),
                                    Text(
                                      'List your skills on your profile. This will help recruiters find you more easily.',
                                      textAlign: TextAlign.start,
                                      style: TextStyle(
                                          fontWeight: FontWeight.w400,
                                          height: 1.5,
                                          color: Color(0xff7D7C7C),
                                          fontSize: 14),
                                    )
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      height: 30,
                                    ),
                                    Wrap(
                                      alignment: WrapAlignment.start,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.start,
                                      spacing:
                                          12.0, // Horizontal space between boxes
                                      runSpacing: 12.0,
                                      children:
                                          List.generate(userSkills.length, (i) {
                                        return Container(
                                          padding: EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                              color: AppColors.primaryColor),
                                          child: Text(
                                            userSkills[i],
                                            style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.white),
                                          ),
                                        );
                                      }),
                                    ),
                                  ],
                                ),
                          SizedBox(
                            height: 30,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchProfileFromPref();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    //super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // This is similar to onResume in Android
      print("App has resumed");
      // Add your onResume logic here
    }
    if (state == AppLifecycleState.paused) {
      print("App is in the background (paused)");
    }
    // You can also handle other states like AppLifecycleState.inactive, AppLifecycleState.detached
  }

  Future<void> fetchProfileFromPref() async {
    //ReferralData? _referralData = await getReferralProfileData();
    CandidateProfileModel? _candidateProfileModel =
        await getCandidateProfileData();
    UserData? _retrievedUserData = await getUserData();

    print('Resume : ${_candidateProfileModel!.fileName}');
    UserCredentials? loadedCredentials =
        await UserCredentials.loadCredentials();

    setState(() {
      //referralData = _referralData;
      candidateProfileModel = _candidateProfileModel;
      retrievedUserData = _retrievedUserData;

      educationList = _candidateProfileModel!.candidateEducation;
      workList = _candidateProfileModel!.candidateEmployment;

      if (loadedCredentials != null) {
        email = loadedCredentials.username;
        fetchAndFormatUpdatedTime();
        fetchSkills();
      } else if (retrievedUserData != null) {
        email = retrievedUserData!.email;
        fetchAndFormatUpdatedTime();
        fetchSkills();
      }
    });
  }
}
