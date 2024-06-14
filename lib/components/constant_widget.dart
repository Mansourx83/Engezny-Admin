import 'package:flutter/material.dart';

class ConstantWidget extends StatelessWidget {
  const ConstantWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Column(
        children: [
          const SizedBox(
            height: 10,
          ),
          Image.asset("asset/images/consticon.png"),
          const SizedBox(
            height: 8,
          ),
          const Text(
            "إنجزني",
            style: TextStyle(
                fontSize: 45,
                color: Color(0xff0B303F),
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(
            height: 14,
          ),
          const Divider(
            endIndent: 20,
            indent: 20,
            thickness: 2,
            color: Color(0xff2074EF),
          )
        ],
      ),
    );
  }
}
