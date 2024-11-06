import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_screens.dart';

class MemberInformationPage extends StatefulWidget {
  @override
  _MemberInformationPageState createState() => _MemberInformationPageState();
}

class _MemberInformationPageState extends State<MemberInformationPage> {
  final supabase = Supabase.instance.client;
  String? memberName;
  String? selectedGender;
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    _loadMemberName();
  }

  Future<void> _loadMemberName() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      final response = await supabase
          .from('member')
          .select('member_name')
          .eq('member_id', user.id)
          .single();
      setState(() {
        memberName = response['member_name'];
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.teal,
            colorScheme: ColorScheme.light(primary: Colors.teal),
            buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _saveAdditionalInfo() async {
    final user = supabase.auth.currentUser;
    if (user != null && selectedGender != null && selectedDate != null) {
      try {
        await supabase.from('member').update({
          'member_gender': selectedGender,
          'member_age': selectedDate!.toIso8601String(),
        }).eq('member_id', user.id);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('정보가 성공적으로 저장되었습니다.')),
        );

        // Navigate to HomePage after a short delay
        Future.delayed(Duration(seconds: 1), () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => HomeScreens(userId: user.id)),
          );
        });
      } catch (e) {
        print('Error saving additional info: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('정보 저장 중 오류가 발생했습니다. 다시 시도해 주세요.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('모든 필드를 입력해 주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFDFBF0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'assets/wisely-diary-logo.png',
                height: 100,
                width: 100,
              ),
              SizedBox(height: 20),
              if (memberName != null)
                Text(
                  '$memberName님 환영합니다!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              SizedBox(height: 40),
              Text('성별', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildGenderButton('남성'),
                  SizedBox(width: 20),
                  _buildGenderButton('여성'),
                ],
              ),
              SizedBox(height: 30),
              Text('생년월일', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              InkWell(
                onTap: () => _selectDate(context),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        selectedDate == null
                            ? '생년월일을 선택해주세요'
                            : '${selectedDate!.year}년 ${selectedDate!.month}월 ${selectedDate!.day}일',
                        style: TextStyle(fontSize: 16),
                      ),
                      Icon(Icons.calendar_today, color: Colors.teal),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 40),
              ElevatedButton(
                child: Text('저장', style: TextStyle(fontSize: 18)),
                onPressed: _saveAdditionalInfo,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white, backgroundColor: Colors.teal,
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenderButton(String gender) {
    final isSelected = selectedGender == gender;
    return InkWell(
      onTap: () => setState(() => selectedGender = gender),
      child: Container(
        width: 100,
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.teal : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 3,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            gender,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.teal,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}