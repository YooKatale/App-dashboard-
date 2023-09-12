import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yookatale/features/authentication/widgets/login.dart';
import 'package:yookatale/features/common/widgets/custom_button.dart';

import '../../common/controller/utility_method.dart';
import '/features/authentication/widgets/auth_form.dart';
import '/features/common/widgets/auth_heading.dart';
import '/features/common/widgets/base_widget.dart';

// ignore: must_be_immutable
class SignUpPage extends ConsumerStatefulWidget {
  const SignUpPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage> {
// class SignUpPage extends ConsumerWidget {
  // SignUpPage({super.key});
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String firstName = '';
  String lastName = '';
  String phoneNumber = '';
  String gender = 'Select gender';
  String email = '';
  String password = '';
  bool isVegiterian = false;
  bool agreeTerms = false;
  DateTime? bod;

  TextEditingController? firstNameController = TextEditingController();
  TextEditingController? lastNameController = TextEditingController();
  TextEditingController? emailController = TextEditingController();
  TextEditingController? passwordController = TextEditingController();
  TextEditingController? phoneNumberController = TextEditingController();
  // TextEditingController? passwordController;
  // TextEditingController? passwordController;
  // TextEditingController? passwordController;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: BaseWidget(
          child: SizedBox(
        width: 500,
        height: MediaQuery.of(context).size.height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const AuthHeading(),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    AuthForm(
                      label: 'Firstname',
                      hintText: 'firstname is required',
                      controller: firstNameController!,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password is required';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        firstName = value!;
                      },
                    ),
                    const SizedBox(height: 12),
                    AuthForm(
                      label: 'Lastname',
                      hintText: 'lastname is required',
                      controller: lastNameController!,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password is required';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        lastName = value!;
                      },
                    ),
                    const SizedBox(height: 12),
                    AuthForm(
                      label: 'Phone Number',
                      hintText: 'include country code [+256...]',
                      controller: phoneNumberController!,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password is required';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        firstName = value!;
                      },
                    ),
                    const SizedBox(height: 12),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Gender',
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          color: Color(0XFF1A202C),
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Cabin',
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        height: 38,
                        width: MediaQuery.of(context).size.width,
                        child: DropdownButtonFormField<String>(
                          style: const TextStyle(
                            color: Color(0XFF1A202C),
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Cabin',
                          ),
                          value: gender,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 0),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Color.fromRGBO(61, 60, 60, 0.2),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Color.fromARGB(255, 10, 118, 207),
                              ), // Change border color here
                            ),
                          ),
                          // hint: Text('Select gender'),
                          borderRadius: BorderRadius.circular(4),
                          isExpanded: true,
                          items: ['Select gender', 'Male', 'Female']
                              .map<DropdownMenuItem<String>>((value) {
                            return DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? value) {
                            if (value == null) return;
                            setState(() {
                              gender = value;
                            });
                          },
                          dropdownColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    AuthForm(
                      label: 'Email *',
                      hintText: 'email is required',
                      controller: emailController!,
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
                      onSaved: (value) {
                        setState(() {
                          email = value!;
                          log('email: $email');
                        });
                      },
                    ),
                    const SizedBox(height: 15),
                    Container(
                      width: MediaQuery.of(context).size.width,
                      child: const Align(
                        alignment: Alignment.centerLeft,
                        widthFactor: BorderSide.strokeAlignCenter,
                        child: Text(
                          'Date of Birth *',
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            color: Color(0XFF1A202C),
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Cabin',
                          ),
                        ),
                      ),
                    ),
                    DatePicker(),
                    const SizedBox(height: 12),
                    AuthForm(
                      label: 'Password *',
                      hintText: 'password is required',
                      controller: passwordController!,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password is required';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        setState(() {
                          password = value!;
                          log('password: $password');
                        });
                      },
                    ),
                    Row(
                      children: [
                        const Text(
                          'Access your account',
                          style: TextStyle(
                            fontFamily: 'Cabin',
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        TextButton(
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                              fontFamily: 'Cabin',
                              color: Color.fromRGBO(24, 95, 45, 1),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LoginPage(),
                                ));
                          },
                        )
                      ],
                    ),
                    const CheckBoxWidget(),
                    const SizedBox(
                      height: 15,
                    ),
                    Align(
                        alignment: Alignment.centerLeft,
                        child: CustomButton(
                          onPressed: () {},
                          title: 'Sign Up',
                          width: 120,
                        ))
                  ],
                ),
              ),
            )
          ],
        ),
      )),
    );
  }
}

class DatePicker extends StatefulWidget {
  DatePicker({
    super.key,
  });

  @override
  State<DatePicker> createState() => _DatePickerState();
}

class _DatePickerState extends State<DatePicker> {
  final TextEditingController dateController = TextEditingController();

  final DateTime dateUpperLimit = DateTime.now();

  DateTime? newSelectedDate;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        String currentValue = dateController.text;
        if (!GetUtils.isDateTime(currentValue)) {
          currentValue = dateFormatter(date: dateUpperLimit);
        }
        final DateTime currentDate = DateTime.parse(currentValue);
        newSelectedDate = await showDatePicker(
          context: context,
          initialDate: currentDate,
          firstDate: DateTime(1930),
          lastDate: dateUpperLimit,
          builder: (BuildContext context, Widget? child) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 2,
              // width: MediaQuery.of(context).size.width,
              child: child,
            );
          },
        );
        if (newSelectedDate != null) {
          setState(() {
            dateController.text =
                DateFormat('dd/MM/yyyy').format(newSelectedDate!);
          });
        }
      },
      child: Row(
        children: [
          SizedBox(
            height: 38,
            // width: 400,
            width: MediaQuery.of(context).size.width * 0.83,
            child: TextFormField(
              textAlignVertical: TextAlignVertical.center,
              enabled: false,
              decoration: InputDecoration(
                suffixIcon: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: FaIcon(FontAwesomeIcons.calendar),
                ),
                disabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Color.fromRGBO(61, 60, 60, 0.2),
                  ),
                ),
                hintText: dateController.text ?? 'dd/mm/yyyy',
                hintStyle: const TextStyle(
                  fontFamily: 'Cabin',
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: Colors.black,
                  // color: Color(0XFFA0AEC0),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide:
                      BorderSide(color: Color.fromARGB(255, 34, 104, 235)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CheckBoxWidget extends StatefulWidget {
  const CheckBoxWidget({super.key});

  @override
  State<CheckBoxWidget> createState() => _CheckBoxWidgetState();
}

class _CheckBoxWidgetState extends State<CheckBoxWidget> {
  bool isVegetarian = false;
  bool agreeTerms = false;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            SizedBox(
              height: 20,
              child: Checkbox(
                value: isVegetarian,
                onChanged: (value) {
                  setState(() {
                    isVegetarian = value!;
                  });
                },
              ),
            ),
            const Text(
              'Are you vegetarian',
              style: TextStyle(
                fontFamily: 'Cabin',
                color: Colors.black,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            SizedBox(
              height: 20,
              child: Checkbox(
                value: agreeTerms,
                onChanged: (value) {
                  setState(() {
                    agreeTerms = value!;
                  });
                },
              ),
            ),
            const Text(
              'I agree to the ',
              style: TextStyle(
                fontFamily: 'Cabin',
                color: Colors.black,
                fontWeight: FontWeight.w400,
              ),
            ),
            const Text(
              'terms and conditions ',
              style: TextStyle(
                fontFamily: 'Cabin',
                color: Color.fromRGBO(24, 95, 45, 1),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        )
      ],
    );
  }
}
