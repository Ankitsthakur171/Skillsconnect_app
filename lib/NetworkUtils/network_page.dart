import 'package:flutter/material.dart';

class NoInternetPage extends StatelessWidget {
  const NoInternetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // back disable
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Replace icon with image
              Image.asset(
                "assets/nointernet.png", // apne path ke hisaab se
                width: 300,
                height: 300,
              ),
              const SizedBox(height: 20),
              const Text(
                "No Internet Connection",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,color: Color(0xff003840)),
              ),
              const SizedBox(height: 10),
              const Text("Please check your Wi-Fi or Mobile Data" ,style: TextStyle(color: Color(0x90003840)),),
            ],
          ),
        ),
      ),
    );
  }
}
