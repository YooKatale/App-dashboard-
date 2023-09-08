import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../app.dart';
import '../../../main.dart';
import '../../common/controller/utility_method.dart';
import '../providers/auth_provider.dart';
import '/features/authentication/widgets/sign_up.dart';
import '/features/common/widgets/base_widget.dart';
import '/features/common/widgets/custom_button.dart';
import '../../common/widgets/auth_heading.dart';
import 'auth_form.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  void googleLogin({
    required BuildContext context,
  }) async {
    var navigator = Navigator.of(context);

    try {
      if (kIsWeb) {
        userCredential = await auth!.signInWithPopup(authProvider);
        user = userCredential!.user;
        log('user: ${user!.uid}');
      } else {
        googleSignInAccount = await googleSignIn.signIn();
        log('googleSignInAccount: $googleSignInAccount');

        await googleSignInAccount!.authentication;
        userCredential = await auth!.signInWithCredential(
            GoogleAuthProvider.credential(
                idToken: googleSignInAuthentication!.idToken,
                accessToken: googleSignInAuthentication!.accessToken));
      }

      if (userCredential!.user != null) {
        !kIsWeb
            ? getUserProfile(googleSignInAccount!.id)
            : getUserProfile(user!.uid);

        ref.read(authStateProvider.notifier).state = const AuthState.loggedIn();

        navigator.push(MaterialPageRoute(
            builder: (context) =>
                App(uid: kIsWeb ? user!.uid : googleSignInAccount!.id)));
      }
    } on Exception catch (err) {
      log('Error: $err');

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error logging in: $err'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void login(
      {required BuildContext context,
      required String userEmail,
      required String userPassword}) async {
    var navigator = Navigator.of(context);

    String email = userEmail;
    String password = userPassword;
    log('User: $email $password');
    try {
      UserCredential userCredential = await auth!
          .signInWithEmailAndPassword(email: email, password: password);
      log('user: ${userCredential.user!.displayName}');
      if (userCredential.user != null) {
        navigator.push(MaterialPageRoute(builder: (context) => App()));
      }
    } catch (err) {
      log('Error: $err');
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loging in: $err'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    var loginProvider = ref.read(authStateProvider).isLoggedIn;
    log('loginProvider $loginProvider');

    return BaseWidget(
        child: Center(
      child: SizedBox(
        width: 500,
        height: MediaQuery.of(context).size.height * 0.58,
        child: Column(
          children: [
            const AuthHeading(),
            const SizedBox(height: 50),
            Container(
              // height: 200,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AuthForm(
                      controller: emailController,
                      label: 'Email',
                      hintText: 'email is required',
                      validator: (value) {
                        final emailRegExp =
                            RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                        if (value == null || value.isEmpty) {
                          return 'Email is required';
                        } else if (!emailRegExp.hasMatch(value)) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                      onFieldSubmitted: (value) {
                        setState(() {
                          email = value;
                        });
                      },
                      onSaved: (value) {
                        setState(() {
                          email = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    AuthForm(
                      controller: passwordController,
                      label: 'Password',
                      hintText: 'password is required',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password is required';
                        }
                        return null;
                      },
                      onFieldSubmitted: (value) {
                        setState(() {
                          password = value;
                        });
                      },
                      onSaved: (value) {
                        setState(() {
                          password = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text(
                          'Create new account',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextButton(
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              color: Color.fromRGBO(24, 95, 45, 1),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SignUpPage(),
                                ));
                          },
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        CustomButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              _formKey.currentState!.save();
                              log('Email: $email, password: $password');
                              login(
                                  context: context,
                                  userEmail: email,
                                  userPassword: password);
                            }
                          },
                          title: 'Sign In',
                          width: 100,
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            googleLogin(context: context);
                          },
                          icon: const FaIcon(
                            FontAwesomeIcons.google,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Google sign In',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            fixedSize: const Size(170, 40),
                            backgroundColor:
                                const Color.fromRGBO(24, 95, 45, 1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    ));
  }
}
