import 'package:http/http.dart' as http;
import 'dart:convert';
import 'letter_model.dart';

class LetterNotReadyException implements Exception {
  final String message;
  LetterNotReadyException(this.message);
}

class LetterService {
  final String baseUrl = 'http://43.203.173.116:8080/api';

  Future<Letter> getOrCreateLetter(int diaryCode) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/letter/$diaryCode'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        final letterData = json.decode(utf8.decode(response.bodyBytes));
        return Letter.fromJson(letterData);
      } else {
        throw Exception('Failed to get or create letter: ${response.statusCode}, ${utf8.decode(response.bodyBytes)}');
      }
    } catch (e) {
      throw Exception('서버 연결에 실패했습니다. 잠시 후 다시 시도해주세요.');
    }
  }

  Future<Letter> viewLetter(int letterCode) async {
    final response = await http.get(
      Uri.parse('$baseUrl/letter/view/$letterCode'),
      headers: {
        'Accept': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      return Letter.fromJson(json.decode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Failed to view letter: ${response.statusCode}');
    }
  }

  Future<List<Letter>> inquiryLetter(String date, String memberId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/letter/inquiry?date=$date&memberId=$memberId'),
        headers: {
          'Accept': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> letterDataList = json.decode(utf8.decode(response.bodyBytes));
        return letterDataList.map((data) => Letter.fromJson(data)).toList();
      } else if (response.statusCode == 204) {
        return [];
      } else {
        throw Exception('Failed to inquiry letters: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('서버 연결에 실패했습니다. 잠시 후 다시 시도해주세요.');
    }
  }
}