import 'package:flutter/material.dart';
import 'package:yoga_monitor/screens/signup_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../reuseable_widgets/reuseable_widget.dart';
import '../utils/color_utils.dart';
import 'package:yoga_monitor/screens/mainpage.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({Key? key}) : super(key: key);

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  TextEditingController _passwordTextController = TextEditingController();
  TextEditingController _emailTextController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Sign In'),
        ),
        body: Container(

        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(10, MediaQuery.of(context).size.height * 0.3, 10,MediaQuery.of(context).size.height*0.3 ),
            child: Column(
              children: <Widget>[
                const SizedBox(
                height: 30,
                ),
                reusableTextField("Enter UserName", Icons.person_outline, false,_emailTextController),
                const SizedBox(
                height: 20,
                ),
                reusableTextField("Enter Password", Icons.lock_outline, true,_passwordTextController),

                firebaseUIButton(context, "Sign In", () {
                  FirebaseAuth.instance
                      .signInWithEmailAndPassword(
                      email: _emailTextController.text,
                      password: _passwordTextController.text)
                      .then((value) {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => MainHomePage()));
                  }).onError((error, stackTrace) {
                    // print("Error ${error.toString()}");
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Password incorrect. Please try again.'),
                        duration: Duration(seconds: 3), // Adjust the duration as needed
                      ),
                    );
                  });
                }),
                signUpOption(),

              ]
            ),
          ),
        ),
        ),
    );
  }
  Row signUpOption() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Don't have account?",
            style: TextStyle(color: Colors.black)),
        GestureDetector(
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => SignUpScreen()));
          },
          child: const Text(
            " Sign Up",
            style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
          ),
        )
      ],
    );
  }
}
