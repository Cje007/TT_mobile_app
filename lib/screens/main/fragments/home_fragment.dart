import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_icon_snackbar/flutter_icon_snackbar.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:intl/intl.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:talent_turbo_new/AppColors.dart';
import 'package:talent_turbo_new/AppConstants.dart';
import 'package:talent_turbo_new/Utils.dart';
import 'package:talent_turbo_new/models/candidate_profile_model.dart';
import 'package:talent_turbo_new/models/job_list_model.dart';

import 'package:talent_turbo_new/screens/jobDetails/JobDetails.dart';
import 'package:talent_turbo_new/screens/main/SearchAndFilter.dart';
import 'package:talent_turbo_new/screens/main/job_search_filter.dart';
import 'package:talent_turbo_new/screens/main/notifications.dart';

import '../../../models/user_data_model.dart';
import 'package:http/http.dart' as http;

class HomeFragment extends StatefulWidget {
  const HomeFragment({super.key});

  @override
  State<HomeFragment> createState() => _HomeFragmentState();
}

class _HomeFragmentState extends State<HomeFragment>
    with SingleTickerProviderStateMixin {
  //UserData? retrievedUserData = await getUserData();
  UserData? retrievedUserData;
  //ReferralData? referralData;
  CandidateProfileModel? candidateProfileModel;

  String jobSearchTerm = '';
  String exp_search = '0';
  String emp_search = '';

  bool isLoading = true;
  bool isConnectionAvailable = true;

  List<dynamic> jobList = [];

  bool hasFilters = false;

  List<Job> parseJobs(List<dynamic> jsonList) {
    return jsonList.map((json) => Job.fromJson(json)).toList();
  }

  Future<void> loadCachedJobs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? jobListString = prefs.getString('jobList');

    if (jobListString != null) {
      List<dynamic> cachedJobs = jsonDecode(jobListString);
      setState(() {
        jobList = cachedJobs;
        isLoading = false;
      });
    }
  }

