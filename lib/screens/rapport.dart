import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RapportForm extends StatefulWidget {
  final Map<String, dynamic> userData;

  const RapportForm({super.key, required this.userData});

  @override
  _RapportFormState createState() => _RapportFormState();
}

class _RapportFormState extends State<RapportForm> {
  int? selectedReceveurId; // Pour stocker l'ID du receveur sélectionné
  String? selectedReceveur; // Pour stocker le receveur sélectionné
  Map<int, String> receveurNamesAndIds =
      {}; // Pour stocker les noms des receveurs
  int? selectedEnvoyeurId; // Pour stocker l'ID de l'envoyeur sélectionné

  String? text; // Pour stocker le texte
  int? selectedNote; // Pour stocker la note choisie

  @override
  void initState() {
    super.initState();
    selectedEnvoyeurId = widget.userData["id"];
    fetchReceveurNames();
  }

  Future<void> fetchReceveurNames() async {
    final Uri url =
        Uri.parse("https://kpks-76bbd2eed811.herokuapp.com/api/user-receveur");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      final Map<int, String> namesAndIds = {}; // Créons un dictionnaire vide

      for (var item in data) {
        namesAndIds[item['id']] =
            item['username']; // Ajouton les entrées au dictionnaire
      }

      setState(() {
        receveurNamesAndIds = namesAndIds;
      });
    } else {
      throw Exception('Échec de chargement des noms depuis l\'API');
    }
  }

  Future<void> submitRapport() async {
    if (selectedReceveurId == null || text == null || selectedNote == null) {
      // Vérifiez que toutes les informations requises sont remplies
      // Vous pouvez également afficher une boîte de dialogue ou un message d'erreur ici
      return;
    }

    // Utilisez l'ID pour construire l'objet JSON avec les données du formulaire
    final Map<String, dynamic> formData = {
      'envoyeur': selectedEnvoyeurId,
      'receveur': selectedReceveurId,
      'texte': text,
      'note': selectedNote,
      // Ajoutez d'autres champs du formulaire ici
    };

    final Uri url =
        Uri.parse("https://kpks-76bbd2eed811.herokuapp.com/api/rapport");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(formData),
    );

    if (response.statusCode == 200) {
      print("rapport envoyé!!");
    } else {
      print("rapport non envoyé!!");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF343A40),
      body: Padding(
        padding: const EdgeInsets.all(0.0),
        child: Center(
          child: Container(
            width: 400, // Largeur du conteneur
            padding: const EdgeInsets.all(20), // Marge intérieure du conteneur
            decoration: BoxDecoration(
              border: Border.all(
                  color: Colors.white, width: 5), // Bordure blanche de 5 pixels
              borderRadius:
                  BorderRadius.circular(10), // Coins arrondis pour la bordure
              color: const Color(
                  0xFF343A40), // Couleur de fond à l'intérieur de la bordure
            ),
            child: Column(
              children: [
                TextFormField(
                  controller: TextEditingController(
                      text: selectedEnvoyeurId
                          .toString()), // Initialisez la valeur avec l'ID actuel (converti en chaîne)
                  style: const TextStyle(
                      color: Colors.transparent), // Rend le texte invisible
                  decoration: const InputDecoration(
                    border: InputBorder
                        .none, // Supprime la bordure du champ de texte
                    hintText:
                        'Envoyeur ID', // Texte d'indice (non visible lorsque le champ a du texte)
                    hintStyle: TextStyle(
                        color: Colors.transparent), // Rend l'indice invisible
                    // Définissez d'autres propriétés de décoration selon vos besoins
                    // ...
                  ),
                ),
                DropdownButtonFormField<int>(
                  value: selectedReceveurId, // Sélection initiale vide
                  items: receveurNamesAndIds.entries.map((entry) {
                    return DropdownMenuItem<int>(
                      value: entry.key,
                      child: Text(entry.value), // Affichez le nom
                    );
                  }).toList(),
                  onChanged: (int? newValue) {
                    setState(() {
                      selectedReceveurId = newValue;
                    });
                  },
                  hint: const Text('Sélectionnez un receveur'),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Texte du Rapport',
                    border: OutlineInputBorder(),
                  ),
                  maxLines:
                      4, // Vous pouvez ajuster le nombre de lignes selon vos besoins
                  onChanged: (value) {
                    setState(() {
                      text = value;
                    });
                  },
                ),
                RatingBar.builder(
                  initialRating: selectedNote?.toDouble() ?? 0,
                  minRating: 1,
                  maxRating: 5,
                  direction: Axis.horizontal,
                  allowHalfRating: false,
                  itemCount: 5,
                  itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                  itemBuilder: (context, _) => const Icon(
                    Icons.star,
                    color: Colors.amber,
                  ),
                  onRatingUpdate: (double rating) {
                    setState(() {
                      selectedNote = rating.toInt();
                    });
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    // Soumettez le formulaire avec les données requises, y compris le receveur sélectionné
                    submitRapport();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors
                        .black, // Couleur de fond du bouton (noir dans ce cas)
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          10), // Coins arrondis pour le bouton
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(10), // Marge interne du bouton
                    child: Text(
                      'Envoyer',
                      style: TextStyle(
                          color: Colors
                              .white), // Couleur du texte (blanc dans ce cas)
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
