import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class GlpiService {
  /// L'URL de base de l'API GLPI. Doit pointer vers `apirest.php`.
  /// Ex: "https://votre-glpi.com/apirest.php"
  final String apiUrl;

  /// Le jeton d'application généré dans l'interface de GLPI.
  final String appToken;

  /// Le jeton personnel de l'utilisateur qui effectuera les actions.
  final String userToken;

  String? _sessionToken;

  /// Indique si une session est actuellement active.
  bool get isSessionActive => _sessionToken != null;

  GlpiService({
    required this.apiUrl,
    required this.appToken,
    required this.userToken,
  });

  // --- Gestion de Session ---

  // Fonction pour initialiser la session et récupérer le session_token
  Future<void> initSession() async {
    final response = await http.get(
      Uri.parse('$apiUrl/initSession'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'user_token $userToken',
        'App-Token': appToken,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _sessionToken = data['session_token'];
      print('✅ Session GLPI initialisée avec succès !');
    } else {
      throw Exception(
        'Erreur lors de l\'initialisation de la session GLPI: ${response.body}',
      );
    }
  }

  // Fonction pour fermer la session (bonne pratique)
  Future<void> killSession() async {
    if (_sessionToken == null) return;

    await http.get(Uri.parse('$apiUrl/killSession'), headers: _getHeaders());
    _sessionToken = null;
    print('🔌 Session GLPI terminée.');
  }

  // --- Méthodes CRUD Génériques ---

  /// Récupère un item spécifique par son ID.
  /// [itemType] : Le type d'objet (ex: 'Ticket', 'Computer').
  /// [id] : L'ID de l'objet à récupérer.
  Future<Map<String, dynamic>> getItem({
    required String itemType,
    required int id,
  }) async {
    final response = await http.get(
      Uri.parse('$apiUrl/$itemType/$id'),
      headers: _getHeaders(),
    );
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Erreur GET sur $itemType/$id: ${response.body}');
  }

  /// Récupère un item spécifique par son ID.
  /// [itemType] : Le type d'objet (ex: 'Ticket', 'Computer').
  /// [id] : L'ID de l'objet à récupérer.
  Future<List<Map<String, dynamic>>> getAllItems({
    required String itemType,
  }) async {
    final response = await http.get(
      Uri.parse('$apiUrl/$itemType/'),
      headers: _getHeaders(),
    );
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Erreur GET sur $itemType/: ${response.body}');
  }

  /// Récupère un item spécifique par son ID.
  /// [itemType] : Le type d'objet (ex: 'Ticket', 'Computer').
  /// [id] : L'ID de l'objet à récupérer.
  Future<List<Map<String, dynamic>>> getSubItem({
    required String itemType,
    required int id,
    required String subItemType,
  }) async {
    final response = await http.get(
      Uri.parse('$apiUrl/$itemType/$id/$subItemType'),
      headers: _getHeaders(),
    );
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Erreur GET sur $itemType/$id: ${response.body}');
  }

  /// Ajoute un nouvel item.
  /// [itemType] : Le type d'objet à créer.
  /// [data] : Le `Map` contenant les données de l'objet.
  Future<Map<String, dynamic>> addItem({
    required String itemType,
    required Map<String, dynamic> data,
  }) async {
    final response = await http.post(
      Uri.parse('$apiUrl/$itemType'),
      headers: _getHeaders(),
      body: json.encode({'input': data}),
    );
    if (response.statusCode == 201) {
      return json.decode(response.body); // 201 Created
    }
    throw Exception('Erreur POST sur $itemType: ${response.body}');
  }

  /// Ajoute un nouvel item.
  /// [itemType] : Le type d'objet à créer.
  /// [data] : Le `Map` contenant les données de l'objet.
  Future<Map<String, dynamic>> addSubItem({
    required String itemType,
    required int id,
    required String subItemType,
    required Map<String, dynamic> data,
  }) async {
    final response = await http.post(
      Uri.parse('$apiUrl/$itemType/$id/$subItemType'),
      headers: _getHeaders(),
      body: json.encode({'input': data}),
    );
    if (response.statusCode == 201) {
      return json.decode(response.body); // 201 Created
    }
    throw Exception('Erreur POST sur $itemType: ${response.body}');
  }

  /// Met à jour un item existant.
  /// [itemType] : Le type d'objet à mettre à jour.
  /// [id] : L'ID de l'objet à modifier.
  /// [data] : Le `Map` contenant les champs à modifier.
  Future<Map<String, dynamic>> updateItem({
    required String itemType,
    required int id,
    required Map<String, dynamic> data,
  }) async {
    final response = await http.put(
      Uri.parse('$apiUrl/$itemType/$id'),
      headers: _getHeaders(),
      body: json.encode({'input': data}),
    );
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Erreur PUT sur $itemType/$id: ${response.body}');
  }

  /// Met à jour un item existant.
  /// [itemType] : Le type d'objet à mettre à jour.
  /// [id] : L'ID de l'objet à modifier.
  /// [data] : Le `Map` contenant les champs à modifier.
  Future<Map<String, dynamic>> updateSubItem({
    required String itemType,
    required int id,
    required String subItemType,
    required Map<String, dynamic> data,
  }) async {
    final response = await http.put(
      Uri.parse('$apiUrl/$itemType/$id/$subItemType'),
      headers: _getHeaders(),
      body: json.encode({'input': data}),
    );
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Erreur PUT sur $itemType/$id: ${response.body}');
  }

  /// Supprime un item.
  /// [itemType] : Le type d'objet à supprimer.
  /// [id] : L'ID de l'objet à supprimer.
  Future<void> deleteItem({required String itemType, required int id}) async {
    final response = await http.delete(
      Uri.parse('$apiUrl/$itemType/$id'),
      headers: _getHeaders(),
      // L'API GLPI attend un corps vide ou un `input` pour la suppression
      body: json.encode({
        'input': {'id': id},
      }),
    );
    if (response.statusCode != 204 && response.statusCode != 200) {
      // 204 No Content
      throw Exception('Erreur DELETE sur $itemType/$id: ${response.body}');
    }
  }

  /// Supprime un item.
  /// [itemType] : Le type d'objet à supprimer.
  /// [id] : L'ID de l'objet à supprimer.
  Future<void> deleteSubItem({
    required String itemType,
    required int id,
    required String subItemType,
  }) async {
    final response = await http.delete(
      Uri.parse('$apiUrl/$itemType/$id/$subItemType'),
      headers: _getHeaders(),
      // L'API GLPI attend un corps vide ou un `input` pour la suppression
      body: json.encode({
        'input': {'id': id},
      }),
    );
    if (response.statusCode != 204 && response.statusCode != 200) {
      // 204 No Content
      throw Exception('Erreur DELETE sur $itemType/$id: ${response.body}');
    }
  }

  // --- Recherche Avancée ---

  /// Recherche des items en fonction de multiples critères.
  Future<List<dynamic>> searchItems({
    required String itemType,
    List<Map<String, dynamic>>? criteria,
    List<String>? forcedisplay,
    String? range,
  }) async {
    final queryParameters = _buildSearchQueryParameters(
      criteria: criteria,
      forcedisplay: forcedisplay,
      range: range,
    );

    final uri = Uri.parse('$apiUrl/search/$itemType').replace(
      queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
    );

    final response = await http.get(uri, headers: _getHeaders());

    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body);
      // La réponse de recherche peut contenir `totalcount` et `count`,
      // les données réelles sont dans la clé "data".
      if (decodedBody is Map && decodedBody.containsKey('data')) {
        return decodedBody['data'] as List<dynamic>;
      }
      // Si la réponse n'a pas la clé "data", on retourne la liste (peut être vide)
      return (decodedBody is List) ? decodedBody : [];
    } else {
      throw Exception('Erreur SEARCH sur $itemType: ${response.body}');
    }
  }

  // --- Gestion des Documents ---

  /// Téléverse un fichier et l'associe à un item GLPI.
  ///
  /// [itemType] : Le type d'objet auquel lier le document (ex: 'Ticket').
  /// [itemId] : L'ID de l'objet auquel lier le document.
  /// [filePath] : Le chemin d'accès local au fichier à téléverser.
  /// [displayName] : Le nom du fichier qui sera affiché dans GLPI.
  /// [comment] : Une description ou un commentaire optionnel pour le document.
  ///
  /// Retourne un Map contenant les informations du document créé.
  Future<Map<String, dynamic>> uploadDocument({
    required String itemType,
    required int itemId,
    required String filePath,
    required String displayName,
    String? comment,
  }) async {
    // On crée une requête "multipart", nécessaire pour envoyer des fichiers.
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$apiUrl/Document'),
    );

    // On attache les en-têtes d'authentification
    request.headers.addAll(_getHeaders());

    // On prépare le corps de la requête au format JSON attendu par GLPI
    final documentData = {
      'name': displayName,
      'itemtype': itemType,
      'items_id': itemId,
      if (comment != null) '_comment': comment,
    };
    request.fields['input'] = json.encode(documentData);

    // On attache le fichier. 'filename[0]' est le nom de champ attendu par l'API GLPI.
    request.files.add(
      await http.MultipartFile.fromPath('filename[0]', filePath),
    );

    // On envoie la requête et on attend la réponse
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      // 201 Created
      print('✅ Document téléversé avec succès !');
      return json.decode(response.body);
    } else {
      throw Exception(
        'Erreur lors du téléversement du document: ${response.body}',
      );
    }
  }

  /// Récupère la liste des documents associés à un item.
  ///
  /// [itemType] : Le type d'objet (ex: 'Ticket').
  /// [itemId] : L'ID de l'objet dont on veut lister les documents.
  ///
  /// Retourne une liste de Maps, chaque Map représentant un document.
  Future<List<dynamic>> getDocumentsForItem({
    required String itemType,
    required int itemId,
  }) async {
    final response = await http.get(
      Uri.parse('$apiUrl/$itemType/$itemId/Document'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(
        'Erreur lors de la récupération des documents pour $itemType/$itemId: ${response.body}',
      );
    }
  }

  /// Télécharge le contenu binaire d'un document spécifique.
  ///
  /// [documentId] : L'ID du document à télécharger.
  ///
  /// Retourne les données brutes du fichier (en bytes).
  /// Vous pouvez ensuite utiliser ces données pour enregistrer le fichier sur le disque.
  Future<Uint8List> downloadDocument(int documentId) async {
    final response = await http.get(
      Uri.parse('$apiUrl/Document/$documentId'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      // On ne décode pas le JSON, on retourne directement le corps de la réponse en bytes.
      return response.bodyBytes;
    } else {
      throw Exception(
        'Erreur lors du téléchargement du document $documentId: ${response.body}',
      );
    }
  }

  // --- Fonctions Privées Utilitaires ---

  /// Construit les en-têtes HTTP nécessaires pour chaque requête authentifiée.
  Map<String, String> _getHeaders() {
    if (!isSessionActive) {
      throw Exception(
        'Session non initialisée. Appelez initSession() d\'abord.',
      );
    }
    return {
      'Content-Type': 'application/json',
      'Session-Token': _sessionToken!,
      'App-Token': appToken,
    };
  }

  /// Construit les paramètres de la requête pour la fonction de recherche.
  Map<String, String> _buildSearchQueryParameters({
    List<Map<String, dynamic>>? criteria,
    List<String>? forcedisplay,
    String? range,
  }) {
    final params = <String, String>{};
    if (range != null) params['range'] = range;

    if (criteria != null) {
      for (int i = 0; i < criteria.length; i++) {
        final c = criteria[i];
        params['criteria[$i][field]'] = c['field'].toString();
        params['criteria[$i][searchtype]'] = c['searchtype'].toString();
        params['criteria[$i][value]'] = c['value'].toString();
        if (c.containsKey('link')) {
          params['criteria[$i][link]'] = c['link'].toString();
        }
      }
    }

    if (forcedisplay != null) {
      for (int i = 0; i < forcedisplay.length; i++) {
        params['forcedisplay[$i]'] = forcedisplay[i];
      }
    }
    return params;
  }
}