// 🔹 Helper function for showing snack bars
  void _showSnackBar(BuildContext context, String message, Color color) {
    IconSnackBar.show(
      context,
      label: message,
      snackBarType:
          color == Colors.green ? SnackBarType.success : SnackBarType.fail,
      backgroundColor: color,
      iconColor: Colors.white,
    );
  }

  Future<bool> saveJob(int jobId, int status) async {
    final url =
        Uri.parse(AppConstants.BASE_URL + AppConstants.SAVE_JOB_TO_FAV_NEW);
    final bodyParams = {"jobId": jobId, "isFavorite": status};

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': retrievedUserData?.token ?? '',
        },
        body: jsonEncode(bodyParams),
      );

      if (kDebugMode) {
        print(
            'Response code: ${response.statusCode} :: Response => ${response.body}');
      }

      if (response.statusCode == 200 || response.statusCode == 202) {
        if (mounted) {
          _showSnackBar(
            context,
            status == 1 ? 'Saved successfully' : 'Removed successfully',
            Colors.green,
          );
        }
        return true; // ✅ Return success
      } else {
        if (mounted) {
          _showSnackBar(context, 'Something went wrong. Please try again.',
              Color(0xffBA1A1A));
        }
        return false; // ❌ Return failure
      }
    } catch (e) {
      if (kDebugMode) print("Error: $e");

      if (mounted) {
        _showSnackBar(context, 'Network error. Please check your connection.',
            Color(0xffBA1A1A));
      }
      return false; // ❌ Return failure
    }
  }

  Future<void> fetchAllJobs() async {
    final url = Uri.parse(AppConstants.BASE_URL + AppConstants.ALL_JOBS_LIST);

    final bodyParams = {
      "jobTitle": jobSearchTerm,
      "jobCode": "",
      "companyName": "",
      "experience": exp_search,
      "workType": emp_search,
      "skillSet": ""
    };

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
        body: jsonEncode(bodyParams),
      );

      if (kDebugMode) {
        print(
            'Response code ${response.statusCode} :: Response => ${response.body}');
      }

      if (response.statusCode == 200) {
        var resOBJ = jsonDecode(response.body);
        bool status = resOBJ['status'];
        String statusMessage = resOBJ['message'];

        if (statusMessage.toLowerCase().contains('success') && status == true) {
          final List<dynamic> jsonResponse = (resOBJ['jobList']);
          setState(() {
            jobList = jsonResponse;
          });
        }

        if (kDebugMode) {
          print(jobList.length);
        }
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
    } finally {
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        // Fluttertoast.showToast(
        //   msg: "No internet connection",
        //   toastLength: Toast.LENGTH_SHORT,
        //   gravity: ToastGravity.BOTTOM,
        //   timeInSecForIosWeb: 1,
        //   backgroundColor: Color(0xff2D2D2D),
        //   textColor: Colors.white,
        //   fontSize: 16.0,
        // );
        IconSnackBar.show(
          context,
          label: 'No internet connection',
          snackBarType: SnackBarType.alert,
          backgroundColor: Color(0xff2D2D2D),
          iconColor: Colors.white,
        );

        setState(() {
          isConnectionAvailable = false;
        });
      } else {
        setState(() {
          isConnectionAvailable = true;
        });
      }
      setState(() {
        isLoading = false;
      });
    }
  }

  bool checkExpiry(String dateString) {
    // Parse the date string
    DateTime providedDate = DateFormat("yyyy-MM-dd").parse(dateString);

    // Get the current date
    DateTime currentDate = DateTime.now();

    // Compare the dates
    return (providedDate.isBefore(currentDate));
  }

  @override
  Widget build(BuildContext context) {
    // Change the status bar color
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Color(0xff001B3E),
      statusBarIconBrightness: Brightness.light,
    ));
    return Stack(
      children: [
        Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Color(0xff001B3E),
              child: Column(
                children: [
                  SizedBox(
                    height: 60,
                  ),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 25),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width * 0.77,
                          height: 40,
                          padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50),
                              color: Colors.white),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (BuildContext context) =>
                                                  Searchandfilter()));
                                      String? pref_value =
                                          await getStringFromPreferences(
                                              "search");
                                      setState(() {
                                        jobSearchTerm = pref_value!;
                                        fetchAllJobs();
                                      });
                                      //await saveStringToPreferences("search", "");
                                    },
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SvgPicture.asset(
                                          'assets/icon/Search.svg',
                                          width: 26,
                                          height: 26,
                                        ),
                                        SizedBox(
                                          width: 10,
                                        ),
                                        Flexible(
                                          child: Text(
                                            jobSearchTerm.isEmpty
                                                ? 'Search for jobs or skills'
                                                : jobSearchTerm,
                                            style: TextStyle(
                                                color: Color(0xff7D7C7C)),
                                            overflow: TextOverflow
                                                .ellipsis, // Add this line to handle overflow
                                            maxLines:
                                                1, // Optional: Limits text to a single line
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                                jobSearchTerm.isEmpty
                                    ? Container()
                                    : InkWell(
                                        onTap: () {
                                          setState(() {
                                            jobSearchTerm = '';
                                            fetchAllJobs();
                                          });
                                        },
                                        child: Icon(
                                          Icons.cancel,
                                          color: Color(0xff818385),
                                        )),
                              ],
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
                                        NotificationScreen(),
                                transitionDuration: Duration.zero,
                                reverseTransitionDuration: Duration.zero,
                              ),
                            );
                          },
                          child: Stack(
                            children: [
                              jobSearchTerm.isEmpty
                                  ? SvgPicture.asset(
                                      'assets/icon/Notifi.svg',
                                      width: 28,
                                      height: 28,
                                    )
                                  : SizedBox(
                                      width: 26,
                                      height: 26,
                                      child: InkWell(
                                        onTap: () async {
                                          await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder:
                                                      (BuildContext context) =>
                                                          JobSearchFilter()));

                                          String? pref_filt =
                                              await getStringFromPreferences(
                                                  "searchExp");
                                          exp_search = pref_filt ?? '';

                                          String? pref_emp_filt =
                                              await getStringFromPreferences(
                                                  "searchEmpType");
                                          emp_search = pref_emp_filt ?? '';

                                          if (emp_search == 'Full time') {
                                            setState(() {
                                              emp_search = 'Fulltime';
                                            });
                                          }

                                          setState(() {
                                            if ((emp_search != null &&
                                                    emp_search != "") ||
                                                (exp_search != null &&
                                                    exp_search != "0")) {
                                              hasFilters = true;
                                            } else {
                                              hasFilters = false;
                                            }
                                          });

                                          fetchAllJobs();
                                        },
                                        child: Stack(
                                          children: [
                                            SvgPicture.asset(
                                                'assets/images/ic_filter.svg'),
                                            hasFilters
                                                ? Positioned(
                                                    left: 3,
                                                    top: 1,
                                                    child: SvgPicture.asset(
                                                        'assets/images/ic_filter_on.svg'))
                                                : Container(),
                                          ],
                                        ),
                                      ),
                                    )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                ],
              ),
            )),
        Positioned(
            top: 120,
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).size.height * 0.07,
            child: Container(
              width: MediaQuery.of(context).size.width,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Container(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          //Text('Hi, ${referralData?.name}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xff333333)),),
                          Text(
                            'Hi, ${candidateProfileModel?.candidateName}',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xff333333)),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              /* Container(
                                  width: 200,
                                  child: Flexible(fit: FlexFit.loose ,child: Text(maxLines: 1, overflow: TextOverflow.ellipsis, jobSearchTerm.isEmpty?'Recent job list' : 'Search results for ${jobSearchTerm}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Color(0xff333333)),))
                              ),*/

                              Flexible(
                                  fit: FlexFit.loose,
                                  child: Text(
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    jobSearchTerm.isEmpty
                                        ? 'Recent job list'
                                        : 'Search results for ${jobSearchTerm}',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400,
                                        color: Color(0xff333333)),
                                  ))
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  isLoading
                      ? Expanded(
                          child: Shimmer.fromColors(
                            baseColor: Color(0xffE6E6E6),
                            highlightColor: Color(0xffF2F2F2),
                            child: ListView.builder(
                              itemCount: 5,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 8, horizontal: 15),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Container(
                                              height: 1,
                                              color: Color(0xffE6E6E6),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 10),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.11,
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.11,
                                            decoration: BoxDecoration(
                                              color: Color(0xffE6E6E6),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.62,
                                                height: 20,
                                                decoration: BoxDecoration(
                                                  color: Color(0xffE6E6E6),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                              ),
                                              SizedBox(height: 10),
                                              Container(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.45,
                                                height: 15,
                                                decoration: BoxDecoration(
                                                  color: Color(0xffE6E6E6),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                              ),
                                              SizedBox(height: 10),
                                              Container(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.70,
                                                height: 15,
                                                decoration: BoxDecoration(
                                                  color: Color(0xffE6E6E6),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                              ),
                                              SizedBox(height: 10),
                                              Row(
                                                children: [
                                                  Container(
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.33,
                                                    height: 15,
                                                    decoration: BoxDecoration(
                                                      color: Color(0xffE6E6E6),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                    ),
                                                  ),
                                                  SizedBox(width: 10),
                                                  Container(
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.33,
                                                    height: 15,
                                                    decoration: BoxDecoration(
                                                      color: Color(0xffE6E6E6),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 10),
                                              Container(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.27,
                                                height: 15,
                                                decoration: BoxDecoration(
                                                  color: Color(0xffE6E6E6),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Spacer(),
                                          Container(
                                            width: 30,
                                            height: 30,
                                            decoration: BoxDecoration(
                                              color: Color(0xffE6E6E6),
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        )
                      : jobList.length > 0
                          ? Expanded(
                              child: RefreshIndicator(
                              onRefresh: fetchAllJobs,
                              child: ListView.builder(
                                itemCount: jobList.length,
                                itemBuilder: (context, index) {
                                  return Container(
                                    margin: EdgeInsets.symmetric(vertical: 5),
                                    padding: EdgeInsets.all(15),
                                    decoration: BoxDecoration(
                                        border: Border.all(
                                            width: 0.2,
                                            color: Color(0xffE6E6E6)),
                                        color: Color(0xffFCFCFC)),
                                    width: MediaQuery.of(context).size.width,
                                    height: 160,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        InkWell(
                                          onTap: () async {
                                            //Navigator.push(context, MaterialPageRoute(builder: (BuildContext context)=>Jobdetails(jobData: jobList[index])));

                                            await Navigator.pushAndRemoveUntil(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      Jobdetails(
                                                        jobData: jobList[index],
                                                        isFromSaved: false,
                                                      )),
                                              (Route<dynamic> route) => route
                                                  .isFirst, // This will keep Screen 1
                                            );

                                            // fetchAllJobs();
                                            loadCachedJobs();
                                          },
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              //Image.asset('assets/images/bmw_logo.png', height: 32, width: 32, ),
                                              //jobList[index]['logo'] ? Image.network(jobList[index]['logo'], height: 32, width: 32, ) : Image.asset('assets/images/tt_logo_resized.png', height: 32, width: 32, ),
                                              Image(
                                                image: jobList[index]['logo'] !=
                                                            null &&
                                                        jobList[index]['logo']
                                                            .isNotEmpty
                                                    ? NetworkImage(
                                                        jobList[index]['logo'],
                                                      ) as ImageProvider<Object>
                                                    : const AssetImage(
                                                        'assets/images/tt_logo_resized.png'),
                                                height: 40,
                                                width: 40,
                                                fit: BoxFit.contain,
                                                errorBuilder: (context, error,
                                                    stackTrace) {
                                                  // Fallback to asset if network image fails
                                                  return Image.asset(
                                                    'assets/images/tt_logo_resized.png',
                                                    height: 37,
                                                    width: 37,
                                                    fit: BoxFit.contain,
                                                  );
                                                },
                                              ),

                                              SizedBox(
                                                width: 15,
                                              ),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Flexible(
                                                      fit: FlexFit.loose,
                                                      child: Container(
                                                          width: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width -
                                                              180,
                                                          child: Text(
                                                            jobList[index]
                                                                ['jobTitle'],
                                                            //"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddjobList[index]['jobTitle']",
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                fontFamily:
                                                                    'Lato',
                                                                fontSize: 16,
                                                                color: Color(
                                                                    0xff333333)),
                                                          ))),
                                                  Flexible(
                                                    fit: FlexFit.loose,
                                                    child: Container(
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width -
                                                              155,
                                                      child: Text(
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        jobList[index]
                                                                ['companyName']
                                                            .toString()
                                                            .trim(),
                                                        //"jobList[index]['companyName'].toString().trim()jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj" ,
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.w400,
                                                            fontFamily: 'Lato',
                                                            fontSize: 13,
                                                            color: Color(
                                                                0xff545454)),
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width -
                                                            155,
                                                    child: Row(
                                                      children: [
                                                        SvgPicture.asset(
                                                          'assets/images/ic_idea.svg',
                                                          height: 14,
                                                          width: 14,
                                                          color: Colors.black,
                                                        ),
                                                        SizedBox(
                                                          width: 5,
                                                        ),
                                                        //Text('Skills : Interaction Design · User Research +5', style: TextStyle(fontWeight: FontWeight.w400, fontSize: 14, color: Color(0xff545454)),),
                                                        Flexible(
                                                            fit: FlexFit.loose,
                                                            child: Text(
                                                              'Skills : ${jobList[index]['skillSet']}',
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              maxLines: 1,
                                                              style: TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w400,
                                                                  fontSize: 14,
                                                                  color: Color(
                                                                      0xff545454)),
                                                            )),
                                                      ],
                                                    ),
                                                  ),
                                                  Row(
                                                    children: [
                                                      Row(
                                                        children: [
                                                          SvgPicture.asset(
                                                            'assets/images/ic_suitcase.svg',
                                                            height: 14,
                                                            width: 14,
                                                            color: Colors.black,
                                                          ),
                                                          SizedBox(
                                                            width: 5,
                                                          ),
                                                          Text(
                                                            jobList[index]
                                                                ['workType'],
                                                            style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w400,
                                                                fontSize: 14,
                                                                color: Color(
                                                                    0xff545454)),
                                                          ),
                                                        ],
                                                      ),
                                                      SizedBox(
                                                        width: 20,
                                                      ),
                                                      Container(
                                                        width: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width -
                                                            255,
                                                        child: Row(
                                                          children: [
                                                            SvgPicture.asset(
                                                              'assets/images/ic_location.svg',
                                                              height: 14,
                                                              width: 14,
                                                              color:
                                                                  Colors.black,
                                                            ),
                                                            SizedBox(
                                                              width: 5,
                                                            ),
                                                            //Text(jobList[index]['location'], overflow: TextOverflow.ellipsis, maxLines: 1, softWrap: false, style: TextStyle(fontWeight: FontWeight.w400, fontSize: 14, color: Color(0xff545454)),),
                                                            Flexible(
                                                              fit:
                                                                  FlexFit.loose,
                                                              child: Text(
                                                                jobList[index][
                                                                        'location'] ??
                                                                    'N/A',
                                                                //"kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk",
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                maxLines: 1,
                                                                softWrap: false,
                                                                style:
                                                                    TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w400,
                                                                  fontSize: 14,
                                                                  color: Color(
                                                                      0xff545454),
                                                                ),
                                                              ),
                                                            )
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  Text(
                                                    checkExpiry(jobList[index]
                                                                ['dueDate'] ??
                                                            '1990-01-01')
                                                        ? 'Job Expired'
                                                        : processDate(jobList[
                                                                    index][
                                                                'createdDate'] ??
                                                            '2024-10-27'),
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w400,
                                                        fontSize: 14,
                                                        color: checkExpiry(jobList[
                                                                        index][
                                                                    'dueDate'] ??
                                                                '1990-01-01')
                                                            ? const Color(
                                                                0xffBA1A1A)
                                                            : Color(
                                                                0xff545454)),
                                                  )
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () async {
                                            bool isSaved = (jobList[index]
                                                    ['isFavorite'] ==
                                                "1"); // Convert to boolean
                                            int? jobId = jobList[index]
                                                    ['jobId'] ??
                                                jobList[index]
                                                    ['id']; // Get job ID

                                            if (kDebugMode) {
                                              print(
                                                  'Status before tap: $isSaved');
                                            }

                                            if (jobId != null) {
                                              setState(() {
                                                jobList[index]['isFavorite'] =
                                                    isSaved
                                                        ? "0"
                                                        : "1"; // Optimistic UI update
                                              });

                                              bool success = await saveJob(
                                                  jobId,
                                                  isSaved ? 0 : 1); // API call

                                              if (!success) {
                                                // Revert UI if API call fails
                                                setState(() {
                                                  jobList[index]['isFavorite'] =
                                                      isSaved ? "1" : "0";
                                                });
                                              }
                                            } else {
                                              if (kDebugMode) {
                                                print("Error: Job ID is null");
                                              }
                                            }
                                          },
                                          child: Icon(
                                            (jobList[index]['isFavorite'] ==
                                                    "1")
                                                ? Icons.bookmark
                                                : Icons.bookmark_border_rounded,
                                            color: jobList[index]
                                                        ['isFavorite'] ==
                                                    "1"
                                                ? Color(0xff004C99)
                                                : null,
                                            size: 25,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ))
                          : isConnectionAvailable
                              ? SizedBox(
                                  height: 500,
                                  child: Padding(
                                    padding: const EdgeInsets.all(15.0),
                                    child: Center(
                                      child: Text(
                                        'No Jobs Here ${jobSearchTerm}',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w400),
                                      ),
                                    ),
                                  ),
                                )
                              : Expanded(
                                  child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SvgPicture.asset(
                                          'assets/icon/noInternet.svg'),
                                      Text(
                                        'No Internet connection',
                                        style: TextStyle(
                                            fontFamily: 'Lato',
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: Color(0xff333333)),
                                      ),
                                      SizedBox(
                                        height: 15,
                                      ),
                                      Text(
                                        'Connect to Wi-Fi or cellular data and try again.',
                                        style: TextStyle(
                                            fontFamily: 'Lato',
                                            fontWeight: FontWeight.w400,
                                            fontSize: 14,
                                            color: Color(0xff545454)),
                                      ),
                                      SizedBox(height: 30),
                                      InkWell(
                                        onTap: () {
                                          fetchAllJobs();
                                        },
                                        child: Container(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width -
                                              50,
                                          height: 44,
                                          margin: EdgeInsets.symmetric(
                                              horizontal: 0),
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 10),
                                          decoration: BoxDecoration(
                                              color: AppColors.primaryColor,
                                              borderRadius:
                                                  BorderRadius.circular(8)),
                                          child: Center(
                                            child: Text(
                                              'Try Again',
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ))
                ],
              ),
            ))
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    fetchUserDataFromPref();
  }

  Future<void> fetchUserDataFromPref() async {
    UserData? _retrievedUserData = await getUserData();
    CandidateProfileModel? _candidateProfileModel =
        await getCandidateProfileData();

    setState(() {
      retrievedUserData = _retrievedUserData;
      candidateProfileModel = _candidateProfileModel;

      if (kDebugMode) {
        print("User Email: ${retrievedUserData?.email}");
      }

      fetchAllJobs(); // Fetch jobs after retrieving user data
    });
  }
}
