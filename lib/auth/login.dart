// ignore_for_file: use_build_context_synchronously

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutterfirebase/components/constant_widget.dart';
import 'package:flutterfirebase/components/custom_button_auth.dart';
import 'package:flutterfirebase/components/text_form.dart';
import 'package:flutterfirebase/view/veiw_statioon.dart';

class LogIn extends StatefulWidget {
  const LogIn({Key? key}) : super(key: key);

  @override
  State<LogIn> createState() => _LogInState();
}

class _LogInState extends State<LogIn> {
  bool passwordVisible = false;
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  GlobalKey<FormState> formState = GlobalKey<FormState>();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading ? _buildLoadingIndicator() : _buildLoginForm(),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(
        color: Colors.blue,
      ),
    );
  }

  Widget _buildLoginForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          Form(
            key: formState,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const ConstantWidget(),
                const SizedBox(height: 30),
                _buildLoginTitle(),
                const SizedBox(height: 20),
                _buildEmailTextField(),
                const SizedBox(height: 16),
                _buildPasswordTextField(),
                const SizedBox(height: 20),
                _buildLoginButton(),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginTitle() {
    return Center(
      child: const Text(
        "تسجيل الدخول ",
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmailTextField() {
    return CustomTextForm(
      prefixIcon: Icons.person,
      keyboardType: TextInputType.emailAddress,
      hintText: " ادخل الحساب ",
      myController: emailController,
      validator: (val) => val!.isEmpty ? "لا يمكن ان تكون الخانه فارغة" : null,
    );
  }

  Widget _buildPasswordTextField() {
    return TextFormField(
      validator: (val) => val!.isEmpty ? "لا يمكن ان تكون الخانه فارغة" : null,
      controller: passwordController,
      obscureText: !passwordVisible,
      keyboardType: TextInputType.emailAddress,
      cursorColor: Colors.blue,
      decoration: InputDecoration(
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(
            color: Color(0xFFBDBDBD),
          ),
          borderRadius: BorderRadius.circular(70),
        ),
        fillColor: Colors.grey[100],
        filled: true,
        suffixIcon: IconButton(
          onPressed: () {
            setState(() {
              passwordVisible = !passwordVisible;
            });
          },
          icon: Icon(
            passwordVisible ? Icons.visibility_off : Icons.visibility,
          ),
        ),
        prefixIcon: Icon(
          Icons.lock,
          color: Colors.blue,
        ),
        border: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.grey, width: 5),
          borderRadius: BorderRadius.circular(70),
        ),
        hintText: " ادخل الرقم السري ",
      ),
    );
  }

  Widget _buildLoginButton() {
    return CustomButtonAuth(
      child: "تسجيل الدخول ",
      onPressed: () async {
        if (formState.currentState!.validate()) {
          _handleLogin();
        }
      },
    );
  }

  void _handleLogin() async {
    try {
      setState(() {
        isLoading = true;
      });

      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text, password: passwordController.text);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) {
          return const StationName();
        }),
      );

      setState(() {
        isLoading = false;
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        isLoading = false;
      });

      _handleLoginError(e.code);
    }
  }

  void _handleLoginError(String errorCode) {
    if (errorCode == 'network-request-failed') {
      _showErrorDialog(' خطأ في الاتصال ');
    } else if (errorCode == 'user-not-found') {
      _showErrorDialog(' لم يتم العثور على مستخدم بهذا البريد الإلكتروني ');
    } else if (errorCode == 'wrong-password') {
      _showErrorDialog(' كلمة مرور خاطئة لهذا المستخدم ');
    }
  }

  void _showErrorDialog(String message) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      animType: AnimType.rightSlide,
      desc: message,
    ).show();
  }
}
