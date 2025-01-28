import 'package:flutter/material.dart';
import 'package:rexplore/components/my_button.dart';
import 'package:rexplore/components/my_textfield.dart';
import 'package:rexplore/components/square_tile.dart';
import 'package:rexplore/pages/forgotPass_page.dart';
import 'package:rexplore/pages/register_page.dart';

class LoginPage extends StatelessWidget {
  final Function()? onTap;
  LoginPage({super.key, required this.onTap});

// text editting controllers
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

//Create Account button
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
              const SizedBox(
                height: 30,
              ),

              //logo
              const Icon(
                Icons.local_car_wash,
                size: 100,
              ),

              const SizedBox(
                height: 50,
              ),

              //Welcome
              Text(
                'Welcome!',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 50,
                  fontWeight: FontWeight.bold,
                ),
              ),

              //Create your account
              Text('Login to your account!'),

              const SizedBox(
                height: 25,
              ),

              // Username
              MyTextfield(
                controller: usernameController,
                hintText: 'Username',
                obscureText: false,
              ),

              const SizedBox(
                height: 8,
              ),

              // password
              MyTextfield(
                controller: passwordController,
                hintText: 'Password',
                obscureText: true,
              ),

              const SizedBox(
                height: 8,
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        textStyle: const TextStyle(color: Colors.grey),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ForgotPassword()),
                        );
                      },
                      child: const Text('Forgot Password?'),
                    )
                  ],
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              // button
              MyButton(
                text: "Sign In",
                onTap: createAccount,
              ),

              const SizedBox(
                height: 30,
              ),

              // or sign in with
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Divider(
                        thickness: 1,
                        color: Colors.black,
                      ),
                    ),
                    Text('Or continue with'),
                    Expanded(
                      child: Divider(
                        thickness: 1,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 30,
              ),

              // google logo
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [SquareTile(imagePath: 'lib/icons/Google.png')],
              ),

              const SizedBox(
                height: 30,
              ),

              //already have an account
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('Don\'t have an account yet?',
                    style: TextStyle(color: Colors.grey[700])),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onTap,
                  child: const Text(
                    'Register now',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ])
            ]),
          ),
        )));
  }
}
