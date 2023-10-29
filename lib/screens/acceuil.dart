import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'map.dart';
import 'rapport.dart';

class AccueilPage extends StatelessWidget {
  final Map<String, dynamic> userData;

  const AccueilPage({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    String userStatus = userData["userStatus"];

    bool isAdmin = userStatus == "admin";
    bool isStaff = userStatus == "staff";
    bool isControlleur = userStatus == "controlleur";

    int initialTabIndex = 0; // L'onglet "Carte" sera affiché par défaut

    return DefaultTabController(
      initialIndex: initialTabIndex,
      length: 3, // Il y a trois onglets : Carte, Rapport, Rapport envoyé
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF343A40),
          bottom: TabBar(
            tabs: [
              const Tab(icon: Icon(Icons.map), text: "Carte"),
              if (isAdmin || isStaff || isControlleur)
                const Tab(icon: Icon(Icons.insert_chart), text: "Rapport"),
              if (isAdmin || isStaff || isControlleur)
                const Tab(icon: Icon(Icons.send), text: "Rapport envoyé"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Contenu de l'onglet Carte
            Center(child: MapWidget(userData: userData)),
            // Contenu de l'onglet Rapport
            if (isAdmin || isStaff || isControlleur)
              Center(child: RapportForm(userData: userData)),
            // Contenu de l'onglet Rapport envoyé
            if (isAdmin || isStaff || isControlleur)
              Center(
                child: FutureBuilder<List<Rapport>>(
                  future:
                      fetchRapports(userData['id']), // Fournissez l'userId ici
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else {
                      return RapportsList(rapports: snapshot.data!);
                    }
                  },
                ),
              ), //afficher les rapports ici
          ],
        ),
      ),
    );
  }
}

//pour la map

// pour les rappport envoyé

class Rapport {
  final int id;
  final String envoyeur;
  final String receveur;
  final String texte;
  final int note;
  final String heure;

  Rapport(
      {required this.id,
      required this.envoyeur,
      required this.receveur,
      required this.texte,
      required this.note,
      required this.heure});

  factory Rapport.fromJson(Map<String, dynamic> json) {
    return Rapport(
      id: json['id'],
      envoyeur: json['envoyeur_nom'],
      receveur: json['receveur_nom'],
      texte: json['texte'],
      note: json['note'],
      heure: json['heure'],
    );
  }

  String get formattedDate {
    DateTime dateTime = DateTime.parse(heure);
    String formattedDate = "${dateTime.day}/${dateTime.month}/${dateTime.year}";
    return formattedDate;
  }
}

Future<List<Rapport>> fetchRapports(int userId) async {
  final Uri url = Uri.parse(
      "https://kpks-76bbd2eed811.herokuapp.com/api/list_rapport/$userId");
  final response = await http.get(url);

  if (response.statusCode == 200) {
    List<dynamic> data = json.decode(response.body);
    List<Rapport> rapports =
        data.map((json) => Rapport.fromJson(json)).toList();
    return rapports;
  } else {
    throw Exception('Failed to load rapports');
  }
} // Remplacez 1 par l'ID de l'utilisateur connecté

class MyApp extends StatelessWidget {
  final Map<String, dynamic> userData;

  const MyApp({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    int userId = userData['id'];

    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: FutureBuilder<List<Rapport>>(
            future: fetchRapports(userId),
            builder: (context, snapshot) {
              if (snapshot.hasError) print(snapshot.error);

              return snapshot.hasData
                  ? RapportsList(rapports: snapshot.data!)
                  : const Center(child: CircularProgressIndicator());
            },
          ),
        ),
      ),
    );
  }
}

class RapportsList extends StatelessWidget {
  final List<Rapport> rapports;

  const RapportsList({Key? key, required this.rapports}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: rapports.length,
      itemBuilder: (context, index) {
        return Column(
          children: [
            ListTile(
              title: Text(
                'Receveur: ${rapports[index].receveur}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold, // Mettre en gras
                  color: Colors.black, // Couleur noire
                ),
              ),
              subtitle: Text(
                'Texte: ${rapports[index].texte}\n'
                'Note: ${rapports[index].note}\n'
                'Date: ${rapports[index].formattedDate}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold, // Mettre en gras
                  color: Colors.black, // Couleur noire
                ),
              ),
            ),
            const Divider(
              // Ligne séparatrice
              color: Colors.black,
              thickness: 1.0,
            ),
          ],
        );
      },
    );
  }
}
