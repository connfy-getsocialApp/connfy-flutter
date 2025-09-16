import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    required this.controller,
    this.prefixIcon,
    this.suffixIcon,
    this.hintText,
    this.borderColor,
    this.boxShadow,
    this.radius,
    this.onChanged,
    this.obscureText,
    this.inputFormatters,
    this.height,
    this.inputType,
    this.errorText,
  });

  final TextEditingController controller;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? hintText;
  final String? errorText;
  final Color? borderColor;
  final List<BoxShadow>? boxShadow;
  final double? radius;
  final double? height;
  final bool? obscureText;
  final List<TextInputFormatter>? inputFormatters;
  final void Function(String)? onChanged;
  final TextInputType? inputType;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: Colors.white,
          style: BorderStyle.solid,
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(15.0),
      ),

      height: height ?? size.height * 0.08,
      // height:
      child: TextFormField(
        controller: controller,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        cursorColor: Color(0xffffffff),
        obscureText: obscureText ?? false,
        keyboardType: inputType,
        enabled: false,
        style: GoogleFonts.poppins(fontSize: 15.0, color: Colors.black45, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          fillColor: Colors.white,
          // filled: true,
          errorText: errorText,
          enabledBorder: InputBorder.none, // Remove enabled border
          border: InputBorder.none, // Remove default border
          focusedBorder: InputBorder.none,
          prefixIconColor: Colors.blue,
          suffixIconColor: Colors.blue,
          prefixIcon: prefixIcon ?? const SizedBox(),
          suffixIcon: suffixIcon ?? const SizedBox(),
          hintText: hintText ?? 'Email address',
          hintStyle: GoogleFonts.poppins(fontSize: 15.0, color: Colors.black45, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
