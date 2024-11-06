import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'CartoonResultPage.dart';

class CartoonCreationPage extends StatefulWidget {
  final int diarySummaryCode;

  CartoonCreationPage({required this.diarySummaryCode});

  @override
  _CartoonCreationPageState createState() => _CartoonCreationPageState();
}

class _CartoonCreationPageState extends State<CartoonCreationPage> {
  final String baseUrl = 'http://43.203.173.116:8080';
  bool isLoading = false;

  Future<void> createCartoon() async {
    final user = Supabase.instance.client.auth.currentUser;
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${baseUrl}/api/cartoon/create'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'diarySummaryCode': 5,
        }),
      );

      if (response.statusCode == 200) {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => CartoonResultPage(
            cartoonUrl: response.body,
            diarySummaryCode: 5,
            userName:user?.userMetadata?['name']??'사용자',
          ),
        ));
      } else {
        throw Exception('Failed to create cartoon');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('만화 생성에 실패했습니다.')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('만화 생성'),
      ),
      body: Center(
        child: isLoading
            ? CircularProgressIndicator()
            : ElevatedButton(
          onPressed: createCartoon,
          child: Text('만화 생성'),
        ),
      ),
    );
  }
}