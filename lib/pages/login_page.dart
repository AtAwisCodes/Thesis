import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rexplore/components/my_button.dart';
import 'package:rexplore/components/my_textfield.dart';
import 'package:rexplore/components/square_tile.dart';

class LoginPage extends StatefulWidget {
  final Function()? onTap;
  LoginPage({super.key, this.onTap});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
// text editting controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

//Create Account button
  void createAccount() async {
    //loading screen
    showDialog(
      context: context,
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    //Email&Password Validation
    Navigator.pop(context);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );
      //pop loading screen
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context);
      if (e.code == 'user-not-found') {
        wrongEmailMessage();
      } else if (e.code == 'wrong password') {
        wrongPasswordMessage();
      }
    }
  }

//Notification para sa maling email at password
  void wrongEmailMessage() {
    showDialog(
      context: context,
      builder: (context) {
        return const AlertDialog(
          title: Text('Incorrect Email'),
        );
      },
    );
  }

  void wrongPasswordMessage() {
    showDialog(
      context: context,
      builder: (context) {
        return const AlertDialog(
          title: Text('Incorrect Password'),
        );
      },
    );
  }

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
                controller: emailController,
                hintText: 'Email',
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

              const SizedBox(
                height: 10,
              ),

              // Sign in button
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
                  onTap: widget.onTap,
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
