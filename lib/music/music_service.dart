import 'package:http/http.dart' as http;
import 'dart:convert';

class MusicService {
  final String baseUrl = 'http://43.203.173.116:8080/api/music';

  Future<Map<String, dynamic>> getOrCreateMusicPlayback(int diaryCode) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/check/$diaryCode'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('Failed to get or create music: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('서버 연결에 실패했습니다. 잠시 후 다시 시도해주세요.');
    }
  }

  Future<Map<String, dynamic>> getMusicPlayback(int musicCode) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$musicCode/play'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('Failed to get music playback: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('서버 연결에 실패했습니다. 잠시 후 다시 시도해주세요.');
    }
  }

  Future<List<Map<String, dynamic>>> inquiryMusic(String date, String memberId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/inquiry?date=$date&memberId=$memberId'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> musicList = json.decode(utf8.decode(response.bodyBytes));
        return musicList.cast<Map<String, dynamic>>();
      } else if (response.statusCode == 204) {
        return [];
      } else {
        throw Exception('Failed to inquiry music: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('서버 연결에 실패했습니다. 잠시 후 다시 시도해주세요.');
    }
  }
}