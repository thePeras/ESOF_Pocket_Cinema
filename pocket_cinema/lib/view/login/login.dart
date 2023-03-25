import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pocket_cinema/controller/firestore_funcs.dart';
import 'package:pocket_cinema/view/common_widgets/password_form_field.dart';
import 'package:pocket_cinema/view/common_widgets/login_register_tabs.dart';
import 'package:pocket_cinema/view/theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _userIdTextController = TextEditingController();
  final TextEditingController _passwordTextController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Text("Pocket Cinema",
                        textScaleFactor: 3,
                      ),
                    ),
                    const LoginRegisterSegmentedButton(selectedPage: LoginRegister.login),
                  TextFormField(
                    decoration: InputDecoration(
                      hintText: "Email or Username",
                      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                      border: const OutlineInputBorder(),
                      fillColor: Theme.of(context).colorScheme.onPrimary,
                      filled: true,
                    ),
                    style: const TextStyle(color: Colors.black,),
                    controller: _userIdTextController,
                  ),
                  PasswordFormField(
                    labelText: 'Password',
                    passwordController: _passwordTextController,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      signIn().then((value) {
                        Navigator.pushNamed(context, '/');
                      }).onError((error, stackTrace) {
                        print("Error: ${error.toString()}");
                      });
                    },
                    child: const Text('Login'),
                    ),
                    const Divider(),
                  ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Login with Google')),
                ])));
  }
  Future signIn() async {
    final userId = _userIdTextController.text;
    return FirebaseAuth.instance.signInWithEmailAndPassword(
      email: isEmail(userId) ? userId : await getEmail(userId).then((email) => email),
      password: _passwordTextController.text,
    ).onError((error, stackTrace) {
      throw("Error: ${error.toString()}");
    });
  }
}
