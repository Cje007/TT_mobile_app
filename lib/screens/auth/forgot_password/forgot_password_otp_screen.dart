import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icon_snackbar/flutter_icon_snackbar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:otp_pin_field/otp_pin_field.dart';
import 'package:talent_turbo_new/AppColors.dart';
import 'package:talent_turbo_new/AppConstants.dart';
import 'package:talent_turbo_new/screens/auth/forgot_password/reset_new_password.dart';
import 'package:talent_turbo_new/screens/auth/login/login_screen.dart';
import 'package:http/http.dart' as http;

class ForgotPasswordOTPScreen extends StatefulWidget {
  final email;
  const ForgotPasswordOTPScreen({super.key, required this.email});

  @override
  State<ForgotPasswordOTPScreen> createState() =>
      _ForgotPasswordOTPScreenState();
}

class _ForgotPasswordOTPScreenState extends State<ForgotPasswordOTPScreen> {
  bool isLoading = false;
  //String finOTP = '123456';

  bool inValidOTP = false;
  String enteredOTP = '';
  String otpErrorMsg = '';

  bool clearOTP = false;

  Future<void> validateOTP(String receivedOTP) async {
    final url = Uri.parse(
        AppConstants.BASE_URL + AppConstants.FORGOT_PASSWORD_OTP_VERIFY);

    final bodyParams = {"token": receivedOTP};

    try {
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
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
        return; // Exit the function if no internet
      }
      setState(() {
        isLoading = true;
      });

      final response = await http.post(url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(bodyParams));

      if (kDebugMode) {
        print(
            'Response code ${response.statusCode} :: Response => ${response.body}');
      }

      var resOBJ = jsonDecode(response.body);
      String statusMessage = resOBJ['message'];

      if (response.statusCode == 200) {
        if (statusMessage.toLowerCase().contains('success')) {
          String id = resOBJ['id'];
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
                builder: (context) => ResetNewPassword(
                      id: id,
                    )),
            (Route<dynamic> route) => route.isFirst, // This will keep Screen 1
          );
        }
      } else if (response.statusCode >= 400) {
        setState(() {
          inValidOTP = true;
          otpErrorMsg = 'Incorrect OTP';
        });
        // Fluttertoast.showToast(
        //     msg: statusMessage,
        //     toastLength: Toast.LENGTH_SHORT,
        //     gravity: ToastGravity.BOTTOM,
        //     timeInSecForIosWeb: 1,
        //     backgroundColor: Colors.red,
        //     textColor: Colors.white,
        //     fontSize: 16.0);
       /* IconSnackBar.show(
          context,
          label: statusMessage,
          snackBarType: SnackBarType.alert,
          backgroundColor: Color(0xffBA1A1A),
          iconColor: Colors.white,
        );*/
      }
    } catch (e) {
      print(e);
    } finally {
      setState(() {
        clearOTP = true;
        isLoading = false;
      });
    }
  }

  Future<void> sendPasswordRestOTP() async {
    final url = Uri.parse(AppConstants.BASE_URL + AppConstants.FORGOT_PASSWORD);
    final bodyParams = {
      "email": widget.email,
    };

    try {
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
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
        return; // Exit the function if no internet
      }
      setState(() {
        isLoading = true;
      });

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(bodyParams),
      );

      if (kDebugMode) {
        print(
            'Response code ${response.statusCode} :: Response => ${response.body}');
      }

      var resOBJ = jsonDecode(response.body);

      String statusMessage = resOBJ['message'];
      String status = resOBJ['status'];

      if (response.statusCode == 200) {
        if (status.toLowerCase().trim().contains('ok') ||
            statusMessage.toLowerCase().trim().contains('successfully')) {
          // Fluttertoast.showToast(
          //     msg: statusMessage,
          //     toastLength: Toast.LENGTH_SHORT,
          //     gravity: ToastGravity.BOTTOM,
          //     timeInSecForIosWeb: 1,
          //     backgroundColor: Colors.green,
          //     textColor: Colors.white,
          //     fontSize: 16.0);
          IconSnackBar.show(
            context,
            label: statusMessage,
            snackBarType: SnackBarType.success,
            backgroundColor: Color(0xff4CAF50),
            iconColor: Colors.white,
          );
        } else {
          // Fluttertoast.showToast(
          //     msg: statusMessage,
          //     toastLength: Toast.LENGTH_SHORT,
          //     gravity: ToastGravity.BOTTOM,
          //     timeInSecForIosWeb: 1,
          //     backgroundColor: AppColors.primaryColor,
          //     textColor: Colors.white,
          //     fontSize: 16.0);
          IconSnackBar.show(
            context,
            label: statusMessage,
            snackBarType: SnackBarType.alert,
            backgroundColor: Color(0xff004C99),
            iconColor: Colors.white,
          );
        }
      }
    } catch (e) {
      print('Error : ${e}');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffFCFCFC),
      body: Stack(
        children: [
          Positioned(
            right: 0,
            child: Image.asset('assets/images/Ellipse 1.png'),
          ),
          Positioned(
            left: 0,
            bottom: 0,
            child: Image.asset('assets/images/ellipse_bottom.png'),
          ),
          Positioned(
            top: 120,
            child: Container(
              width: MediaQuery.of(context).size.width,
              padding: EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.4,
                    child: FittedBox(
                      child: SvgPicture.asset('assets/images/otp_img.svg'),
                      fit: BoxFit.contain,
                    ),
                  ),
                  Center(
                      child: Text(
                    'Enter OTP',
                    style: TextStyle(
                        color: Color(0xff333333),
                        fontFamily: 'Lato',
                        fontSize: 16,
                        fontWeight: FontWeight.w700),
                  )),
                  SizedBox(
                    height: 20,
                  ),
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [Color(0xff545454), Color(0xff004C99)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ).createShader(
                        Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
                    blendMode: BlendMode.srcIn,
                    child: Text(
                      'Please enter the OTP send to your email',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontWeight: FontWeight.w400,
                          color: Color(0xff545454),
                          fontSize: 14,
                          fontFamily: 'Lato'),
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  SizedBox(
                    height: 50,
                  ),
                  /* Container(
                    width: MediaQuery.of(context).size.width - 20,
                    child: OtpTextField(
                      numberOfFields: 6,
                      borderColor: Color(0xFF512DA8),
                      showFieldAsBox: false,
                      clearText: clearOTP,
                      enabled: !isLoading,
                      onCodeChanged: (String code) {
                        setState(() {
                          clearOTP = false;
                        });
                      },
                      //runs when every textfield is filled
                      onSubmit: (String verificationCode){

                        setState(() {
                          finOTP = verificationCode;
                        });
                        validateOTP(verificationCode);

                      }, // end onSubmit
                    ),
                  ),*/

                  OtpPinField(
                    cursorColor: AppColors.primaryColor,
                    autoFillEnable: false,
                    maxLength: 6,
                    onSubmit: (otp) {},
                    onChange: (txt) {
                      print('txt: ${txt} length: ${txt.length}');
                      setState(() {
                        enteredOTP = txt;
                        inValidOTP = false;
                      });
                    },
                    otpPinFieldStyle: OtpPinFieldStyle(
                      activeFieldBorderColor: AppColors.primaryColor,
                      defaultFieldBorderColor:
                          inValidOTP ? Color(0xffBA1A1A) : Color(0xff333333),
                    ),
                    otpPinFieldDecoration:
                        OtpPinFieldDecoration.underlinedPinBoxDecoration,
                  ),
                  inValidOTP
                      ? Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(30, 20, 0, 0),
                              child: Text(
                                otpErrorMsg,
                                style: TextStyle(
                                  fontFamily: 'Lato',
                                  fontSize: 12,
                                  color: Color(0xffBA1A1A),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Container(),
                  SizedBox(height: 50),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Didn\'t receive the code?',
                        style: TextStyle(
                            color: Color(0xff333333),
                            fontFamily: 'Lato',
                            fontSize: 14,
                            fontWeight: FontWeight.w400),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      InkWell(
                          onTap: () {
                            sendPasswordRestOTP();
                          },
                          child: Text(
                            'Resend',
                            style: TextStyle(
                                color: Color(0xff004C99),
                                fontFamily: 'Lato',
                                fontSize: 14,
                                fontWeight: FontWeight.w600),
                          )),
                    ],
                  ),
                  SizedBox(
                    height: 30,
                  ),
                  InkWell(
                    onTap: () {
                      //validateOTP(finOTP);
                      if (kDebugMode) print('length ${enteredOTP.length}');
                      if (enteredOTP.length < 6) {
                        setState(() {
                          inValidOTP = true;
                          otpErrorMsg = 'Enter OTP';
                        });
                      } else {
                        validateOTP(enteredOTP);
                      }
                    },
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      height: 44,
                      margin: EdgeInsets.symmetric(horizontal: 10),
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                          color: AppColors.primaryColor,
                          borderRadius: BorderRadius.circular(10)),
                      child: Center(
                        child: isLoading
                            ? SizedBox(
                                height: 24,
                                width: 24,
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween<double>(begin: 0, end: 5),
                                  duration: Duration(seconds: 2),
                                  curve: Curves.linear,
                                  builder: (context, value, child) {
                                    return Transform.rotate(
                                      angle: value *
                                          2 *
                                          3.1416, // Full rotation effect
                                      child: CircularProgressIndicator(
                                        strokeWidth: 4,
                                        value: 0.20, // 1/5 of the circle
                                        backgroundColor: const Color.fromARGB(
                                            142, 234, 232, 232), // Grey stroke
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(Colors
                                                .white), // White rotating stroke
                                      ),
                                    );
                                  },
                                  onEnd: () =>
                                      {}, // Ensures smooth infinite animation
                                ),
                              )
                            : Text(
                                'Verify',
                                style: TextStyle(color: Colors.white),
                              ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 60,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
              top: 40,
              left: 0,
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  InkWell(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Container(
                          height: 50,
                          child: Center(
                              child: Text(
                            'Back',
                            style: TextStyle(fontSize: 16),
                          ))))
                ],
              )),
        ],
      ),
    );
  }
}
