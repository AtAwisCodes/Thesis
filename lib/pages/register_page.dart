import 'package:flutter/material.dart';
import 'package:rexplore/components/my_textfield.dart';
import 'package:rexplore/components/my_button.dart';
import 'package:rexplore/pages/login_page.dart';

class RegisterPage extends StatelessWidget {
  RegisterPage({super.key});

  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  void createAccount() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
            child: Center(
          child: SingleChildScrollView(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              SizedBox(
                height: 30,
              ),

              //Logo
              Icon(
                Icons.access_time_filled_outlined,
                size: 100,
              ),

              //Welcome text
              Text(
                'Welcome back!',
                style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
              ),

              //Caption text
              Text('Create your account!'),

              SizedBox(
                height: 25,
              ),

              //Username textbox
              MyTextfield(
                controller: usernameController,
                hintText: 'Email',
                obscureText: false,
              ),

              SizedBox(
                height: 8,
              ),

              //Password textbox
              MyTextfield(
                controller: passwordController,
                hintText: 'Password',
                obscureText: true,
              ),

              SizedBox(
                height: 8,
              ),

              //Confirm Pass textbox
              MyTextfield(
                controller: confirmPasswordController,
                hintText: 'Confirm Password',
                obscureText: true,
              ),

              const SizedBox(
                height: 10,
              ),

              //Create Account button
              MyButton(
                onTap: createAccount,
              ),

              const SizedBox(
                height: 30,
              ),

              //Already have an account
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('Already have an account?',
                    style: TextStyle(color: Colors.grey[700])),
                const SizedBox(width: 6),
                TextButton(
                  style: TextButton.styleFrom(
                      textStyle: const TextStyle(
                          color: Colors.blue, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LoginPage()),
                    );
                  },
                  child: const Text('Sign up'),
                ),
              ])
            ]),
          ),
        )));
  }
}
