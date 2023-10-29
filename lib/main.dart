import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'screens/acceuil.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.blue, // La couleur de votre choix
        ).copyWith(
          secondary:
              Colors.white, // Couleur du texte et des champs du formulaire
        ),
        // ...
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text("se connecter"),
          backgroundColor: const Color(0xFF343A40),
        ),
        body: const Padding(
          padding: EdgeInsets.all(0.0),
          child: MyForm(), // Utiliser le formulaire que nous allons créer
        ),
      ),
    );
  }
}

class MyForm extends StatefulWidget {
  const MyForm({super.key});

  @override
  _MyFormState createState() => _MyFormState();
}

Future<Map<String, dynamic>> loginUser(
    BuildContext context, String username, String password) async {
  final url = Uri.parse("https://kpks-76bbd2eed811.herokuapp.com/api/login");
  final headers = {"Content-Type": "application/json"};
  final data = jsonEncode({"username": username, "password": password});

  try {
    final response = await http.post(url, headers: headers, body: data);

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      if (jsonResponse["message"] == "Logged in successfully.") {
        String userStatus = jsonResponse["statut"];
        int id = jsonResponse["id"];
        print("Connexion réussie");
        print(userStatus);

        // Créez un objet Map pour contenir userStatus et id
        Map<String, dynamic> userData = {
          "userStatus": userStatus,
          "id": id,
        };

        // Rediriger vers la page d'accueil si la connexion réussit
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => AccueilPage(userData: userData),
          ),
        );
        return userData;
      } else {
        print("Identifiants invalides.");
      }
    } else {
      print("Erreur lors de la requête: ${response.statusCode}");
    }
  } catch (e) {
    print("Erreur lors de la requête: $e");
  }

  // Si une erreur se produit ou si la connexion échoue, vous pouvez renvoyer une valeur par défaut ou une chaîne vide, par exemple.
  return {"error": "Une erreur s'est produite"};
}

class _MyFormState extends State<MyForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isObscure = true;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Container(
        color: const Color(0xFF343A40), // Couleur #343a40
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nom'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer un nom';
                }
                return null;
              },
            ),
            const SizedBox(height: 16.0),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                suffixIcon: IconButton(
                  icon: Icon(
                    _isObscure ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _isObscure = !_isObscure;
                    });
                  },
                ),
              ),
              obscureText: _isObscure,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer un mot de passe';
                } else {
                  return null;
                }
              },
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState != null &&
                    _formKey.currentState!.validate()) {
                  String name = _nameController.text;
                  String password = _passwordController.text;

                  await loginUser(context, name,
                      password); // Appeler la fonction avec les bons paramètres
                }
              },
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(
                    Colors.black), // Couleur noire foncée
              ),
              child: const Text('Envoyer'),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(const MyApp());
}
